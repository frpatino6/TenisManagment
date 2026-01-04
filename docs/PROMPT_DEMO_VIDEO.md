# Prompt para Crear Demo de Video de Tennis Management System

## Contexto del Sistema

Soy el desarrollador de **Tennis Management System**, una plataforma multi-tenant para gestión de centros de tenis/padel. Necesito crear un video demo profesional de la aplicación móvil.

## Información sobre la Aplicación

### Tipo de Aplicación
- **Plataforma:** Flutter (móvil)
- **Backend:** Node.js + Express + MongoDB
- **Autenticación:** Firebase Auth
- **Arquitectura:** Multi-tenant (múltiples centros operando independientemente)

### Usuarios y Roles
1. **Estudiantes:** Pueden reservar clases con profesores o alquilar canchas
2. **Profesores:** Gestionan sus horarios, ven estudiantes, configuran precios
3. **Tenant Admin:** Administra su centro (configuración, profesores, canchas, reportes)
4. **Super Admin:** Gestiona todos los tenants del sistema

### Funcionalidades Principales de la App Móvil

#### Para Estudiantes:
- **Home Screen:** Dashboard con favoritos y accesos rápidos
- **Reservar Clase:** Ver horarios de profesores favoritos agrupados por centro, reservar en 3 toques
- **Reservar Cancha:** Seleccionar cancha, fecha y hora disponible (sin necesidad de profesor)
- **Mis Reservas:** Ver todas las reservas (clases y canchas) con información de la cancha asignada
- **Mi Balance:** Ver balance de pagos por centro
- **Solicitar Servicio:** Solicitar servicios personalizados
- **Selección de Centro:** Cambiar entre múltiples centros donde el estudiante tiene actividad

#### Para Profesores:
- **Dashboard:** Vista de clases del día, métricas de ingresos
- **Crear Horarios:** Crear horarios disponibles para que estudiantes reserven
- **Gestionar Horarios:** Ver, editar, bloquear, completar horarios
- **Lista de Estudiantes:** Ver estudiantes con progreso y estadísticas
- **Configuración de Precios:** Configurar precios personalizados por tipo de clase
- **Analytics:** Ver reportes de ingresos, reservas, tendencias
- **Selección de Centro:** Cambiar entre múltiples centros donde trabaja

### Características Técnicas Destacables

1. **Multi-Tenancy:**
   - Cada centro (tenant) opera independientemente
   - Estudiantes pueden reservar en múltiples centros
   - Profesores pueden trabajar en múltiples centros
   - Balance y datos separados por centro

2. **Reservas Inteligentes:**
   - Asignación automática de canchas a clases con profesor
   - Validación de disponibilidad en tiempo real
   - Prevención de doble reserva
   - Horarios de operación configurables por centro

3. **Sistema de Precios:**
   - Precios base por centro
   - Precios personalizados por profesor
   - Cálculo automático según configuración

4. **Gestión de Disponibilidad:**
   - Slots horarios calculados automáticamente según horarios de operación
   - Validación de conflictos en tiempo real
   - Filtrado de horarios ocupados

## Objetivo del Demo

Crear un video demo profesional de **2-5 minutos** que muestre:
1. Las funcionalidades principales de la app
2. La experiencia de usuario fluida
3. El valor del sistema multi-tenant
4. La facilidad de uso (reserva en 3 toques)

## Estructura Sugerida del Demo

### Opción 1: Flujo de Estudiante (Recomendado)
1. **Intro (10-15 seg):**
   - "Tennis Management System - La plataforma completa para gestionar tu centro de tenis"
   - Mostrar logo/pantalla de inicio

2. **Login y Selección de Centro (20-30 seg):**
   - Login rápido
   - Selección de centro (mostrar multi-tenant)

3. **Home Screen (15-20 seg):**
   - Mostrar dashboard con favoritos
   - Accesos rápidos visibles

4. **Reservar Clase (45-60 seg):**
   - Tocar profesor favorito
   - Ver horarios agrupados por centro
   - Seleccionar horario
   - Confirmar reserva (mostrar que es rápido - 3 toques)

5. **Reservar Cancha (30-40 seg):**
   - Ir a "Reservar Cancha"
   - Seleccionar cancha
   - Seleccionar fecha
   - Ver slots disponibles (mostrar que solo muestra disponibles)
   - Seleccionar hora y confirmar

6. **Mis Reservas (20-30 seg):**
   - Ver lista de reservas
   - Mostrar que incluye información de cancha asignada
   - Mostrar diferentes tipos (clase individual, cancha)

7. **Cierre (10-15 seg):**
   - "Gestiona tu centro de tenis de forma profesional"
   - Call to action o contacto

### Opción 2: Flujo de Profesor
1. **Intro (10-15 seg)**
2. **Dashboard del Profesor (20-30 seg):**
   - Mostrar clases del día
   - Métricas de ingresos
3. **Crear Horario (30-40 seg):**
   - Mostrar formulario
   - Seleccionar fecha y hora
   - Guardar
4. **Gestionar Horarios (20-30 seg):**
   - Ver lista de horarios
   - Mostrar estados (disponible, reservado)
5. **Lista de Estudiantes (20-30 seg):**
   - Ver estudiantes
   - Mostrar progreso
