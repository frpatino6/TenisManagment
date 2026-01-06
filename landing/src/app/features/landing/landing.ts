import { Component } from '@angular/core';
import { HeaderComponent } from '../../core/layout/header/header';
import { FooterComponent } from '../../core/layout/footer/footer';
import { HeroComponent } from './components/hero/hero';
import { FeaturesComponent } from './components/features/features';
import { LeadGenComponent } from './components/lead-gen/lead-gen';
import { PricingComponent } from './components/pricing/pricing';
import { FaqComponent } from './components/faq/faq';
import { SeoService } from '../../core/services/seo.service';

@Component({
    selector: 'app-landing',
    standalone: true,
    imports: [
        HeaderComponent,
        FooterComponent,
        HeroComponent,
        FeaturesComponent,
        PricingComponent,
        FaqComponent,
        LeadGenComponent
    ],
    templateUrl: './landing.html',
    styleUrl: './landing.scss'
})
export class LandingComponent {
    constructor(private seo: SeoService) {
        this.seo.updateMetaTags({
            title: 'TenisManagement - La plataforma integral para tu Club de Raqueta',
            description: 'Gestiona reservas, profesores, alumnos y cobros en una sola aplicación. Potencia tu club con TenisManagement.',
            image: 'assets/og-image.jpg'
        });
    }
}
