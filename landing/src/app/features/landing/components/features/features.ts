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
      title: 'Su Club en su Bolsillo',
      description: 'Control total desde su móvil. Supervise ingresos, reservas y personal en tiempo real con la tranquilidad de tener el mando total.',
      icon: 'device-mobile'
    },
    {
      title: 'Recaudo Automatizado',
      description: 'Diga adiós a la cobranza manual. El monedero digital gestiona y automatiza el cobro de saldos pendientes sin errores.',
      icon: 'credit-card'
    },
    {
      title: 'Control de Profesores en Cancha',
      description: 'Elimine las planillas de papel. Los profesores marcan asistencia en segundos y el pago de sus clases se calcula automáticamente.',
      icon: 'users'
    },
    {
      title: 'Rentabilidad Operativa',
      description: 'Sepa exactamente qué servicios le dejan más dinero. Compare la ganancia real entre clases grupales, individuales y alquiler de pistas.',
      icon: 'database'
    },
    {
      title: 'Seguro de Retención',
      description: 'Detecte a tiempo cuando un alumno deja de asistir y actúe automáticamente antes de que se retire del club.',
      icon: 'calendar'
    },
    {
      title: 'Cero Fugas de Dinero',
      description: 'Recupere hasta un 5% de sus ingresos eliminando comisiones bancarias innecesarias y errores de registro manual.',
      icon: 'chart-bar'
    }
  ];
}
