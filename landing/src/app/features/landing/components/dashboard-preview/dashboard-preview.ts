import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DashboardService, DashboardTab, FinancesData, ReservationsData, FacturacionData, AcademiesData } from '../../services/dashboard.service';

@Component({
  selector: 'app-dashboard-preview',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard-preview.html',
  styleUrl: './dashboard-preview.scss',
})
export class DashboardPreviewComponent {
  activeTab: DashboardTab = 'inicio';
  financesData: FinancesData | null = null;
  reservationsData: ReservationsData | null = null;
  facturacionData: FacturacionData | null = null;
  academiesData: AcademiesData | null = null;

  tabs: { id: DashboardTab; label: string; icon: string }[] = [
    { id: 'inicio', label: 'Inicio', icon: 'home' },
    { id: 'finanzas', label: 'Pagos', icon: 'chart-bar' },
    { id: 'reservas', label: 'Reservas', icon: 'calendar' },
    { id: 'facturacion', label: 'Facturación', icon: 'receipt' },
    { id: 'academias', label: 'Academias', icon: 'trophy' },
  ];

  quickAccessCards = [
    { title: 'Reservas', subtitle: 'Ver reservas', icon: 'calendar', color: 'purple' },
    { title: 'Profesores', subtitle: 'Gestionar profesores', icon: 'people', color: 'blue' },
    { title: 'Canchas', subtitle: 'Gestionar canchas', icon: 'tennis', color: 'green' },
    { title: 'Estudiantes', subtitle: 'Gestionar estudiantes', icon: 'students', color: 'orange' },
    { title: 'Facturación', subtitle: 'Ver ingresos', icon: 'chart', color: 'teal' },
    { title: 'Deudas', subtitle: 'Reporte deudores', icon: 'debt', color: 'red' },
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
      case 'inicio':
        this.financesData = null;
        this.reservationsData = null;
        this.facturacionData = null;
        this.academiesData = null;
        break;
      case 'finanzas':
        this.financesData = this.dashboardService.getFinancesData();
        this.reservationsData = null;
        this.facturacionData = null;
        this.academiesData = null;
        break;
      case 'reservas':
        this.reservationsData = this.dashboardService.getReservationsData();
        this.financesData = null;
        this.facturacionData = null;
        this.academiesData = null;
        break;
      case 'facturacion':
        this.facturacionData = this.dashboardService.getFacturacionData();
        this.financesData = null;
        this.reservationsData = null;
        this.academiesData = null;
        break;
      case 'academias':
        this.academiesData = this.dashboardService.getAcademiesData();
        this.financesData = null;
        this.reservationsData = null;
        this.facturacionData = null;
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
}
