export type BookingType = 'individual_class' | 'group_class' | 'court_rental';
export type BookingStatus = 'confirmed' | 'pending' | 'cancelled' | 'completed';
export type PaymentStatus = 'paid' | 'pending' | 'overdue';

export interface Booking {
  id: string;
  studentId: string;
  scheduleId?: string; // Optional - not required for court_rental
  serviceType: BookingType;
  status: BookingStatus;
  price: number;
  notes?: string;
  bookingDate?: Date;
  createdAt?: Date;
}
