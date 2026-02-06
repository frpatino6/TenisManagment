import { Component } from '@angular/core';
import { HeaderComponent } from '../../core/layout/header/header';
import { FooterComponent } from '../../core/layout/footer/footer';
import { HeroComponent } from './components/hero/hero';
import { FeaturesComponent } from './components/features/features';
import { LeadGenComponent } from './components/lead-gen/lead-gen';
import { PricingComponent } from './components/pricing/pricing';
import { FaqComponent } from './components/faq/faq';
import { SavingsCalculatorComponent } from './components/savings-calculator/savings-calculator';
import { BlogPreviewComponent } from './components/blog-preview/blog-preview';
import { WhiteLabelComponent } from './components/white-label/white-label';
import { LoyaltyComponent } from './components/loyalty/loyalty';
import { ProofComponent } from './components/proof/proof';
import { BenefitsComponent } from './components/benefits/benefits';
import { SeoService } from '../../core/services/seo.service';

@Component({
    selector: 'app-landing',
    standalone: true,
    imports: [
        HeaderComponent,
        FooterComponent,
        HeroComponent,
        ProofComponent,
        WhiteLabelComponent,
        FeaturesComponent,
        LoyaltyComponent,
        PricingComponent,
        SavingsCalculatorComponent,
        BlogPreviewComponent,
        FaqComponent,
        LeadGenComponent,
        BenefitsComponent
    ],
    templateUrl: './landing.html',
    styleUrl: './landing.scss'
})
export class LandingComponent {
    constructor(private seo: SeoService) {
        this.seo.updateMetaTags({
            title: 'CourtHub | Software de Gestión y BI para Clubes de Tenis y Padel',
            description: 'Optimiza la rentabilidad de tu club de tenis o padel con BI financiero, monedero digital y pagos automatizados vía Wompi.',
            image: 'https://courthub.co/images/og-image-1200x630.jpg',
            url: 'https://courthub.co/',
            keywords: 'Software Gestión Padel Tenis, Administración de Clubes Deportivos, BI Financiero, Automatización de pagos, Rankings ELO'
        });
    }
}
