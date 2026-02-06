import { Injectable } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';

@Injectable({
    providedIn: 'root'
})
export class SeoService {
    constructor(private title: Title, private meta: Meta) { }

    updateTitle(title: string) {
        this.title.setTitle(title);
    }

    updateMetaTags(config: { title?: string, description?: string, image?: string, url?: string, keywords?: string }) {
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
        }
    }
}
