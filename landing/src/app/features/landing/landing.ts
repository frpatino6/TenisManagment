import { Component } from '@angular/core';
import { HeaderComponent } from '../../core/layout/header/header';
import { FooterComponent } from '../../core/layout/footer/footer';
import { HeroComponent } from './components/hero/hero';
import { FeaturesComponent } from './components/features/features';
import { LeadGenComponent } from './components/lead-gen/lead-gen';
import { PricingComponent } from './components/pricing/pricing';
import { FaqComponent } from './components/faq/faq';
import { SavingsCalculatorComponent } from './components/savings-calculator/savings-calculator';
import { WhiteLabelComponent } from './components/white-label/white-label';
import { LoyaltyComponent } from './components/loyalty/loyalty';
import { ProofComponent } from './components/proof/proof';
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
        FaqComponent,
        LeadGenComponent
    ],
    templateUrl: './landing.html',
    styleUrl: './landing.scss'
})
export class LandingComponent {
    constructor(private seo: SeoService) {
        this.seo.updateMetaTags({
            title: 'CourtHub | BI financiero para clubes de raqueta',
            description: 'Tome decisiones basadas en datos con dashboard ejecutivo, ahorro por monedero y desglose por servicio.',
            image: 'https://courthub.co/images/og-image-1200x630.jpg',
            url: 'https://courthub.co/'
        });
    }
}
