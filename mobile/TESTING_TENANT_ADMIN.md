# 🧪 Guía de Prueba - Panel Tenant Admin

Esta guía te ayudará a probar el panel de administración de Tenant Admin que acabamos de implementar.

---

## ✅ Prerequisitos

### 1. Backend en ejecución

El backend debe estar corriendo y accesible:

```bash
# Si estás en desarrollo local
# El backend debe estar en http://localhost:3000

# Verifica que esté corriendo
curl http://localhost:3000/api/health  # O el endpoint de health que tengas
```

### 2. Usuario con rol `tenant_admin`

**IMPORTANTE:** Necesitas un usuario autenticado en Firebase con rol `tenant_admin` en el backend.

**Opciones para crear/probar:**

1. **Usar un usuario existente** (si ya tienes uno configurado en el backend)
2. **Crear un nuevo usuario** desde el backend o base de datos
3. **Modificar un usuario existente** para darle el rol `tenant_admin`

**Verificar en el backend:**
- El usuario debe tener el rol `tenant_admin` en la tabla `AuthUser`
- Debe existir un registro en `TenantAdmin` que relacione al usuario con un tenant
- El tenant debe estar activo

### 3. Flutter y dependencias

```bash
cd mobile
flutter pub get
flutter doctor  # Verifica que todo esté bien
```

---

## 🚀 Ejecutar la Aplicación

### Opción 1: Script (Recomendado)

```bash
cd mobile
./scripts/run_dev.sh
```

### Opción 2: Comando directo

```bash
cd mobile
flutter run --flavor dev -t lib/main_dev.dart
```

