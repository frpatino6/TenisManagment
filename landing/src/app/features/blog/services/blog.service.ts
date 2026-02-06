import { Injectable } from '@angular/core';
import {
    BLOG_POSTS,
    getAllBlogSlugs,
    getBlogPostBySlug,
    type BlogPost
} from '../data/blog-posts.data';

@Injectable({
    providedIn: 'root'
})
export class BlogService {
    getAllPosts(): BlogPost[] {
        return [...BLOG_POSTS].sort(
            (a, b) =>
                new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime()
        );
    }

    getPostBySlug(slug: string): BlogPost | undefined {
        return getBlogPostBySlug(slug);
    }

    getAllSlugs(): string[] {
        return getAllBlogSlugs();
    }
}
