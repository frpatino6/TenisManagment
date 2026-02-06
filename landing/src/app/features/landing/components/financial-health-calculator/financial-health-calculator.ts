import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LeadService } from '../../../../core/services/lead.service';

declare let gtag: Function;

const STEPS = 5;
const COSTE_HORA_GESTION_COP = 25000;

@Component({
    selector: 'app-financial-health-calculator',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './financial-health-calculator.html',
    styleUrl: './financial-health-calculator.scss'
})
export class FinancialHealthCalculatorComponent {
    currentStep = 0;
    canchas = 4;
    tarifa = 35000;
    cancelacionesSemanales = 5;
    horasGestionManual = 8;
    clubName = '';
    email = '';
    isSubmitting = false;
    success = false;
    errorMessage: string | null = null;

    constructor(private leadService: LeadService) { }

    get monthlyLoss(): number {
        const perdidaCancelaciones = this.cancelacionesSemanales * 4 * this.tarifa;
        const perdidaGestion = this.horasGestionManual * 4 * COSTE_HORA_GESTION_COP;
        return Math.round(perdidaCancelaciones + perdidaGestion);
    }

    get isLastStep(): boolean {
        return this.currentStep === STEPS - 1;
    }

    get isEmailStep(): boolean {
        return this.currentStep === STEPS - 1;
    }

    nextStep(): void {
        if (this.currentStep < STEPS - 1) {
            this.currentStep++;
        }
    }

    prevStep(): void {
        if (this.currentStep > 0) {
            this.currentStep--;
        }
    }

    canProceed(): boolean {
        if (this.isEmailStep) {
            return this.clubName.trim().length >= 3 && this.isValidEmail(this.email);
        }
        return true;
    }

    private isValidEmail(email: string): boolean {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    onSubmit(): void {
        if (!this.canProceed()) return;

        this.isSubmitting = true;
        this.errorMessage = null;

        this.leadService
            .createCalculatorLead({
                clubName: this.clubName.trim(),
                email: this.email.trim(),
                monthlyLoss: this.monthlyLoss,
                canchas: this.canchas,
                tarifa: this.tarifa,
                cancelacionesSemanales: this.cancelacionesSemanales,
                horasGestionManual: this.horasGestionManual
            })
            .subscribe({
                next: () => {
                    this.isSubmitting = false;
                    this.success = true;
                    // Google Ads Conversion Event
                    if (typeof gtag !== 'undefined') {
                        gtag('event', 'conversion', {
                            'send_to': 'AW-XXXXXXXXX/CALCULATOR_SUBMIT_LABEL'
                        });
                    }
                },
                error: () => {
                    this.isSubmitting = false;
                    this.errorMessage =
                        'Hubo un error al registrar. Por favor, intenta de nuevo o contacta directamente.';
                }
            });
    }

    formatCurrency(value: number): string {
        return new Intl.NumberFormat('es-CO', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    getStepLabel(step: number): string {
        const labels = ['Canchas', 'Tarifa', 'Cancelaciones', 'Horas gestión', 'Tus datos'];
        return labels[step] ?? '';
    }
}
