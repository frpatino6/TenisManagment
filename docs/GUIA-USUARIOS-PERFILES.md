# Guía de Usuarios - Perfiles y Características

**Tennis Management System**  
Documento para usuarios finales

---

## Introducción

Esta guía describe las funcionalidades principales disponibles para cada tipo de usuario en la aplicación. Identifica tu perfil y descubre todo lo que puedes hacer.

---

## 👔 Administrador del Centro (Tenant Admin)

Si eres el **administrador de un club o academia de tenis**, tienes acceso a las siguientes funcionalidades:

### Panel Principal
- **Dashboard**: Vista general con métricas clave: pagos totales, reservas, ingresos, número de profesores, estudiantes y canchas
- **Profesores más activos**: Lista de los profesores con mayor cantidad de reservas
- **Accesos rápidos**: Navegación directa a cada sección del panel

### Configuración del Centro
- **Información básica**: Nombre del centro, slug (identificador para URL) y dominio
- **Precios base**: Definir precios por defecto para clase individual, clase grupal y alquiler de cancha
- **Horarios de operación**: Configurar horario de apertura y cierre por cada día de la semana (lunes a domingo)
- **Branding**: Logo, sitio web y dirección del centro

### Gestión de Profesores
- **Lista de profesores**: Ver todos los profesores del centro con búsqueda
- **Invitar profesor**: Enviar invitación por correo electrónico a nuevos profesores
- **Detalle de profesor**: Ver información completa y estadísticas de cada profesor
- **Activar o desactivar**: Dar de alta o baja a profesores según su disponibilidad

### Gestión de Canchas
- **Lista de canchas**: Ver todas las canchas (tenis, pádel o mixtas)
- **Crear cancha**: Registrar nuevas canchas con nombre, tipo, precio y características
- **Editar cancha**: Modificar información de canchas existentes

### Gestión de Reservas
- **Lista de reservas**: Ver todas las reservas del centro con filtros
- **Vista calendario**: Ver reservas organizadas por fecha
- **Estadísticas de reservas**: Métricas y reportes de facturación
- **Detalle de reserva**: Ver información completa (estudiante, profesor, cancha, precio, estado)
- **Confirmar pago y reserva**: Marcar como pagada una reserva pendiente cuando el estudiante paga en efectivo o transferencia
- **Cancelar reserva**: Anular reservas cuando sea necesario

### Gestión de Pagos
- **Lista de pagos**: Ver todos los pagos registrados en el centro
- **Seguimiento de ingresos**: Control de cobros realizados

### Gestión de Estudiantes
- **Lista de estudiantes**: Ver todos los estudiantes del centro con búsqueda
- **Detalle de estudiante**: Información completa, reservas y balance de cada estudiante

### Reportes
- **Reporte de deudas**: Lista de estudiantes con balance pendiente (deudores), con búsqueda por nombre o email. Resumen del total adeudado

### Torneos
- **Gestionar torneos**: Acceso al módulo de torneos para crear, configurar y administrar competencias (fases de grupos, cuadros de eliminación)

### Configuración de Cuenta
- **Tema**: Cambiar entre tema claro y oscuro
- **Cerrar sesión**: Salir de la aplicación

---

## 🎾 Profesor

Si eres **profesor de tenis** en uno o más centros, puedes utilizar:

### Panel Principal
- **Bienvenida personalizada**: Mensaje con tu nombre
- **Selector de centro**: Si trabajas en varios centros, cambiar entre ellos para ver la información correspondiente
- **Horarios de hoy**: Vista de tus clases del día con opción de navegar por fecha (ayer, hoy, mañana, etc.)
- **Estadísticas rápidas**: Número de estudiantes, clases del día, ganancias de la semana, rating
- **Ganancias del mes**: Resumen visual de tus ingresos mensuales

### Gestión de Horarios
- **Crear horario**: Publicar nuevos bloques de disponibilidad para que los estudiantes reserven
- **Gestionar horarios**: Ver y modificar tu disponibilidad existente
- **Horarios por fecha**: Navegar día a día para ver tus clases programadas

### Acciones sobre Reservas (desde el widget de horarios)
- **Completar clase**: Marcar una reserva como realizada cuando la clase se impartió
- **Registrar pago**: Indicar cuando el estudiante pagó la clase (efectivo, transferencia, etc.)
- **Cancelar reserva**: Cancelar una clase con motivo opcional. Puedes aplicar **penalización** (monto en dinero) cuando el estudiante no asiste o cancela fuera de plazo
- **Ver detalle**: Consultar información del estudiante y la reserva

### Precios y Servicios
- **Configurar precios**: Definir tus tarifas para clase individual, clase grupal y alquiler de cancha
- **Precios personalizados**: Usar precios diferentes a los del centro si lo deseas

