import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

export interface MonthlyRevenue {
  month: string;
  amount: number;
}

export interface WalletBalance {
  total: number;
  walletCount: number;
}

export interface UpcomingTournament {
  id: string;
  name: string;
  date: string;
  category: string;
  participants: number;
  eloRange: string;
}

export interface FinancesData {
  monthlyRevenue: MonthlyRevenue[];
  totalRevenue: number;
  trendPercent: number;
  walletBalance: WalletBalance;
  ticketPromedio: number;
  ahorroMonedero: number;
  penetracionMonedero: number;
  transactions?: PaymentTransaction[];
}

export interface ReservationCard {
  clientName: string;
  court: string;
  date: string;
  professor: string;
  timeSlot: string;
  type: string;
  price: number;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
}

export interface ReservationsData {
  totalCount: number;
  reservations: ReservationCard[];
}

export interface AcademiesData {
  upcomingTournaments: UpcomingTournament[];
}

export interface ServiceDistribution {
  label: string;
  amount: number;
  percent: number;
  color: string;
}

export interface ExecutiveRow {
  service: string;
  icon: string;
  quantity: number;
  total: number;
  percent: number;
}

export interface FacturacionData {
  totalNetIncome: number;
  trendPercent: number;
  ticketPromedio: number;
  ahorroMonedero: number;
  penetracionMonedero: number;
  serviceDistribution: ServiceDistribution[];
  executiveBreakdown: ExecutiveRow[];
}

export interface DebtorEntry {
  name: string;
  email: string;
  initial: string;
  balance: number;
  totalDebt: number;
  pending: number;
}

export interface DeudasData {
  totalDebt: number;
  debtByBalance: number;
  debtorCount: number;
  debtByPending: number;
  debtors: DebtorEntry[];
}

export interface PaymentTransaction {
  amount: number;
  type: 'online' | 'manual';
  date: string;
  payer: string;
  reference: string;
  status: 'approved' | 'pending';
  description?: string;
}

export type DashboardTab = 'inicio' | 'finanzas' | 'reservas' | 'facturacion' | 'deudas' | 'academias';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  getFinancesData(): FinancesData {
    return {
      monthlyRevenue: [
        { month: 'Ene', amount: 98500 },
        { month: 'Feb', amount: 112300 },
        { month: 'Mar', amount: 108400 },
        { month: 'Abr', amount: 124500 },
        { month: 'May', amount: 118200 },
        { month: 'Jun', amount: 128450 },
      ],
      totalRevenue: 128450,
      trendPercent: 18.4,
      walletBalance: {
        total: 45680,
        walletCount: 142,
      },
      ticketPromedio: 38200,
      ahorroMonedero: 2140,
      penetracionMonedero: 68.5,
      transactions: [
        { amount: 50000, type: 'manual', date: '29/01/2026', payer: 'fernando rodriguez', reference: 'MAN-697AE9A5', status: 'approved', description: 'individual_class' },
        { amount: 35000, type: 'online', date: '28/01/2026', payer: 'maría garcía', reference: 'TRX-1769648262798', status: 'approved' },
        { amount: 45000, type: 'manual', date: '27/01/2026', payer: 'carlos lópez', reference: 'MAN-697AE997', status: 'approved', description: 'court_rental' },
        { amount: 38000, type: 'online', date: '27/01/2026', payer: 'ana martínez', reference: 'TRX-1769648123456', status: 'approved' },
      ],
    };
  }

  getReservationsData(): ReservationsData {
    return {
      totalCount: 4,
      reservations: [
        { clientName: 'Ginna Piñeros', court: 'Cancha Padel 1', date: '03/02/2026', professor: 'Sin profesor', timeSlot: '12:00 - 13:00', type: 'Alquiler', price: 40000, status: 'pending' },
        { clientName: 'Fernando Rodriguez', court: 'Cancha 1', date: '05/02/2026', professor: 'Fernando Rodriguez', timeSlot: '09:00 - 10:00', type: 'Clase', price: 50000, status: 'confirmed' },
        { clientName: 'María García', court: 'Cancha 2', date: '05/02/2026', professor: 'Sin profesor', timeSlot: '14:00 - 15:00', type: 'Alquiler', price: 38000, status: 'confirmed' },
        { clientName: 'Carlos López', court: 'Cancha Padel 1', date: '06/02/2026', professor: 'Juan Pérez', timeSlot: '16:00 - 17:00', type: 'Clase', price: 45000, status: 'confirmed' },
      ],
    };
  }

  getFacturacionData(): FacturacionData {
    return {
      totalNetIncome: 390000,
      trendPercent: -33,
      ticketPromedio: 48750,
      ahorroMonedero: 3000,
      penetracionMonedero: 25.6,
      serviceDistribution: [
        { label: 'Alquiler de cancha', amount: 290000, percent: 74.4, color: '#009688' },
        { label: 'Clase Individual', amount: 100000, percent: 25.6, color: '#4caf50' },
      ],
      executiveBreakdown: [
        { service: 'Alquiler de cancha', icon: 'tennis', quantity: 6, total: 290000, percent: 74 },
        { service: 'Clase Individual', icon: 'person', quantity: 2, total: 100000, percent: 26 },
      ],
    };
  }

  getDeudasData(): DeudasData {
    return {
      totalDebt: 40000,
      debtByBalance: 40000,
      debtorCount: 1,
      debtByPending: 0,
      debtors: [
        { name: 'Ginna Piñeros', email: 'piginna2015@gmail.com', initial: 'G', balance: -40000, totalDebt: 40000, pending: 0 },
      ],
    };
  }

  getAcademiesData(): AcademiesData {
    return {
      upcomingTournaments: [
        {
          id: '1',
          name: 'Torneo Copa Verde',
          date: '15 Mar 2025',
          category: 'Mixto',
          participants: 32,
          eloRange: '1200-1600',
        },
        {
          id: '2',
          name: 'Liga Club Arena',
          date: '22 Mar 2025',
          category: 'Individual',
          participants: 24,
          eloRange: '1400-1800',
        },
        {
          id: '3',
          name: 'Champions Padel',
          date: '5 Abr 2025',
          category: 'Dobles',
          participants: 16,
          eloRange: '1300-1700',
        },
      ],
    };
  }

  getDataForTab(tab: DashboardTab): FinancesData | ReservationsData | FacturacionData | DeudasData | AcademiesData | null {
    switch (tab) {
      case 'inicio':
        return null;
      case 'finanzas':
        return this.getFinancesData();
      case 'reservas':
        return this.getReservationsData();
      case 'facturacion':
        return this.getFacturacionData();
      case 'deudas':
        return this.getDeudasData();
      case 'academias':
        return this.getAcademiesData();
      default:
        return this.getFinancesData();
    }
  }

  /**
   * Future: Replace with HttpClient calls to backend endpoints.
   * Example: return this.http.get<FinancesData>('/api/tenant/finances');
   */
  getFinancesData$(): Observable<FinancesData> {
    return of(this.getFinancesData());
  }

  getReservationsData$(): Observable<ReservationsData> {
    return of(this.getReservationsData());
  }

  getAcademiesData$(): Observable<AcademiesData> {
    return of(this.getAcademiesData());
  }

  getFacturacionData$(): Observable<FacturacionData> {
    return of(this.getFacturacionData());
  }

  getDeudasData$(): Observable<DeudasData> {
    return of(this.getDeudasData());
  }
}