6. **Analytics (20-30 seg):**
   - Mostrar gráficos de ingresos
7. **Cierre (10-15 seg)**

### Opción 3: Demo Completo (Ambos Roles)
- Primera mitad: Flujo de estudiante
- Segunda mitad: Flujo de profesor
- Mostrar cómo ambos interactúan en el sistema

## Elementos Visuales a Destacar

1. **Multi-Tenancy:**
   - Mostrar selector de centro
   - Mencionar que cada centro es independiente

2. **Reserva Rápida:**
   - Enfatizar "reserva en 3 toques"
   - Mostrar flujo simplificado

3. **Disponibilidad en Tiempo Real:**
   - Mostrar que solo aparecen horarios disponibles
   - Mostrar validación de conflictos

4. **Asignación Automática de Canchas:**
   - Mencionar que las clases con profesor también asignan cancha automáticamente

5. **Diseño Moderno:**
   - Mostrar UI limpia y profesional
   - Material Design 3

## Guion de Narración Sugerido

### Versión Corta (2-3 minutos)

**[Intro]**
"Tennis Management System es la plataforma completa para gestionar tu centro de tenis o padel. Con soporte multi-tenant, múltiples centros pueden operar de forma independiente en la misma plataforma."

**[Home]**
"Los estudiantes tienen acceso a un dashboard personalizado con sus profesores favoritos y accesos rápidos a las funciones más usadas."

**[Reservar Clase]**
"Reservar una clase es increíblemente simple. Con solo 3 toques, el estudiante puede ver los horarios de su profesor favorito, seleccionar un horario disponible y confirmar la reserva. El sistema asigna automáticamente una cancha disponible."

**[Reservar Cancha]**
"Para alquileres de cancha, el estudiante simplemente selecciona la cancha, la fecha, y ve solo los horarios disponibles. El sistema valida la disponibilidad en tiempo real."

**[Mis Reservas]**
"Todas las reservas se muestran en un solo lugar, incluyendo información de la cancha asignada, ya sea para clases o alquileres."

**[Cierre]**
"Tennis Management System: La solución completa para tu centro de tenis. Multi-tenant, intuitiva y profesional."

### Versión Extendida (4-5 minutos)

Incluir también:
- Flujo de profesor (crear horarios, ver estudiantes)
- Mencionar Tenant Admin (gestión del centro)
- Mostrar analytics y reportes
- Destacar características técnicas (multi-tenant, disponibilidad en tiempo real)

## Requerimientos Técnicos del Video

- **Duración:** 2-5 minutos
- **Formato:** MP4, 1080p o 4K
- **Aspecto:** 16:9 (landscape) o 9:16 (vertical para redes sociales)
- **Audio:** Narración clara o música de fondo profesional
- **Subtítulos:** Opcionales pero recomendados
- **Transiciones:** Suaves y profesionales
- **Zoom/Enfoque:** Resaltar elementos importantes de la UI

## Herramientas Recomendadas

1. **Grabación:**
   - Android: AZ Screen Recorder
   - iOS: Grabación de pantalla nativa
   - Emulador: OBS Studio

2. **Edición con IA:**
   - **Descript** (recomendado): Edición por transcripción, mejora de audio, eliminación de filler words
   - **Runway ML**: Efectos visuales y transiciones
   - **CapCut**: Gratis, con funciones de IA

3. **Audio:**
   - Narración profesional o texto a voz
   - Música de fondo (opcional)
   - Efectos de sonido sutiles

## Puntos Clave a Comunicar

1. ✅ **Multi-tenant:** Múltiples centros en una plataforma
2. ✅ **Reserva Rápida:** 3 toques para reservar
3. ✅ **Inteligente:** Asignación automática de canchas, validación de disponibilidad
4. ✅ **Completo:** Estudiantes, profesores, administradores
5. ✅ **Profesional:** UI moderna, experiencia fluida

## Tono y Estilo

- **Profesional pero accesible**
- **Enfocado en beneficios, no solo características**
- **Mostrar la facilidad de uso**
- **Destacar la innovación (multi-tenant, automatización)**

## Call to Action Sugerido

- "Prueba Tennis Management System hoy"
- "Contacta para una demo personalizada"
- "Gestiona tu centro de tenis de forma profesional"
- "Disponible para iOS y Android"

---

## Instrucciones para el Agente de IA

Por favor, ayúdame a:

1. **Crear un guion detallado** para el video demo basado en la información proporcionada
2. **Sugerir mejoras** a la estructura del demo
3. **Crear un storyboard** con las pantallas clave a mostrar
4. **Proporcionar tips de grabación** específicos para apps móviles
5. **Recomendar música/audio** apropiado para el tono profesional
6. **Crear versiones del guion** (corta 2-3 min, extendida 4-5 min)
7. **Sugerir elementos visuales** adicionales (animaciones, textos, callouts)

Si tienes acceso a herramientas de generación de video, también puedes ayudar con:
- Generar clips de introducción
- Crear transiciones
- Sugerir efectos visuales

**Prioridad:** Crear un demo que muestre claramente el valor del sistema y la facilidad de uso, especialmente el flujo de "reserva en 3 toques" y el concepto multi-tenant.

