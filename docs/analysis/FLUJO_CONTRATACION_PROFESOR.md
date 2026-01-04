# Análisis: Flujo de Contratación de Profesor

## 🔍 Estado Actual

### Problema Identificado

**Frontend:**
- ❌ Profesor nuevo NO puede seleccionar tenant al registrarse
- ❌ Profesor queda sin centros asignados después del registro
- ✅ Selector de tenant existe pero solo se muestra si tiene múltiples centros
- ❌ Si tiene 0 centros, no puede trabajar

**Backend:**
- ✅ Endpoint `POST /api/tenant/professors/invite` existe
- ✅ Permite agregar profesor existente a un tenant
- ❌ Requiere que el profesor ya esté registrado
- ❌ No hay flujo de auto-asignación

---

## 💡 Flujo Propuesto: Profesor Contratado por Centro

### Opción 1: Invitación por Email (Recomendado) ✅

**Flujo:**
1. **Tenant Admin** invita profesor por email (`POST /api/tenant/professors/invite`)
2. **Backend** crea relación `ProfessorTenant` (si profesor existe) o envía email de invitación
3. **Profesor** recibe email con link de invitación
4. **Profesor** hace clic en link → Se registra (si no existe) o acepta invitación
5. **Profesor** queda automáticamente asociado al centro
6. **Profesor** inicia sesión → Ve el centro asignado

**Ventajas:**
- ✅ Control del tenant admin sobre quién se une
- ✅ Profesor no necesita saber qué centro elegir
- ✅ Seguro (solo emails invitados pueden unirse)
- ✅ Permite configurar precios antes de la invitación

**Implementación:**
- Backend: Enviar email con token de invitación
- Frontend: Pantalla de aceptación de invitación
- Si profesor no existe: Registro con token → Auto-asignación
- Si profesor existe: Aceptar invitación → Agregar relación

---

### Opción 2: Registro con Código de Centro

**Flujo:**
1. **Tenant Admin** genera código único del centro
2. **Profesor** se registra ingresando código del centro
3. **Backend** valida código y asigna profesor al tenant
4. **Profesor** queda asociado automáticamente

**Ventajas:**
- ✅ Simple para el profesor
- ✅ No requiere email

**Desventajas:**
- ❌ Código puede ser compartido incorrectamente
- ❌ Menos control del tenant admin

---

### Opción 3: Registro Libre + Solicitud de Unión

**Flujo:**
1. **Profesor** se registra libremente (sin centro)
2. **Profesor** busca centros disponibles
3. **Profesor** solicita unirse a un centro
4. **Tenant Admin** aprueba/rechaza solicitud
5. Si aprobado → Se crea relación `ProfessorTenant`

**Ventajas:**
- ✅ Profesor puede elegir dónde trabajar
- ✅ Flexibilidad

**Desventajas:**
- ❌ Requiere aprobación manual
- ❌ Más pasos en el proceso

---

## 🎯 Recomendación: Opción 1 (Invitación por Email)

**Razones:**
1. **Control:** Tenant admin decide quién se une
2. **Seguridad:** Solo emails invitados pueden unirse
3. **UX:** Profesor solo necesita aceptar invitación
4. **Precios:** Se pueden configurar antes de invitar

**Flujo Detallado:**

```
1. Tenant Admin → Invita profesor (email + precios)
   POST /api/tenant/professors/invite
   
2. Backend → Crea token de invitación + envía email
   - Si profesor existe: Email con link de aceptación
   - Si no existe: Email con link de registro + invitación
   
3. Profesor → Recibe email
   - Link: /accept-invitation?token=xxx
   
4. Profesor → Hace clic
   - Si no registrado: Pantalla registro → Auto-asignación
   - Si registrado: Pantalla aceptación → Agregar relación
   
5. Profesor → Inicia sesión
   - Ve centro asignado automáticamente
   - Puede empezar a trabajar
```

---

## 🔧 Cambios Necesarios (Sin Implementar)

### Backend:
1. ✅ `POST /api/tenant/professors/invite` - Ya existe
2. ❌ Generar token de invitación
3. ❌ Enviar email de invitación
4. ❌ `GET /api/invitations/:token` - Validar token
5. ❌ `POST /api/invitations/:token/accept` - Aceptar invitación

### Frontend:
1. ❌ Pantalla de aceptación de invitación
2. ❌ Modificar registro para aceptar token de invitación
3. ❌ Auto-seleccionar tenant después de aceptar invitación

---

## 📝 Flujo Alternativo: Profesor Freelance

Si un profesor quiere trabajar en múltiples centros:

1. **Primer centro:** Invitación por email (Opción 1)
2. **Centros adicionales:** 
   - Opción A: Otra invitación del nuevo centro
   - Opción B: Solicitud del profesor (Opción 3)

**Recomendación:** Combinar Opción 1 (primer centro) + Opción 3 (centros adicionales)

---

## ✅ Conclusión

**Flujo Recomendado:**
- **Invitación por Email** para primer centro (controlado por tenant admin)
- **Solicitud de Unión** para centros adicionales (flexibilidad para profesor)

**Estado Actual:**
- Backend tiene base (`inviteProfessor`)
- Falta: Tokens, emails, pantallas de aceptación

