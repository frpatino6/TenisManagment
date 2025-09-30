export type ScheduleType = 'individual' | 'group' | 'court_rental';

export interface Schedule {
  id: string;
  professorId: string;
  date: Date;
  startTime: string;
  endTime: string;
  type: ScheduleType;
  isAvailable: boolean;
  maxStudents?: number;
}
