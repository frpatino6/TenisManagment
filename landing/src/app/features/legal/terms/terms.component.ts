import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../../../core/layout/header/header';
import { FooterComponent } from '../../../core/layout/footer/footer';

@Component({
    selector: 'app-terms',
    standalone: true,
    imports: [CommonModule, HeaderComponent, FooterComponent],
    template: `
    <app-header></app-header>
    <main class="pt-32 pb-20 bg-gray-50">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 bg-white p-10 rounded-2xl shadow-sm border border-gray-100">
        <h1 class="text-3xl font-bold text-tenis-dark mb-8">Términos y Condiciones</h1>
        
        <div class="prose prose-blue max-w-none text-gray-600 space-y-6">
          <p>Última actualización: 29 de enero, 2026</p>
          
          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">1. Aceptación de los términos</h2>
            <p>Al acceder y utilizar este sitio web, usted acepta estar sujeto a estos términos y condiciones y a todas las leyes y regulaciones aplicables.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">2. Uso de la plataforma</h2>
            <p>CourtHub es una herramienta de gestión para centros de tenis y pádel. El uso indebido de la plataforma o de la información contenida en ella está estrictamente prohibido.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">3. Propiedad Intelectual</h2>
            <p>Todo el contenido, diseño y código de CourtHub es propiedad exclusiva de sus creadores y está protegido por las leyes de propiedad intelectual internacionales.</p>
          </section>

          <section>
            <h2 class="text-xl font-semibold text-gray-900 mb-3">4. Limitación de responsabilidad</h2>
            <p>CourtHub no se hace responsable de daños directos, indirectos o consecuentes derivados del uso o la imposibilidad de uso de nuestros servicios.</p>
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
export class TermsComponent { }
