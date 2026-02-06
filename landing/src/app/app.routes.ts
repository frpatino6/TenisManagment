import { Routes } from '@angular/router';
import { LandingComponent } from './features/landing/landing';
import { PrivacyComponent } from './features/legal/privacy/privacy.component';
import { TermsComponent } from './features/legal/terms/terms.component';
import { BlogListComponent } from './features/blog/blog-list/blog-list';
import { BlogPostComponent } from './features/blog/blog-post/blog-post';

export const routes: Routes = [
    {
        path: '',
        component: LandingComponent
    },
    {
        path: 'blog',
        component: BlogListComponent
    },
    {
        path: 'blog/:slug',
        component: BlogPostComponent
    },
    {
        path: 'privacidad',
        component: PrivacyComponent
    },
    {
        path: 'terminos',
        component: TermsComponent
    },
    {
        path: '**',
        redirectTo: ''
    }
];
