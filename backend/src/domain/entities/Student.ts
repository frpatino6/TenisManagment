export type MembershipType = 'basic' | 'premium';

export interface Student {
  id: string;
  name: string;
  email: string;
  phone: string;
  membershipType: MembershipType;
  balance: number;
}
