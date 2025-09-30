export type BookingType = 'lesson' | 'court_rental';
export type BookingStatus = 'confirmed' | 'pending' | 'cancelled';
export type PaymentStatus = 'paid' | 'pending' | 'overdue';

export interface Booking {
  id: string;
  studentId: string;
  scheduleId: string;
  type: BookingType;
  status: BookingStatus;
  paymentStatus: PaymentStatus;
  createdAt?: Date;
}
