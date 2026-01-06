import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';

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

  constructor(private fb: FormBuilder) {
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

      // Simulate API call
      console.log('Sending lead data to POST /api/public/leads:', this.leadForm.value);

      setTimeout(() => {
        this.isSubmitting = false;
        this.successMessage = '¡Gracias! Un agente activará tu club en breve.';
        this.leadForm.reset();

        // Clear message after 5 seconds
        setTimeout(() => {
          this.successMessage = null;
        }, 5000);
      }, 1500);
    } else {
      this.leadForm.markAllAsTouched();
    }
  }

  get f() { return this.leadForm.controls; }
}
