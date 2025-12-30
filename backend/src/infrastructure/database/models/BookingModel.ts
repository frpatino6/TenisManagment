import { Schema, model, Types } from 'mongoose';

export interface BookingDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId; // Reference to Tenant (required for multi-tenancy)
  scheduleId?: Types.ObjectId; // Optional - not required for court_rental
  studentId: Types.ObjectId;
  professorId?: Types.ObjectId; // Optional - not required for court_rental
  serviceType: 'individual_class' | 'group_class' | 'court_rental';
  price: number;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
  bookingDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const BookingSchema = new Schema<BookingDocument>({
  tenantId: {
    type: Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
    index: true,
  },
  scheduleId: { 
    type: Schema.Types.ObjectId, 
    ref: 'Schedule', 
    required: false, // Made explicitly optional, validation handled in pre-save hook
    index: true 
  },
  studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
  professorId: { 
    type: Schema.Types.ObjectId, 
    ref: 'Professor', 
    required: false, // Made explicitly optional, validation handled in pre-save hook
    index: true 
  },
  serviceType: { 
    type: String, 
    enum: ['individual_class', 'group_class', 'court_rental'], 
    required: true 
  },
  price: { type: Number, required: true },
  status: { 
    type: String, 
    enum: ['pending', 'confirmed', 'cancelled', 'completed'], 
    default: 'pending' 
  },
  notes: { type: String },
  bookingDate: { type: Date, default: Date.now }
}, { timestamps: true });

// Pre-save validation hook to ensure required fields for non-court_rental bookings
BookingSchema.pre('save', function(next) {
  // Only validate if serviceType is not court_rental
  if (this.serviceType !== 'court_rental') {
    if (!this.scheduleId) {
      return next(new Error('scheduleId is required for individual_class and group_class'));
    }
    if (!this.professorId) {
      return next(new Error('professorId is required for individual_class and group_class'));
    }
  }
  next();
});

// Indexes - using sparse for optional fields to allow null values
BookingSchema.index({ scheduleId: 1, studentId: 1 }, { sparse: true });
BookingSchema.index({ professorId: 1, createdAt: 1 }, { sparse: true });
BookingSchema.index({ tenantId: 1, studentId: 1 });
BookingSchema.index({ tenantId: 1, professorId: 1 }, { sparse: true });
BookingSchema.index({ tenantId: 1, createdAt: 1 });
// Index for court rentals (without professorId or scheduleId)
BookingSchema.index({ tenantId: 1, serviceType: 1, createdAt: 1 });
// Index for checking court rental availability by date
BookingSchema.index({ tenantId: 1, serviceType: 1, bookingDate: 1, status: 1 });

export const BookingModel = model<BookingDocument>('Booking', BookingSchema);