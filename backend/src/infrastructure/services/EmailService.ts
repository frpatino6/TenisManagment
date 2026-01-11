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
     * Enviar invitación a profesor
     */
    async sendInvitationEmail(to: string, tenantName: string): Promise<boolean> {
        try {
            const subject = `Invitación a unirse a ${tenantName}`;
            // TODO: Mejorar template HTML con diseño real
            const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>¡Has sido invitado!</h2>
          <p>Hola,</p>
          <p>El administrador de <strong>${tenantName}</strong> te ha invitado a unirte a su equipo de profesores en Tennis Management.</p>
          <p>Para aceptar la invitación:</p>
          <ol>
            <li>Descarga la aplicación Tennis Management.</li>
            <li>Regístrate usando este mismo correo electrónico: <strong>${to}</strong></li>
            <li>¡Listo! Tu cuenta se vinculará automáticamente con el centro.</li>
          </ol>
          <br>
          <p>Si ya tienes una cuenta, simplemente ignora este correo o contáctanos si crees que es un error.</p>
        </div>
      `;

            const info = await this.transporter.sendMail({
                from: config.email.from,
                to,
                subject,
                html,
            });

            this.logger.info('Email de invitación enviado', { to, tenantName, messageId: info.messageId });

            // Loguear URL de previsualización si es una cuenta de prueba de Ethereal
            const previewUrl = nodemailer.getTestMessageUrl(info);
            if (previewUrl) {
                this.logger.info(`Preview URL: ${previewUrl}`);
            }

            return true;
        } catch (error) {
            this.logger.error('Error enviando email de invitación', { error: (error as Error).message, to });
            return false;
        }
    }
}
