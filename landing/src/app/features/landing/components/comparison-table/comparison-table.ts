import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';

@Component({
    selector: 'app-comparison-table',
    standalone: true,
    imports: [CommonModule, UiButtonComponent],
    templateUrl: './comparison-table.html',
    styleUrl: './comparison-table.scss'
})
export class ComparisonTableComponent {

    rows = [
        {
            criteria: 'Recaudo de Dinero',
            paper: { text: 'Manual / Inseguro', type: 'bad' },
            excel: { text: 'Manual / Sin cobro online', type: 'bad' },
            courthub: { text: 'Automático con Wompi', type: 'good' }
        },
        {
            criteria: 'Deudas de Jugadores',
            paper: { text: 'Difícil de rastrear', type: 'bad' },
            excel: { text: 'Requiere cruzar datos manuales', type: 'neutral' },
            courthub: { text: 'Monedero Digital Prepago', type: 'good' }
        },
        {
            criteria: 'Fidelización',
            paper: { text: 'Ninguna', type: 'bad' },
            excel: { text: 'Ninguna', type: 'bad' },
            courthub: { text: 'Ranking ELO Automático', type: 'good' }
        },
        {
            criteria: 'Informes y Métricas',
            paper: { text: 'Inexistentes', type: 'bad' },
            excel: { text: 'Tediosos / Error humano', type: 'neutral' },
            courthub: { text: 'BI Financiero en Tiempo Real', type: 'good' }
        }
    ];

    scrollToLeadGen() {
        const element = document.getElementById('contact');
        if (element) {
            element.scrollIntoView({ behavior: 'smooth' });
        }
    }
}
