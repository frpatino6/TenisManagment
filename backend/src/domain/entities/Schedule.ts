export type ScheduleType = 'individual' | 'group' | 'court_rental';

export interface Schedule {
  id: string;
  professorId: string;
  date: Date;
  startTime: string;
  endTime: string;
  isAvailable: boolean;
  notes?: string;
  status?: string;
}
