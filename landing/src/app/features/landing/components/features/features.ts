import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-features',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './features.html',
  styleUrl: './features.scss'
})
export class FeaturesComponent {
  features = [
    {
      title: 'Dashboard Financiero',
      description: 'Reportes de ingresos (Facturación) con ahorro real del club y ticket promedio por servicio.',
      icon: 'chart-bar'
    },
    {
      title: 'Pagos Automatizados',
      description: 'Ecosistema de pagos propios vía Wompi para eliminar micro-comisiones y acelerar la cobranza.',
      icon: 'credit-card'
    },
    {
      title: 'Penetración de Monedero',
      description: 'Controle la adopción del monedero por parte de socios y su impacto en la recurrencia.',
      icon: 'users'
    },
    {
      title: 'Desglose Ejecutivo',
      description: 'Rentabilidad por tipo de servicio: clases vs. alquiler de pistas.',
      icon: 'database'
    },
    {
      title: 'Rendimiento por periodos',
      description: 'Comparativa 7, 30 y 90 días para detectar picos y ajustar estrategia.',
      icon: 'calendar'
    },
    {
      title: 'Proyecciones y alertas',
      description: 'Anticipe desviaciones y tome decisiones con señales tempranas del negocio.',
      icon: 'chart-bar'
    }
  ];
}
