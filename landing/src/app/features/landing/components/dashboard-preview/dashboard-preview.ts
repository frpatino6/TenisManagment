import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DashboardService, DashboardTab, FinancesData, ReservationsData, AcademiesData } from '../../services/dashboard.service';

@Component({
  selector: 'app-dashboard-preview',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard-preview.html',
  styleUrl: './dashboard-preview.scss',
})
export class DashboardPreviewComponent {
  activeTab: DashboardTab = 'finanzas';
  financesData: FinancesData | null = null;
  reservationsData: ReservationsData | null = null;
  academiesData: AcademiesData | null = null;

  tabs: { id: DashboardTab; label: string; icon: string }[] = [
    { id: 'finanzas', label: 'Finanzas', icon: 'chart-bar' },
    { id: 'reservas', label: 'Reservas', icon: 'calendar' },
    { id: 'academias', label: 'Academias', icon: 'trophy' },
  ];

  constructor(private dashboardService: DashboardService) {
    this.loadData();
  }

  selectTab(tab: DashboardTab): void {
    this.activeTab = tab;
    this.loadData();
  }

  private loadData(): void {
    switch (this.activeTab) {
      case 'finanzas':
        this.financesData = this.dashboardService.getFinancesData();
        this.reservationsData = null;
        this.academiesData = null;
        break;
      case 'reservas':
        this.reservationsData = this.dashboardService.getReservationsData();
        this.financesData = null;
        this.academiesData = null;
        break;
      case 'academias':
        this.academiesData = this.dashboardService.getAcademiesData();
        this.financesData = null;
        this.reservationsData = null;
        break;
    }
  }

  formatCurrency(value: number): string {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  }

  get chartMaxValue(): number {
    if (!this.financesData?.monthlyRevenue?.length) return 130000;
    return Math.max(...this.financesData.monthlyRevenue.map((m) => m.amount)) * 1.1;
  }
}