### Opción 3: Especificar dispositivo

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>
```

---

## 🔐 Probar el Login

1. **Abre la app** - Deberías ver la pantalla de login
2. **Inicia sesión** con un usuario que tenga rol `tenant_admin`:
   - Puedes usar **Google Sign-In** (si el usuario está registrado con Google)
   - O **Email/Contraseña** (si tienes credenciales)
3. **Verificación automática:**
   - Si el usuario tiene rol `tenant_admin`, debería redirigir automáticamente a `/tenant-admin-home`
   - Si el usuario no tiene tenant configurado, debería mostrar `/select-tenant`

---

## 📱 Funcionalidades a Probar

### 1. Dashboard Principal (`/tenant-admin-home`)

**Qué verificar:**
- ✅ Se muestra el nombre del centro
- ✅ Se muestran métricas: Reservas, Ingresos, Profesores, Estudiantes, Canchas
- ✅ Los cards de métricas tienen los valores correctos
- ✅ Los accesos rápidos funcionan (navegan a las pantallas correspondientes)

**Cómo probar:**
1. Después del login, deberías llegar automáticamente al dashboard
2. Verifica que las métricas se carguen correctamente
3. Toca cada uno de los 4 accesos rápidos para verificar la navegación

---

### 2. Configuración del Centro (`/tenant-config`)

**Qué verificar:**
- ✅ Se cargan los datos actuales del tenant
- ✅ Puedes editar nombre, slug y dominio
- ✅ El botón "Guardar Cambios" funciona
- ✅ Los botones de navegación a Branding, Precios y Horarios funcionan

**Cómo probar:**
1. Desde el dashboard, toca "Configuración"
2. Verifica que los campos se pre-llenan con los datos actuales
3. Modifica algún campo y guarda
4. Verifica que se muestre el mensaje de éxito
5. Prueba los botones de navegación a otras secciones

---

### 3. Branding (`/tenant-branding`)

**Qué verificar:**
- ✅ Se cargan los valores actuales (logo, colores)
- ✅ Puedes editar el logo (URL)
- ✅ Puedes editar colores primario y secundario
- ✅ La validación de formato hexadecimal funciona

**Cómo probar:**
1. Desde Configuración, toca "Branding"
2. Modifica los colores (formato: `2196F3` sin el #)
3. Guarda y verifica que funcione
4. Prueba validaciones (colores inválidos)

---

### 4. Precios Base (`/tenant-pricing`)

**Qué verificar:**
- ✅ Se cargan los precios actuales
- ✅ Puedes modificar los 3 precios (Individual, Grupal, Alquiler)
- ✅ La validación de números funciona
- ✅ El guardado funciona correctamente

**Cómo probar:**
1. Desde Configuración, toca "Precios"
2. Modifica los valores
3. Guarda y verifica
4. Prueba con valores inválidos (negativos, texto)

---

### 5. Horarios de Operación (`/tenant-operating-hours`)

**Qué verificar:**
- ✅ Se cargan las horas actuales
- ✅ Puedes seleccionar hora de apertura y cierre
- ✅ Puedes seleccionar días de la semana (opcional)
- ✅ El guardado funciona

**Cómo probar:**
1. Desde Configuración, toca "Horarios de Operación"
2. Selecciona diferentes horas usando el picker
3. Selecciona/deselecciona días de la semana
4. Guarda y verifica

---

### 6. Gestión de Profesores (`/tenant-professors`)

**Qué verificar:**
- ✅ Se muestra la lista de profesores
- ✅ El buscador funciona (por nombre/email)
- ✅ Los filtros (Todos/Activos/Inactivos) funcionan
- ✅ Puedes activar/desactivar profesores desde el menú
- ✅ El botón "Invitar Profesor" funciona

**Cómo probar:**
1. Desde el dashboard, toca "Profesores"
2. Verifica que se cargue la lista
3. Usa el buscador para filtrar
4. Prueba los filtros de estado
5. Toca el menú (3 puntos) de un profesor y prueba activar/desactivar
6. Toca "Invitar Profesor" (FAB o botón en AppBar)

---

### 7. Invitar Profesor (`/tenant-invite-professor`)

**Qué verificar:**
- ✅ El formulario de email funciona
- ✅ Puedes activar/desactivar precios personalizados
- ✅ La validación de email funciona
- ✅ El guardado funciona

**Cómo probar:**
1. Desde la lista de profesores, toca "Invitar Profesor"
2. Ingresa un email válido
3. Activa "Usar precios personalizados" y completa los campos
4. Envía la invitación
5. Verifica que se muestre el mensaje de éxito

---

### 8. Gestión de Canchas (`/tenant-courts`)

**Qué verificar:**
- ✅ Se muestra la lista de canchas
- ✅ El buscador funciona
- ✅ Los filtros (Tipo y Estado) funcionan
- ✅ Puedes crear, editar y eliminar canchas
- ✅ Puedes activar/desactivar canchas

**Cómo probar:**
1. Desde el dashboard, toca "Canchas"
2. Verifica que se cargue la lista
3. Usa el buscador y filtros
4. Toca el FAB para crear una cancha
5. Completa el formulario y crea
6. Toca una cancha para editarla
7. Prueba activar/desactivar desde el menú
8. Prueba eliminar (con confirmación)

---

## 🐛 Troubleshooting

### Error: "No autorizado" o 401/403

**Causa:** El usuario no tiene rol `tenant_admin` o no tiene acceso al tenant.

**Solución:**
- Verifica en el backend que el usuario tenga rol `tenant_admin`
- Verifica que exista un registro en `TenantAdmin` para ese usuario
- Verifica que el tenant esté activo

### Error: "Tenant no encontrado" o 404

**Causa:** El usuario no está asociado a ningún tenant como admin.

**Solución:**
- Verifica en el backend que exista un registro `TenantAdmin` para ese usuario
- El tenant debe estar activo

### La app redirige a `/home` en lugar de `/tenant-admin-home`

**Causa:** El usuario no tiene rol `tenant_admin` o hay un problema con la autenticación.

**Solución:**
- Verifica el rol del usuario en Firebase/Backend
- Verifica los logs de la app para ver qué rol se está detectando
- Cierra sesión y vuelve a iniciar sesión

### Las métricas no se cargan

**Causa:** El endpoint `/api/tenant/metrics` no está disponible o hay un error.

**Solución:**
- Verifica que el backend esté corriendo
- Verifica en los logs del backend si hay errores
- Verifica la conexión a internet
- Revisa los logs de la app para ver el error específico

### Las pantallas muestran "Error al cargar"

**Causa:** Los endpoints del backend no están disponibles o hay problemas de autenticación.

**Solución:**
- Verifica que el backend esté corriendo y accesible
- Verifica que el header `X-Tenant-ID` se esté enviando (debería ser automático)
- Verifica que el token de Firebase sea válido
- Revisa los logs del backend para ver errores específicos

---

## 📊 Endpoints Requeridos del Backend

Para que todo funcione, el backend debe tener estos endpoints implementados:

**✅ Ya implementados (según el documento):**
- `GET /api/tenant/me` - Información del tenant
- `PUT /api/tenant/me` - Actualizar configuración
- `PUT /api/tenant/operating-hours` - Configurar horarios
- `GET /api/tenant/professors` - Listar profesores
- `POST /api/tenant/professors/invite` - Invitar profesor
- `PATCH /api/tenant/professors/:id/activate` - Activar profesor
- `PATCH /api/tenant/professors/:id/deactivate` - Desactivar profesor
- `GET /api/tenant/courts` - Listar canchas
- `POST /api/tenant/courts` - Crear cancha
- `PUT /api/tenant/courts/:id` - Actualizar cancha
- `DELETE /api/tenant/courts/:id` - Eliminar cancha
- `GET /api/tenant/metrics` - Métricas del centro

**❌ No implementados aún (no afectan la funcionalidad básica):**
- Endpoints de reservas (`/api/tenant/bookings/*`)
- Endpoints de pagos (`/api/tenant/payments/*`)
- Endpoints de estudiantes (`/api/tenant/students/*`)
- Endpoints de reportes (`/api/tenant/reports/*`)

---

## 🎯 Checklist de Prueba Completo

- [ ] Login con usuario `tenant_admin` funciona
- [ ] Redirección automática a `/tenant-admin-home`
- [ ] Dashboard muestra métricas correctamente
- [ ] Configuración básica funciona (editar y guardar)
- [ ] Branding funciona (editar colores y logo)
- [ ] Precios base funcionan (editar y guardar)
- [ ] Horarios de operación funcionan (seleccionar horas y días)
- [ ] Lista de profesores se carga
- [ ] Búsqueda de profesores funciona
- [ ] Filtros de profesores funcionan
- [ ] Activar/desactivar profesor funciona
- [ ] Invitar profesor funciona
- [ ] Lista de canchas se carga
- [ ] Búsqueda de canchas funciona
- [ ] Filtros de canchas funcionan
- [ ] Crear cancha funciona
- [ ] Editar cancha funciona
- [ ] Eliminar cancha funciona (con confirmación)
- [ ] Activar/desactivar cancha funciona
- [ ] Navegación entre pantallas funciona
- [ ] Mensajes de éxito/error se muestran correctamente

---

## 🔍 Logs y Debugging

### Ver logs de la app

```bash
# Si estás ejecutando la app, los logs aparecen en la terminal
# O usa:
flutter logs
```

### Ver logs del backend

```bash
# En la terminal donde corre el backend
# Deberías ver los requests que llegan
```

### Verificar requests HTTP

Los requests deberían incluir automáticamente:
- `Authorization: Bearer <firebase_token>`
- `X-Tenant-ID: <tenant_id>` (agregado automáticamente por AppHttpClient)

---

## ✅ Estado Actual

**Funcionalidades implementadas:**
- ✅ Dashboard con métricas
- ✅ Configuración completa del centro
- ✅ Gestión de profesores (listar, invitar, activar/desactivar)
- ✅ Gestión de canchas (listar, crear, editar, eliminar, activar/desactivar)
- ✅ Navegación completa
- ✅ Validaciones de formularios
- ✅ Manejo de errores

**Pendiente (requiere endpoints del backend):**
- ⏳ Gestión de reservas
- ⏳ Gestión de pagos
- ⏳ Gestión de estudiantes
- ⏳ Reportes y analytics

---

## 🚀 Siguiente Paso

Una vez probado todo lo anterior, puedes:
1. Continuar con las funcionalidades pendientes (cuando los endpoints estén listos)
2. Agregar más validaciones o mejoras de UI
3. Agregar tests unitarios/integración

