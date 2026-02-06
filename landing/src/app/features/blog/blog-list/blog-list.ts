import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { HeaderComponent } from '../../../core/layout/header/header';
import { FooterComponent } from '../../../core/layout/footer/footer';
import { BlogService } from '../services/blog.service';
import { SeoService } from '../../../core/services/seo.service';
import type { BlogPost } from '../data/blog-posts.data';

@Component({
    selector: 'app-blog-list',
    standalone: true,
    imports: [CommonModule, RouterLink, HeaderComponent, FooterComponent],
    templateUrl: './blog-list.html',
    styleUrl: './blog-list.scss'
})
export class BlogListComponent implements OnInit {
    posts: BlogPost[] = [];

    constructor(
        private blogService: BlogService,
        private seoService: SeoService
    ) {}

    ngOnInit() {
        this.seoService.setBlogListSeo();
        this.posts = this.blogService.getAllPosts();
    }

    formatDate(dateStr: string): string {
        const date = new Date(dateStr);
        return date.toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }
}