### Gestión de Estudiantes
- **Mis estudiantes**: Lista de todos los estudiantes que tienen reservas contigo
- **Búsqueda**: Filtrar estudiantes por nombre
- **Perfil de estudiante**: Ver información completa de cada estudiante:
  - Nombre, email, teléfono
  - Tipo de membresía (premium o regular)
  - Balance actual (saldo a favor o deuda)
  - Fecha de registro

### Analytics (Dashboard de Métricas)
- **Filtros**: Por período (semana, mes, año), tipo de servicio y estado de reserva
- **Métricas**: Ingresos, cantidad de reservas, estudiantes atendidos
- **Gráficos**: Visualización de tendencias y rendimiento
- **Detalle por métrica**: Profundizar en cada indicador

### Configuración de Cuenta
- **Editar perfil**: Actualizar tu información personal
- **Tema**: Cambiar entre tema claro y oscuro
- **Cerrar sesión**: Salir de la aplicación

---

## 🏃 Estudiante

Si eres **estudiante o jugador** que toma clases en un centro, tienes acceso a:

### Inicio (Pantalla Principal)
- **Saludo personalizado**: Mensaje con tu nombre
- **Favoritos**: Tus profesores y centros favoritos para acceso rápido. Si no tienes favoritos, puedes explorar centros o buscar profesores
- **Acciones rápidas**: Acceso directo a las funciones más usadas

### Reservas
- **Reservar clase**: Buscar profesores disponibles, ver sus horarios y reservar clase individual o grupal
- **Reservar cancha**: Alquilar una cancha directamente sin profesor (según disponibilidad del centro)
- **Mis reservas**: Ver todas tus reservas (pasadas y futuras) con estado (pendiente, confirmada, completada, cancelada)
- **Actividad reciente**: Historial de tus últimas clases y próximas citas

### Pagos
- **Mi balance**: Ver tu saldo actual (a favor o pendiente de pago). Si el centro tiene pagos en línea habilitados (Wompi), puedes **pagar tu deuda con tarjeta** desde la app
- **Historial de pagos**: Ver el detalle de todos los pagos que has realizado

### Solicitar Servicio
- **Formulario de solicitud**: Enviar solicitudes al centro para:
  - Clase personalizada
  - Alquiler de equipos
  - Reserva de cancha
  - Organización de torneo
  - Encordado
  - Otros servicios
- **Prioridad**: Indicar si la solicitud es baja, media o alta
- **Notas**: Agregar descripción y observaciones

### Ranking
- **Ver posiciones**: Consultar el ranking de jugadores del centro
- **Reportar resultado**: Registrar el marcador de un partido jugado (ej: 6-2, 6-4). Puedes indicar si fue partido de torneo o partido regular, y si fue en horario valle

### Torneos
- **Ver torneos**: Lista de torneos disponibles en tu centro
- **Detalle de torneo**: Información, categorías e inscripciones
- **Inscribirse**: Participar en torneos abiertos
- **Fase de grupos**: Ver grupos, partidos y tabla de posiciones
- **Cuadro de eliminación (bracket)**: Ver el árbol de partidos de la fase final

### Configuración
- **Cambiar centro**: Seleccionar otro club o academia si tienes varios (o elegir tu centro predeterminado al iniciar)
- **Tema**: Cambiar entre tema claro y oscuro
- **Cerrar sesión**: Salir de la aplicación

### Tipos de Servicio Disponibles
- **Clase individual**: Clase personalizada con un profesor
- **Clase grupal**: Clase con varios alumnos
- **Alquiler de cancha**: Reservar una cancha sin profesor (tenis, pádel o mixta)

---

## Resumen Rápido

| Perfil | En pocas palabras |
|--------|-------------------|
| **Administrador del Centro** | Configura el club (precios, horarios, branding), gestiona profesores, canchas, reservas, pagos y estudiantes. Consulta métricas, reporte de deudas y administra torneos |
| **Profesor** | Publica horarios, gestiona reservas (completar, cancelar, aplicar penalizaciones), registra pagos, ve estudiantes y sus balances, analiza ganancias y métricas |
| **Estudiante** | Reserva clases o canchas, paga (incluso en línea si el centro lo permite), solicita servicios, participa en ranking y torneos, gestiona favoritos y balance |

---

## Notas Importantes

- **Múltiples centros**: Los profesores pueden estar asociados a varios centros y cambiar entre ellos. Los estudiantes pueden tener centros favoritos y cambiar de centro cuando lo necesiten.
- **Pagos en línea**: La opción de pagar con tarjeta (Wompi) depende de que el administrador del centro la haya configurado.
- **Torneos**: Los administradores del centro crean y gestionan torneos. Los estudiantes pueden inscribirse y participar.
- **Balance**: Si tienes balance pendiente (deuda), aparecerá en "Mi Balance" y en el reporte de deudas del administrador.

---

## ¿Tienes dudas?

Si necesitas ayuda para usar alguna función o no encuentras lo que buscas, contacta al administrador de tu centro o al equipo de soporte.

---

*Documento actualizado: Febrero 2025*  
*Basado en análisis del código de la aplicación*
