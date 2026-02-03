import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../../../core/layout/header/header';
import { FooterComponent } from '../../../core/layout/footer/footer';

@Component({
    selector: 'app-privacy',
    standalone: true,
    imports: [CommonModule, HeaderComponent, FooterComponent],
    template: `
    <app-header></app-header>
    <main class="pt-32 pb-20 bg-gray-50">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 bg-white p-10 rounded-2xl shadow-sm border border-gray-100">
        <h1 class="text-3xl font-bold text-tenis-dark mb-8">Política de Privacidad</h1>
        
        <div class="prose prose-blue max-w-none text-gray-600 space-y-6">
          <p>Última actualización: 29 de enero, 2026</p>
          
          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">1. Información que recopilamos</h2>
            <p>Recopilamos información que usted nos proporciona directamente a través de nuestro formulario de contacto, incluyendo su nombre, nombre del club, correo electrónico y número de teléfono.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">2. Uso de la información</h2>
            <p>Utilizamos la información recopilada para ponernos en contacto con usted en relación con su solicitud de demostración, mejorar nuestros servicios y enviarle actualizaciones relevantes sobre CourtHub.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">3. Protección de datos</h2>
            <p>Implementamos medidas de seguridad técnicas y organizativas para proteger sus datos personales contra el acceso no autorizado, la pérdida o la alteración.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">4. Derechos del usuario</h2>
            <p>Usted tiene derecho a acceder, rectificar o eliminar sus datos personales en cualquier momento. Para ejercer estos derechos, puede ponerse en contacto con nosotros.</p>
          </section>
        </div>
      </div>
    </main>
    <app-footer></app-footer>
  `,
    styles: [`
    :host { display: block; }
  `]
})
export class PrivacyComponent { }
