import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';

@Component({
  selector: 'app-pricing',
  standalone: true,
  imports: [CommonModule, UiButtonComponent],
  templateUrl: './pricing.html',
  styleUrl: './pricing.scss'
})
export class PricingComponent {
  plans = [
    {
      name: 'Club Pequeño',
      price: '49',
      features: [
        'Hasta 4 pistas',
        'Hasta 2 profesores',
        'Reservas ilimitadas',
        'Pagos online',
        'App para alumnos'
      ],
      recommended: false
    },
    {
      name: 'Club Profesional',
      price: '99',
      features: [
        'Pistas ilimitadas',
        'Profesores ilimitados',
        'Reservas ilimitadas',
        'Pagos online',
        'App personalizada',
        'Gestión de Torneos con Ranking ELO',
        'Dashboard avanzado',
        'Soporte prioritario'
      ],
      recommended: true
    },
    {
      name: 'Enterprise',
      price: 'Consultar',
      features: [
        'Múltiples sedes',
        'API personalizada',
        'Gestión de torneos',
        'Integración de Pasarelas de Pago Locales',
        'Integración con tornos',
        'SLA garantizado'
      ],
      recommended: false
    }
  ];
}
