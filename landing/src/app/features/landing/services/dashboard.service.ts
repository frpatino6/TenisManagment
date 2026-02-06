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
}

export interface UpcomingBooking {
  time: string;
  court: string;
  type: string;
}

export interface ReservationsData {
  todayCount: number;
  weekCount: number;
  occupancyRate: number;
  upcomingBookings: UpcomingBooking[];
}

export interface AcademiesData {
  upcomingTournaments: UpcomingTournament[];
}

export type DashboardTab = 'finanzas' | 'reservas' | 'academias';

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
    };
  }

  getReservationsData(): ReservationsData {
    return {
      todayCount: 24,
      weekCount: 156,
      occupancyRate: 72,
      upcomingBookings: [
        { time: '09:00', court: 'Cancha 1', type: 'Clase individual' },
        { time: '10:30', court: 'Cancha 2', type: 'Alquiler' },
        { time: '14:00', court: 'Cancha 1', type: 'Clase grupal' },
        { time: '16:00', court: 'Cancha 3', type: 'Alquiler' },
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

  getDataForTab(tab: DashboardTab): FinancesData | ReservationsData | AcademiesData {
    switch (tab) {
      case 'finanzas':
        return this.getFinancesData();
      case 'reservas':
        return this.getReservationsData();
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
}
