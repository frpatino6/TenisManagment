import { Component } from '@angular/core';
import { CommonModule, NgOptimizedImage } from '@angular/common';
import { UiButtonComponent } from '../../../../shared/components/ui-button/ui-button';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [CommonModule, UiButtonComponent, NgOptimizedImage],
  templateUrl: './hero.html',
  styleUrl: './hero.scss'
})
export class HeroComponent {
  images = [
    'images/hero-app-mockup-6.webp',
    'images/hero-app-mockup-7.webp',
    'images/hero-app-mockup-5.webp',
    'images/hero-app-mockup.webp',
    'images/hero-app-mockup-2.webp',
    'images/hero-app-mockup-3.webp',
    'images/hero-app-mockup-4.webp'
  ];
  currentImageIndex = 0;
  private intervalId: any;

  ngOnInit() {
    this.startAutoSlide();
  }

  ngOnDestroy() {
    this.stopAutoSlide();
  }

  startAutoSlide() {
    this.intervalId = setInterval(() => {
      this.nextImage();
    }, 4000);
  }

  stopAutoSlide() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  nextImage() {
    this.currentImageIndex = (this.currentImageIndex + 1) % this.images.length;
  }

  prevImage() {
    this.currentImageIndex = (this.currentImageIndex - 1 + this.images.length) % this.images.length;
  }

  setIndex(index: number) {
    this.currentImageIndex = index;
    // Reset timer on manual interaction
    this.stopAutoSlide();
    this.startAutoSlide();
  }
}
