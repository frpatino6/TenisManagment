# Análisis e Implementación de Pagos Online (Wompi & Future Stripe)

Este documento detalla la arquitectura y el plan de implementación para integrar Wompi como pasarela de pagos en Colombia, manteniendo una estructura flexible que permita la fácil incorporación de Stripe en el futuro.

## 1. Estado Actual

### Backend
*   **Modelos**: Existe un modelo `Payment` básico que registra pagos realizados ('cash', 'card', 'transfer').
*   **Tenants**: Los centros deportivos (`Tenant`) tienen una configuración básica (`TenantConfig`) pero no soportan credenciales de pago.
*   **Servicios**: No existe una capa de abstracción para pasarelas de pago.

### Frontend (Mobile)
*   **UI**: La pantalla `MyBalanceScreen` muestra el saldo y estadísticas, pero no permite realizar recargas o pagos directos.
*   **Booking**: El flujo de reserva actual asume pagos manuales o contabilidad interna.

---

## 2. Arquitectura Propuesta (Backend)

Para soportar múltiples pasarelas (Wompi hoy, Stripe mañana), implementaremos el **Patrón Strategy**.

### 2.1. Abstracción del Gateway
Crearemos una interfaz en `src/domain/services/payment/PaymentGateway.ts`:

```typescript
export interface PaymentIntent {
  reference: string;
  amount: number;
  currency: string;
  signature?: string; // Requerido por Wompi
  checkoutUrl?: string; // URL para redirigir al usuario (Wompi/Stripe Checkout)
}

export interface PaymentGateway {
  // Inicializa una transacción (obtiene referencia, firma y URL de pago)
  createPaymentIntent(
    amount: number, 
    currency: string, 
    user: AuthUser, 
    tenant: TenantWithConfig
  ): Promise<PaymentIntent>;

  // Valida un webhook o respuesta de la pasarela
  validateTransaction(data: any, tenant: TenantWithConfig): Promise<PaymentResult>;
}
```

### 2.2. Adaptadores (Infrastructure)
Implementaremos `WompiAdapter` (y a futuro `StripeAdapter`) que cumplan con `PaymentGateway`.
*   **Ubicación**: `src/infrastructure/services/payment/adapters/`

### 2.3. Configuración por Tenant
Actualizaremos `TenantConfig` en `TenantModel.ts` para guardar las credenciales de forma segura.

```typescript
// En TenantModel.ts
export interface TenantConfig {
  // ... existentes
  payments?: {
    activeProvider: 'wompi' | 'stripe';
    wompi?: {
      pubKey: string;
      eventsKey: string; // Para validar firmas de webhooks
      integrityKey: string; // Para firmar transacciones
      isTest: boolean;
    };
    stripe?: {
      // Futuro
    };
  };
}
```

### 2.4. Modelo de Transacciones (Transaction)
Necesitamos un modelo para auditar **intentos** de pago independientemente de si son exitosos o no. `Payment` se mantendrá para pagos **completados**.

*   **Nuevo Modelo**: `TransactionModel`
    *   `reference`: String (Único, generado por nosotros)
    *   `externalId`: String (ID de Wompi/Stripe)
    *   `amount`, `currency`
    *   `status`: PENDING, APPROVED, DECLINED, VOIDED, ERROR
    *   `gateway`: 'WOMPI', 'STRIPE'
    *   `metadata`: JSON (para guardar respuesta cruda de la pasarela)

---

## 3. Flujo de Implementación (Wompi)

### Flujo Detallado
1.  **Mobile**: Usuario selecciona "Recargar Saldo" o "Pagar Reserva".
    *   Ingresa monto.
2.  **Mobile -> Backend**: `POST /api/payments/init`
    *   Backend genera una referencia única (`TRX-{timestamp}-{random}`).
    *   Backend calcula la firma de integridad (SHA-256 de referencia + monto + moneda + secreto integridad).
    *   Backend responde con: `reference`, `signature`, `publicKey` de Wompi, y `amount`.
3.  **Mobile**: Abre Wompi Widget (WebView o URL Launcher para mejor compatibilidad).
    *   Wompi url: `https://checkout.wompi.co/p/?pub_key=...&currency=COP&amount=...&reference=...&integrity=...`
4.  **Usuario**: Completa el pago en Wompi.
5.  **Wompi -> Backend (Webhook)**: Wompi notifica a `POST /api/webhooks/wompi`.
    *   Backend valida la firma del evento usando `eventsKey`.
    *   Backend busca la `Transaction` por referencia.
    *   Si es `APPROVED`:
        *   Actualiza `Transaction` a `APPROVED`.
        *   Crea registro en `Payment` (contabilidad).
        *   Actualiza saldo del usuario (`Student`).
        *   Envía notificación push/email.
6.  **Mobile**: Recibe notificación o usuario regresa a la app y consulta estado (`GET /api/payments/status/:reference`).

---

## 4. Cambios en Frontend (Mobile)

### Nuevas Pantallas
1.  `PaymentMethodWaitScreen`: Pantalla intermedia que llama al backend para iniciar la transacción.
2.  `WompiWebView`: (Opcional) Para mantener al usuario en la app, o usar `url_launcher` para abrir navegador del sistema (más seguro y fácil de implementar inicialmente).

### Cambios en UI
*   Agregar botón "Recargar Saldo" en `MyBalanceScreen`.
*   Feedback visual de estado de pago (Pending, Success, Error).

---

## 5. Plan de Tareas

### Fase 1: Backend Core y Modelos
- [ ] Crear `TransactionModel` en Mongoose.
- [ ] Actualizar `TenantModel` con `PaymentConfig`.
- [ ] Implementar `PaymentGateway` interface.
- [ ] Implementar `WompiAdapter` (generación de firma y URL).

### Fase 2: Backend Endpoints
- [ ] `POST /payments/init`: Crear transacción pending y devolver datos para checkout.
- [ ] `POST /webhooks/wompi`: Endpoint público para recibir confirmación de Wompi. Logica de validación de firma y actualización de saldo.

### Fase 3: Frontend Mobile
- [ ] Crear provider de Pagos `PaymentProvider`.
- [ ] Crear UI para ingresar monto a recargar.
- [ ] Integrar `url_launcher` para abrir checkout de Wompi.
- [ ] Pantalla de confirmación/éxito.

### Fase 4: Testing & UAT
- [ ] Configurar credenciales de Sandbox de Wompi en Tenant de prueba.
- [ ] Realizar ciclo completo de pago (falso positivo, falso negativo).
- [ ] Verificar creación de `Payment` y `Transaction`.

## Consideraciones de Seguridad
*   **NUNCA** manejar tarjetas de crédito directamente en el backend (PCI DSS). Usar siempre el Checkout de Wompi o Tokenización.
*   **Firmas de Integridad**: Es crucial validar las firmas tanto al enviar a Wompi como al recibir el webhook para evitar manipulación de montos o estados.
*   **Idempotencia**: El webhook debe manejar reintentos de Wompi sin duplicar saldos. (Usar `reference` como llave de idempotencia).
