import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { HeaderComponent } from '../../../core/layout/header/header';
import { FooterComponent } from '../../../core/layout/footer/footer';
import { UiButtonComponent } from '../../../shared/components/ui-button/ui-button';
import { BlogService } from '../services/blog.service';
import { SeoService } from '../../../core/services/seo.service';
import type { BlogPost } from '../data/blog-posts.data';

@Component({
    selector: 'app-blog-post',
    standalone: true,
    imports: [CommonModule, RouterLink, HeaderComponent, FooterComponent, UiButtonComponent],
    templateUrl: './blog-post.html',
    styleUrl: './blog-post.scss'
})
export class BlogPostComponent implements OnInit {
    private route = inject(ActivatedRoute);
    private router = inject(Router);
    private blogService = inject(BlogService);
    private seoService = inject(SeoService);

    post: BlogPost | null = null;
    notFound = false;

    ngOnInit() {
        const slug = this.route.snapshot.paramMap.get('slug');
        if (!slug) {
            this.router.navigate(['/blog']);
            return;
        }

        this.post = this.blogService.getPostBySlug(slug) ?? null;
        if (!this.post) {
            this.notFound = true;
            return;
        }

        this.seoService.setBlogPostSeo(this.post);
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
