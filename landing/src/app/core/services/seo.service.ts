import { DOCUMENT } from '@angular/common';
import { inject, Injectable } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';

const SITE_URL = 'https://courthub.co';

@Injectable({
    providedIn: 'root'
})
export class SeoService {
    private readonly document = inject(DOCUMENT);

    constructor(private title: Title, private meta: Meta) {}

    updateTitle(title: string) {
        this.title.setTitle(title);
    }

    updateMetaTags(config: {
        title?: string;
        description?: string;
        image?: string;
        url?: string;
        keywords?: string;
    }) {
        if (config.keywords) {
            this.meta.updateTag({ name: 'keywords', content: config.keywords });
        }
        if (config.title) {
            this.updateTitle(config.title);
            this.meta.updateTag({ name: 'twitter:title', content: config.title });
            this.meta.updateTag({ property: 'og:title', content: config.title });
        }

        if (config.description) {
            this.meta.updateTag({ name: 'description', content: config.description });
            this.meta.updateTag({ name: 'twitter:description', content: config.description });
            this.meta.updateTag({ property: 'og:description', content: config.description });
        }

        if (config.image) {
            this.meta.updateTag({ name: 'twitter:image', content: config.image });
            this.meta.updateTag({ property: 'og:image', content: config.image });
            this.meta.updateTag({ name: 'twitter:card', content: 'summary_large_image' });
        }

        if (config.url) {
            this.meta.updateTag({ property: 'og:url', content: config.url });
            this.updateCanonicalUrl(config.url);
        }
    }

    updateCanonicalUrl(url: string) {
        let link = this.document.querySelector<HTMLLinkElement>('link[rel="canonical"]');
        if (!link) {
            link = this.document.createElement('link');
            link.setAttribute('rel', 'canonical');
            this.document.head.appendChild(link);
        }
        link.setAttribute('href', url);
    }

    setBlogPostSeo(post: {
        title: string;
        metaDescription: string;
        metaKeywords: string;
        ogImage?: string;
        slug: string;
    }) {
        const url = `${SITE_URL}/blog/${post.slug}`;
        this.updateMetaTags({
            title: `${post.title} | CourtHub Blog`,
            description: post.metaDescription,
            keywords: post.metaKeywords,
            image: post.ogImage ?? `${SITE_URL}/images/og-image-1200x630.jpg`,
            url
        });
    }

    setBlogListSeo() {
        const url = `${SITE_URL}/blog`;
        this.updateMetaTags({
            title: 'Blog | CourtHub - Gestión y BI para Clubes de Tenis y Padel',
            description:
                'Artículos sobre gestión de clubes, monedero digital, BI financiero, integración Wompi y mejores prácticas para dueños de clubes de tenis y pádel.',
            keywords: 'blog club tenis, gestión club padel, monedero digital, BI financiero, CourtHub',
            image: `${SITE_URL}/images/og-image-1200x630.jpg`,
            url
        });
    }
}
