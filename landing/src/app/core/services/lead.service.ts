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

@Injectable({
    providedIn: 'root'
})
export class LeadService {
    private readonly apiUrl = `${environment.apiUrl}/public/leads`;

    constructor(private http: HttpClient) { }

    /**
     * Envía los datos de un nuevo interesado al backend.
     * 
     * @param data - Datos del club e interesado
     * @returns Observable con la respuesta del servidor
     */
    createLead(data: LeadData): Observable<{ message: string; leadId: string }> {
        return this.http.post<{ message: string; leadId: string }>(this.apiUrl, data);
    }
}
