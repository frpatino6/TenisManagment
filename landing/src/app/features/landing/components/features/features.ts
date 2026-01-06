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
      description: 'Visualiza tus ingresos en tiempo real (Revenue). Controla métricas clave como ocupación de pistas y rendimiento de caja.',
      icon: 'chart-bar'
    },
    {
      title: 'Gestión de Staff y "Top Professors"',
      description: 'Identifica a tus entrenadores estrella. Analíticas detalladas de rendimiento, reservas por profesor y retención de alumnos.',
      icon: 'users'
    },
    {
      title: 'Perfil y Portal del Profesor',
      description: 'Biografía, especialidades y experiencia visibles. Incluye gestión privada de agenda, precios y analytics de rendimiento.',
      icon: 'id-card'
    },
    {
      title: 'Base de Datos de Alumnos',
      description: 'CRM completo. Historial de reservas, pagos y asistencia. Segmenta tu base de usuarios entre Profesores y Alumnos.',
      icon: 'database'
    },
    {
      title: 'Reservas Inteligentes',
      description: 'Algoritmo de disponibilidad en tiempo real para pistas de Tenis y Pádel. Evita conflictos y maximiza la ocupación.',
      icon: 'calendar'
    },
    {
      title: 'Pagos Automatizados',
      description: 'Control total de transacciones. Automatiza el cobro de cuotas, clases sueltas y alquileres de pista.',
      icon: 'credit-card'
    }
  ];
}
