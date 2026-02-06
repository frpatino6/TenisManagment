import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { BlogService } from '../../../blog/services/blog.service';
import type { BlogPost } from '../../../blog/data/blog-posts.data';

@Component({
    selector: 'app-blog-preview',
    standalone: true,
    imports: [CommonModule, RouterLink],
    templateUrl: './blog-preview.html',
    styleUrl: './blog-preview.scss'
})
export class BlogPreviewComponent implements OnInit {
    posts: BlogPost[] = [];

    constructor(private blogService: BlogService) {}

    ngOnInit() {
        this.posts = this.blogService.getAllPosts().slice(0, 3);
    }

    formatDate(dateStr: string): string {
        const date = new Date(dateStr);
        return date.toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }
}
