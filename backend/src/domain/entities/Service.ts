export type ServiceCategory = 'stringing' | 'grip' | 'other';

export interface Service {
  id: string;
  name: string;
  description: string;
  price: number;
  category: ServiceCategory;
}
