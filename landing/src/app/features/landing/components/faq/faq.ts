import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-faq',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './faq.html',
  styleUrl: './faq.scss'
})
export class FaqComponent {
  faqs = [
    {
      question: '¿Puedo probar la plataforma antes de pagar?',
      answer: 'Sí, ofrecemos una demo gratuita y un periodo de prueba de 14 días para que explores todas las funcionalidades sin compromiso.',
      isOpen: false
    },
    {
      question: '¿Necesito instalar algún software?',
      answer: 'No, CourtFlow es una aplicación en la nube (SaaS). Puedes acceder desde cualquier navegador web o desde nuestras apps móviles.',
      isOpen: false
    },
    {
      question: '¿Cómo funciona la gestión de cobros?',
      answer: 'Nos integramos con pasarelas de pago seguras (como Stripe) para automatizar el cobro de cuotas y reservas. El dinero llega directamente a tu cuenta.',
      isOpen: false
    },
    {
      question: '¿Puedo migrar los datos de mi sistema actual?',
      answer: 'Por supuesto. Nuestro equipo de soporte te ayudará a importar tus bases de datos de socios y reservas para que la transición sea fluida.',
      isOpen: false
    }
  ];

  toggleFaq(index: number) {
    this.faqs[index].isOpen = !this.faqs[index].isOpen;
  }
}
