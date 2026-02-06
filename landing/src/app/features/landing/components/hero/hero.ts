import { Component } from '@angular/core';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';
import { DashboardPreviewComponent } from '../dashboard-preview/dashboard-preview';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [UiButtonComponent, DashboardPreviewComponent],
  templateUrl: './hero.html',
  styleUrl: './hero.scss'
})
export class HeroComponent {}
