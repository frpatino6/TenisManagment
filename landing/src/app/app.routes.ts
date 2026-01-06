import { Routes } from '@angular/router';
import { LandingComponent } from './features/landing/landing';

export const routes: Routes = [
    {
        path: '',
        component: LandingComponent
    },
    {
        path: '**',
        redirectTo: ''
    }
];
