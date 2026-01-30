import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';
import { LeadService } from '../../../../core/services/lead.service';

@Component({
  selector: 'app-lead-gen',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, UiButtonComponent],
  templateUrl: './lead-gen.html',
  styleUrl: './lead-gen.scss'
})
export class LeadGenComponent {
  leadForm: FormGroup;
  isSubmitting = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  constructor(
    private fb: FormBuilder,
    private leadService: LeadService
  ) {
    this.leadForm = this.fb.group({
      clubName: ['', [Validators.required, Validators.minLength(3)]],
      contactName: ['', [Validators.required, Validators.minLength(3)]],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', [Validators.required, Validators.pattern(/^[0-9+ ]{9,15}$/)]]
    });
  }

  onSubmit() {
    if (this.leadForm.valid) {
      this.isSubmitting = true;
      this.errorMessage = null;
      this.successMessage = null;

      this.leadService.createLead(this.leadForm.value).subscribe({
        next: (response: { message: string; leadId: string }) => {
          this.isSubmitting = false;
          this.successMessage = '¡Gracias! Un agente activará tu club en breve.';
          this.leadForm.reset();

          // Limpiar mensaje después de 5 segundos
          setTimeout(() => {
            this.successMessage = null;
          }, 5000);
        },
        error: (err: unknown) => {
          this.isSubmitting = false;
          this.errorMessage = 'Hubo un error al procesar tu solicitud. Por favor, intenta de nuevo.';
        }
      });
    } else {
      this.leadForm.markAllAsTouched();
    }
  }

  get f() { return this.leadForm.controls; }
}
