import { Routes } from '@angular/router';
import { LandingComponent } from './features/landing/landing';
import { PrivacyComponent } from './features/legal/privacy/privacy.component';
import { TermsComponent } from './features/legal/terms/terms.component';

export const routes: Routes = [
    {
        path: '',
        component: LandingComponent
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
