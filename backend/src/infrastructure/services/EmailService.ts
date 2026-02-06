import nodemailer from 'nodemailer';
import { Logger } from '../services/Logger';
import { config } from '../config';

export class EmailService {
    private transporter: nodemailer.Transporter;
    private logger: Logger;

    constructor() {
        this.logger = new Logger({ module: 'EmailService' });

        // Configurar transporte
        // Si no hay configuración SMTP, el servicio solo logueará los emails (modo dev/test)
        if (config.email.host && config.email.user) {
            this.transporter = nodemailer.createTransport({
                host: config.email.host,
                port: config.email.port,
                secure: config.email.port === 465, // true para 465, false para otros puertos
                auth: {
                    user: config.email.user,
                    pass: config.email.pass,
                },
            });
            this.logger.info('EmailService inicializado con configuración SMTP');
        } else {
            // Transporte dummy para desarrollo sin credenciales
            this.transporter = nodemailer.createTransport({
                jsonTransport: true,
            });
            this.logger.warn('EmailService inicializado en modo DEBUG (sin credenciales SMTP reales)');
        }
    }

    /**
     * Envía una notificación de solicitud de demo al administrador y una confirmación al usuario.
     */
    async sendDemoRequestNotification(leadData: {
        clubName: string;
        contactName: string;
        email: string;
        phone: string;
    }): Promise<boolean> {
        try {
            // 1. Notificación al Administrador
            const adminSubject = `Nueva Solicitud de Demo: ${leadData.clubName}`;
            const adminHtml = `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
                    <h2 style="color: #2D3748;">Nueva Solicitud de Demo</h2>
                    <p>Se ha recibido una nueva solicitud desde la landing page:</p>
                    <div style="background-color: #F7FAFC; padding: 20px; border-radius: 8px; border: 1px solid #E2E8F0;">
                        <p><strong>Club:</strong> ${leadData.clubName}</p>
                        <p><strong>Contacto:</strong> ${leadData.contactName}</p>
                        <p><strong>Email:</strong> ${leadData.email}</p>
                        <p><strong>Teléfono:</strong> ${leadData.phone}</p>
                    </div>
                </div>
            `;

            await this.transporter.sendMail({
                from: config.email.from,
                to: config.email.from, // Se envía al administrador (mismo correo de origen por defecto)
                subject: adminSubject,
                html: adminHtml,
            });

            // 2. Auto-respuesta al Cliente
            const userSubject = `Confirmación de Recepción: Solicitud de Demo CourtHub`;
            const userHtml = `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; line-height: 1.6;">
                    <div style="text-align: center; padding: 20px 0;">
                        <h1 style="color: #2FB344;">¡Hola ${leadData.contactName}!</h1>
                    </div>
                    <p>Gracias por tu interés en <strong>CourtHub</strong>. Hemos recibido exitosamente tu solicitud para el club <strong>${leadData.clubName}</strong>.</p>
                    <p>Uno de nuestro especialistas se pondrá en contacto contigo a la brevedad para agendar la demo y mostrarte cómo podemos ayudarte a optimizar la gestión de tu centro.</p>
                    <p>Mientras tanto, si tienes alguna duda urgente, puedes responder a este correo.</p>
                    <br>
                    <hr style="border: 0; border-top: 1px solid #EEE;">
                    <p style="font-size: 12px; color: #777; text-align: center;">&copy; ${new Date().getFullYear()} CourtHub - Gestión Inteligente de Tenis y Pádel</p>
                </div>
            `;

            const userInfo = await this.transporter.sendMail({
                from: config.email.from,
                to: leadData.email,
                subject: userSubject,
                html: userHtml,
            });

            this.logger.info('Notificación de demo y auto-respuesta enviadas', {
                email: leadData.email,
                club: leadData.clubName,
                messageId: userInfo.messageId
            });

            return true;
        } catch (error) {
            this.logger.error('Error enviando notificaciones de demo', {
                error: (error as Error).message,
                email: leadData.email
            });
            return false;
        }
    }

    /**
     * Notifica al administrador cuando un usuario completa la Calculadora de Salud Financiera.
     */
    async sendCalculatorLeadNotification(data: {
        clubName: string;
        email: string;
        monthlyLoss: number;
        canchas: number;
        tarifa: number;
        cancelacionesSemanales: number;
        horasGestionManual: number;
    }): Promise<boolean> {
        try {
            const subject = `[Calculadora] Lead: ${data.clubName} - Está perdiendo $${data.monthlyLoss.toLocaleString('es-CO')}/mes`;
            const html = `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333;">
                    <h2 style="color: #2D3748;">Nuevo lead desde Calculadora de Salud Financiera</h2>
                    <p>Un usuario completó la calculadora y dejó sus datos:</p>
                    <div style="background-color: #F7FAFC; padding: 20px; border-radius: 8px; border: 1px solid #E2E8F0;">
                        <p><strong>Club:</strong> ${data.clubName}</p>
                        <p><strong>Email:</strong> ${data.email}</p>
                        <p><strong>Pérdida mensual estimada:</strong> $${data.monthlyLoss.toLocaleString('es-CO')}</p>
                        <p><strong>Canchas:</strong> ${data.canchas}</p>
                        <p><strong>Tarifa/hora:</strong> $${data.tarifa.toLocaleString('es-CO')}</p>
                        <p><strong>Cancelaciones/semana:</strong> ${data.cancelacionesSemanales}</p>
                        <p><strong>Horas gestión manual/semana:</strong> ${data.horasGestionManual}</p>
                    </div>
                </div>
            `;

            await this.transporter.sendMail({
                from: config.email.from,
                to: config.email.from,
                subject,
                html
            });

            this.logger.info('Notificación de calculator lead enviada', {
                email: data.email,
                club: data.clubName
            });

            return true;
        } catch (error) {
            this.logger.error('Error enviando notificación de calculator lead', {
                error: (error as Error).message,
                email: data.email
            });
            return false;
        }
    }

    /**
     * Envía un email de invitación a un profesor.
     */
    async sendInvitationEmail(email: string, tenantName: string): Promise<boolean> {
        try {
            const subject = `Invitación a unirse a ${tenantName} en CourtHub`;
            const html = `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; line-height: 1.6;">
                    <div style="text-align: center; padding: 20px 0;">
                        <h1 style="color: #2FB344;">¡Hola!</h1>
                    </div>
                    <p>Has sido invitado a unirte como profesor al centro <strong>${tenantName}</strong> en nuestra plataforma <strong>CourtHub</strong>.</p>
                    <p>Nuestra aplicación te permitirá gestionar tus clases, horarios y pagos de manera sencilla desde tu dispositivo móvil.</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="https://courthub.app/registro" style="background-color: #2FB344; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">Comenzar ahora</a>
                    </div>
                    <p>Si ya tienes una cuenta, simplemente inicia sesión para ver tu nueva vinculación.</p>
                    <p>Si tienes alguna duda, ponte en contacto con el administrador del centro.</p>
                    <br>
                    <hr style="border: 0; border-top: 1px solid #EEE;">
                    <p style="font-size: 12px; color: #777; text-align: center;">&copy; ${new Date().getFullYear()} CourtHub - Gestión Inteligente de Tenis y Pádel</p>
                </div>
            `;

            await this.transporter.sendMail({
                from: config.email.from,
                to: email,
                subject,
                html,
            });

            this.logger.info('Email de invitación enviado', { email, tenantName });
            return true;
        } catch (error) {
            this.logger.error('Error enviando email de invitación', {
                error: (error as Error).message,
                email
            });
            return false;
        }
    }
}
