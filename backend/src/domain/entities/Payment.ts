export type PaymentMethod = 'cash' | 'card' | 'transfer';

export interface Payment {
  id: string;
  studentId: string;
  professorId?: string;
  amount: number;
  date: Date;
  method: PaymentMethod;
  concept?: string;
}
