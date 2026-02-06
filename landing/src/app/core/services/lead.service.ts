import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface LeadData {
    clubName: string;
    contactName: string;
    email: string;
    phone: string;
}

export interface CalculatorLeadData {
    clubName: string;
    email: string;
    monthlyLoss: number;
    canchas: number;
    tarifa: number;
    cancelacionesSemanales: number;
    horasGestionManual: number;
}

@Injectable({
    providedIn: 'root'
})
export class LeadService {
    private readonly apiUrl = `${environment.apiUrl}/public`;

    constructor(private http: HttpClient) {}

    createLead(data: LeadData): Observable<{ message: string; leadId: string }> {
        return this.http.post<{ message: string; leadId: string }>(`${this.apiUrl}/leads`, data);
    }

    createCalculatorLead(data: CalculatorLeadData): Observable<{ message: string; leadId: string }> {
        return this.http.post<{ message: string; leadId: string }>(
            `${this.apiUrl}/calculator-leads`,
            data
        );
    }
}
