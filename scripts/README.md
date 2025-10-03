# 📁 Scripts Directory

Este directorio contiene todos los scripts de automatización y utilidades para el proyecto Tennis Management.

## 📂 Estructura

### `linear/`
Scripts para integración y gestión con Linear (project management).

### `sprint-management/`
Scripts específicos para la gestión de sprints y seguimiento de progreso.

### Scripts Principales (raíz de scripts/)
- `linear-backlog-manager.js` - Script principal para gestionar el backlog
- `linear-utils.js` - Utilidades compartidas para la API de Linear
- `organize-sprints.js` - Organización y visualización de sprints

## 🚀 Uso

Todos los scripts están diseñados para ejecutarse desde la raíz del proyecto:

```bash
# Scripts principales
node scripts/linear-backlog-manager.js
node scripts/organize-sprints.js

# Scripts de Linear
node scripts/linear/check-issue-identifiers.js

# Scripts de Sprint Management
node scripts/sprint-management/update-sprint-progress.js
```

## 📋 Requisitos

- Node.js 18+
- Archivo `config/linear-config.env` configurado
- Acceso a la API de Linear

## 🔧 Configuración

Asegúrate de tener configurado el archivo `config/linear-config.env` con:
```
LINEAR_API_KEY=tu_api_key_aqui
LINEAR_TEAM_ID=tu_team_id_aqui
```
