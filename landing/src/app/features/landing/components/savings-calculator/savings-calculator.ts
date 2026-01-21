import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-savings-calculator',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './savings-calculator.html',
  styleUrl: './savings-calculator.scss'
})
export class SavingsCalculatorComponent {
  minBilling = 1000;
  maxBilling = 50000;
  step = 1000;
  monthlyBilling = 10000;
  isAnimating = false;

  get monthlySavings(): number {
    return this.monthlyBilling * 0.03;
  }

  onBillingChange(): void {
    this.triggerAnimation();
  }

  formatCurrency(value: number): string {
    const formatted = new Intl.NumberFormat('es-CO', {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);

    return `$ ${formatted}`;
  }

  private triggerAnimation(): void {
    this.isAnimating = true;
    setTimeout(() => {
      this.isAnimating = false;
    }, 200);
  }
}
