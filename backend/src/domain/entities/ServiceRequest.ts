export interface ServiceRequest {
  id: string;
  studentId: string;
  serviceId: string;
  notes?: string;
  status: 'requested';
  createdAt: Date;
}
