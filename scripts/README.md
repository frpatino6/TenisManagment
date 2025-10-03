# 📁 Scripts Directory

Este directorio contiene todos los scripts de automatización y utilidades para el proyecto Tennis Management.

## 📂 Estructura

### `linear/`
Scripts para integración y gestión con Linear (project management).

### `sprint-management/`
Scripts específicos para la gestión de sprints y seguimiento de progreso.

## 🚀 Uso

Todos los scripts están diseñados para ejecutarse desde la raíz del proyecto:

```bash
# Ejemplo: Scripts de Linear
node scripts/linear/check-issue-identifiers.js

# Ejemplo: Scripts de Sprint Management
node scripts/sprint-management/update-sprint-progress.js
```

## 📋 Requisitos

- Node.js 18+
- Archivo `linear-config.env` configurado en la raíz del proyecto
- Acceso a la API de Linear

## 🔧 Configuración

Asegúrate de tener configurado el archivo `linear-config.env` con:
```
LINEAR_API_KEY=tu_api_key_aqui
LINEAR_TEAM_ID=tu_team_id_aqui
```
