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
     * Envía al lead un correo automático con los resultados de la Calculadora de ROI:
     * Pérdida Mensual Estimada, Horas de Gestión Ahorradas y copy persuasivo sobre
     * Monedero Digital, Wompi y BI Financiero. Diseño con colores CourtHub y responsive.
     */
    async sendCalculatorLeadConfirmationToUser(data: {
        clubName: string;
        email: string;
        monthlyLoss: number;
        horasGestionManual: number;
    }): Promise<boolean> {
        const horasAhorradasMensuales = Math.round(data.horasGestionManual * 4);
        const lossFormatted = data.monthlyLoss.toLocaleString('es-CO');
        const primaryGreen = '#2ecc71';
        const dark = '#2c3e50';
        const blue = '#3498db';
        const lightBg = '#f8fafc';
        const borderColor = '#e2e8f0';

        const subject = `Tu resultado: ${data.clubName} está dejando de percibir $${lossFormatted}/mes — CourtHub puede ayudarte`;
        const html = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Resultado Calculadora CourtHub</title>
</head>
<body style="margin:0; padding:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f1f5f9; -webkit-font-smoothing: antialiased;">
  <div style="max-width: 100%; width: 100%; padding: 16px; box-sizing: border-box;">
    <table role="presentation" cellpadding="0" cellspacing="0" style="max-width: 560px; margin: 0 auto; width: 100%; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.07);">
      <tr>
        <td style="background: linear-gradient(135deg, ${dark} 0%, #1a252f 100%); padding: 28px 24px; text-align: center;">
          <h1 style="margin: 0; color: #ffffff; font-size: 22px; font-weight: 700; letter-spacing: -0.02em;">CourtHub</h1>
          <p style="margin: 8px 0 0; color: rgba(255,255,255,0.85); font-size: 14px;">Calculadora de Salud Financiera</p>
        </td>
      </tr>
      <tr>
        <td style="padding: 28px 24px;">
          <p style="margin: 0 0 20px; color: ${dark}; font-size: 16px; line-height: 1.5;">Hola,</p>
          <p style="margin: 0 0 24px; color: #475569; font-size: 15px; line-height: 1.6;">Gracias por usar la calculadora. Estos son los resultados para <strong>${data.clubName}</strong>:</p>
          <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: separate; border-spacing: 0 12px;">
            <tr>
              <td style="background-color: ${lightBg}; border: 1px solid ${borderColor}; border-radius: 8px; padding: 16px;">
                <p style="margin: 0 0 4px; color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em;">Pérdida mensual estimada</p>
                <p style="margin: 0; color: #dc2626; font-size: 22px; font-weight: 700;">$${lossFormatted} COP/mes</p>
              </td>
            </tr>
            <tr>
              <td style="background-color: ${lightBg}; border: 1px solid ${borderColor}; border-radius: 8px; padding: 16px;">
                <p style="margin: 0 0 4px; color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em;">Horas de gestión ahorradas al mes</p>
                <p style="margin: 0; color: ${primaryGreen}; font-size: 22px; font-weight: 700;">${horasAhorradasMensuales} horas</p>
              </td>
            </tr>
          </table>
          <p style="margin: 24px 0 16px; color: ${dark}; font-size: 16px; font-weight: 600;">¿Cómo recuperar ese dinero y ese tiempo?</p>
          <p style="margin: 0 0 12px; color: #475569; font-size: 15px; line-height: 1.6;">Con CourtHub puedes:</p>
          <ul style="margin: 0 0 20px; padding-left: 20px; color: #475569; font-size: 15px; line-height: 1.7;">
            <li><strong>Monedero digital</strong> — Cobros al instante, menos mora y menos pérdidas por no-show.</li>
            <li><strong>Integración con Wompi</strong> — Pagos seguros y reconciliación automática sin horas en Excel.</li>
            <li><strong>BI financiero</strong> — Dashboards en tiempo real para tomar decisiones y recuperar lo que hoy se te escapa.</li>
          </ul>
          <p style="margin: 0 0 24px; color: #475569; font-size: 15px; line-height: 1.6;">Un especialista se pondrá en contacto contigo para mostrarte cómo aplicar esto en tu club.</p>
          <p style="margin: 0; color: ${dark}; font-size: 15px; font-weight: 600;">Saludos,<br>El equipo de CourtHub</p>
        </td>
      </tr>
      <tr>
        <td style="background-color: ${lightBg}; border-top: 1px solid ${borderColor}; padding: 20px 24px; text-align: center;">
          <p style="margin: 0; font-size: 12px; color: #64748b;">&copy; ${new Date().getFullYear()} CourtHub — Gestión Inteligente de Tenis y Pádel</p>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>`;

        try {
            await this.transporter.sendMail({
                from: config.email.from,
                to: data.email,
                subject,
                html
            });

            this.logger.info('Email de confirmación de calculadora enviado al lead', {
                email: data.email,
                club: data.clubName
            });

            return true;
        } catch (error) {
            this.logger.error('Error enviando confirmación de calculadora al lead', {
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
