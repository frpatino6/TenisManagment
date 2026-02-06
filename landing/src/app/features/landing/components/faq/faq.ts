import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

interface FaqItem {
  id: string;
  question: string;
  answer: string;
  isOpen: boolean;
}

@Component({
  selector: 'app-faq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './faq.html',
  styleUrl: './faq.scss'
})
export class FaqComponent {
  faqs: FaqItem[] = [
    {
      id: 'faq-migracion',
      question: '¿Es difícil migrar mis datos actuales?',
      answer:
        'No. Nuestro equipo se encarga de importar tu base de datos de jugadores y saldos desde Excel para que no pierdas ni un minuto de operación. ' +
        'Ofrecemos soporte técnico dedicado durante la migración para que la transición sea fluida y sin riesgos.',
      isOpen: false
    },
    {
      id: 'faq-pagos',
      question: '¿Cómo recibo el dinero de las reservas?',
      answer:
        'Directo a tu cuenta. Gracias a nuestra integración oficial con Wompi, los pagos de tus clientes llegan de forma segura y automática. ' +
        'La seguridad de pagos está garantizada con estándares de la industria y conciliación en tiempo real.',
      isOpen: false
    },
    {
      id: 'faq-elo',
      question: '¿Puedo usar el sistema de rankings ELO si mi club es pequeño?',
      answer:
        '¡Claro! El sistema se adapta a cualquier número de jugadores, motivando la competitividad y aumentando la reserva de canchas desde el primer día. ' +
        'Nuestro software para torneos y ligas funciona igual de bien en clubs pequeños que en los más grandes.',
      isOpen: false
    },
    {
      id: 'faq-prueba',
      question: '¿Puedo probar la plataforma antes de pagar?',
      answer:
        'Sí, ofrecemos una demo gratuita y un periodo de prueba de 14 días para que explores todas las funcionalidades sin compromiso.',
      isOpen: false
    },
    {
      id: 'faq-software',
      question: '¿Necesito instalar algún software?',
      answer:
        'No, CourtHub es una aplicación en la nube (SaaS). Puedes acceder desde cualquier navegador web o desde nuestras apps móviles.',
      isOpen: false
    },
    {
      id: 'faq-cobros',
      question: '¿Cómo funciona la gestión de cobros?',
      answer:
        'Nos integramos con pasarelas de pago seguras (como Stripe) para automatizar el cobro de cuotas y reservas. El dinero llega directamente a tu cuenta.',
      isOpen: false
    },
    {
      id: 'faq-migrar-sistema',
      question: '¿Puedo migrar los datos de mi sistema actual?',
      answer:
        'Por supuesto. Nuestro equipo de soporte te ayudará a importar tus bases de datos de socios y reservas para que la transición sea fluida.',
      isOpen: false
    }
  ];

  toggleFaq(index: number): void {
    const item = this.faqs[index];
    if (item.isOpen) {
      item.isOpen = false;
      return;
    }
    this.faqs.forEach((faq, i) => (faq.isOpen = i === index));
  }
}
