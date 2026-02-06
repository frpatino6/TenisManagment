import { Component } from '@angular/core';

declare let gtag: Function;

@Component({
    selector: 'app-elo-competitiveness',
    standalone: true,
    imports: [],
    templateUrl: './elo-competitiveness.html',
    styleUrl: './elo-competitiveness.scss'
})
export class EloCompetitivenessComponent {
    trackInteraction(): void {
        if (typeof gtag !== 'undefined') {
            gtag('event', 'elo_section_hover', {
                'event_category': 'Engagement',
                'event_label': 'ELO Section'
            });
        }
    }
}
