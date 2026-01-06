import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { UiButtonComponent } from '../../../shared/components/ui-button/ui-button';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterLink, UiButtonComponent],
  templateUrl: './header.html',
  styleUrl: './header.scss'
})
export class HeaderComponent {
  isMenuOpen = false;

  toggleMenu() {
    this.isMenuOpen = !this.isMenuOpen;
  }
}
