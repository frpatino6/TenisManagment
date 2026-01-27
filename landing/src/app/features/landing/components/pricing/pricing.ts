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
      description: 'Ideal para centros que inician su transformación digital.',
      price: '49',
      features: [
        'Hasta 4 pistas',
        'Pagos online',
        'App para alumnos',
        'Reservas ilimitadas',
        'Gestión básica de profesores',
        'Recordatorios automáticos por email/WhatsApp',
        'Reportes operativos básicos'
      ],
      recommended: false
    },
    {
      name: 'Club Profesional',
      description: 'Nuestra solución completa para maximizar la rentabilidad.',
      price: '99',
      features: [
        'Pistas ilimitadas',
        'Sistema de Monedero (Ahorro en comisiones)',
        'Dashboard de Facturación Avanzado',
        'Segmentación de socios por consumo',
        'Reportes de rentabilidad por servicio',
        'Automatización de cobros recurrentes',
        'App personalizada con tu marca',
        'Soporte técnico VIP'
      ],
      recommended: true
    },
    {
      name: 'Enterprise',
      description: 'Para grandes complejos y gestión de múltiples sedes.',
      price: 'Consultar',
      features: [
        'Gestión de Torneos Automatizada',
        'Sistema de Ranking ELO profesional',
        'Integración de pasarelas locales',
        'Dashboard ejecutivo multi-sede',
        'Migración y onboarding dedicado',
        'SLA y soporte premium'
      ],
      recommended: false
    }
  ];
}
