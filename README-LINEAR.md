# Linear MCP Server Integration

Este directorio contiene scripts para integrar Linear con el proyecto Tennis Management System usando el Model Context Protocol (MCP).

## 🚀 Configuración Inicial

### 1. Obtener API Key de Linear

1. Ve a tu workspace de Linear: `https://linear.app/[TU-TEAM]/settings/api`
2. Crea una nueva API key
3. Copia la key generada

### 2. Configurar Variables de Entorno

1. Copia el archivo de ejemplo:
   ```bash
   cp linear-config.env.example linear-config.env
   ```

2. Edita `linear-config.env` y agrega tu información:
   ```bash
   LINEAR_API_KEY=tu_api_key_aqui
   LINEAR_TEAM_ID=tu_team_id_aqui
   ```

### 3. Obtener Team ID

Ejecuta el script de configuración para obtener tu Team ID:
```bash
node linear-backlog-manager.js
```

## 📋 Scripts Disponibles

### `linear-backlog-manager.js`
Script principal para gestionar el backlog de Linear.

**Uso:**
```bash
node linear-backlog-manager.js
```

**Funcionalidades:**
- Listar todos los issues
- Mostrar resumen de configuración
- Verificar asignaciones y story points
- Mostrar issues por categoría

### `linear-utils.js`
Utilidades compartidas para interactuar con la API de Linear.

**Funciones:**
- `getLinearConfig()`: Obtiene configuración de variables de entorno
- `makeLinearRequest(query, variables)`: Hace requests a la API de Linear
- `loadLinearConfig()`: Carga configuración desde archivo .env

### `organize-sprints.js`
Script para organizar y visualizar el backlog por sprints.

**Uso:**
```bash
node organize-sprints.js
```

**Funcionalidades:**
- Organizar issues por sprints
- Mostrar roadmap visual
- Calcular métricas por sprint
- Mostrar dependencias entre sprints

### `setup-sprint-milestones.js`
Script para configurar milestones en Linear.

**Uso:**
```bash
node setup-sprint-milestones.js
```

**Funcionalidades:**
- Crear milestones para cada sprint
- Asignar issues a milestones
- Configurar fechas objetivo
- Organizar timeline del proyecto

## 🔧 Configuración del MCP Server

### Para Cursor/Claude Desktop

Agrega esta configuración a tu archivo de configuración de Cursor:

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "linear-mcp-server"],
      "env": {
        "LINEAR_API_KEY": "tu_api_key_aqui"
      }
    }
  }
}
```

### Para uso directo

```bash
LINEAR_API_KEY=tu_api_key_aqui npx -y linear-mcp-server
```

## 📊 Backlog Creado

### Epics (8):
- Multi-Tenancy Foundation (Backend)
- User Authentication & Authorization
- Onboarding & Signup Flow
- Subscription & Billing
- Admin Dashboard
- Analytics & Reporting
- Mobile App Features
- Go-to-Market

### Sprint Planning (11 Sprints):

#### **Sprint 1 - Multi-Tenancy Foundation** (Semanas 1-2)
- US-MT-001: Crear Modelo de Tenant (3 pts)
- US-MT-002: Implementar TenantService (5 pts)
- US-MT-003: Middleware de Extracción de Tenant (8 pts)
- **Total:** 16 pts

#### **Sprint 2 - Authentication & Authorization** (Semanas 3-4)
- US-AUTH-001: Implementar JWT Authentication (5 pts)
- US-AUTH-002: Sistema de Roles y Permisos (8 pts)
- US-AUTH-003: Password Reset Flow (5 pts)
- **Total:** 18 pts

#### **Sprint 3 - Onboarding & Signup** (Semanas 5-6)
- US-ONB-001: Wizard de Registro de Club (13 pts)
- US-ONB-002: Email de Bienvenida (3 pts)
- **Total:** 16 pts

#### **Sprint 6 - Subscription & Billing** (Semanas 11-12)
- US-BILL-001: Integración con Stripe (Setup) (5 pts)
- US-BILL-003: Checkout Flow - Upgrade a Pro (8 pts)
- US-BILL-004: Webhook - checkout.session.completed (8 pts)
- **Total:** 21 pts

#### **Sprint 8 - Admin Dashboard** (Semanas 15-16)
- US-ADMIN-001: Dashboard de Super Admin (8 pts)
- **Total:** 8 pts

#### **Sprint 9 - Analytics & Reporting** (Semanas 17-18)
- US-ANALYTICS-001: Dashboard de Métricas (8 pts)
- **Total:** 8 pts

#### **Sprint 10 - Mobile Features** (Semanas 19-20)
- US-MOBILE-001: Notificaciones Push (5 pts)
- **Total:** 5 pts

#### **Sprint 11 - Go-to-Market** (Semanas 21-22)
- US-GTM-001: Landing Page (8 pts)
- US-GTM-002: Help Center (13 pts)
- **Total:** 21 pts

**Total:** 32 issues, 113 story points, 22 semanas

## 🎯 Funcionalidades del MCP Server

Una vez configurado, puedes usar comandos como:

- **"Muéstrame el progreso del Sprint 1"**
- **"Actualiza TEN-6 a estado 'In Progress'"**
- **"Agrega un comentario al issue TEN-7: 'Comenzando implementación'"**
- **"Busca todos los issues de Multi-Tenancy"**
- **"Crea un nuevo issue para bug fix"**

## 🔒 Seguridad

- **NUNCA** commites archivos con API keys
- Usa `linear-config.env` para variables de entorno
- El archivo `.env` está en `.gitignore`
- Los scripts usan variables de entorno para API keys

## 🚀 Uso de Scripts

### **Gestionar Sprint 1**
```bash
# Iniciar Sprint 1
node scripts/sprint-management/start-sprint-1.js

# Actualizar progreso
node scripts/sprint-management/update-sprint-progress.js

# Eliminar duplicados
node scripts/sprint-management/remove-duplicates-sprint1.js
```

### **Scripts de Linear**
```bash
# Verificar issues
node scripts/linear/check-issue-identifiers.js

# Asociar issues a projects
node scripts/linear/associate-issues-correct.js

# Verificar configuración
node scripts/linear/verify-linear-setup.js

# Configurar milestones
node scripts/linear/setup-sprint-milestones.js
```

### **Organización General**
```bash
# Organizar sprints
node organize-sprints.js

# Verificar configuración
node linear-backlog-manager.js
```

## 🚨 Troubleshooting

### Error: "LINEAR_API_KEY environment variable is required"
- Verifica que `linear-config.env` existe
- Verifica que contiene `LINEAR_API_KEY=tu_api_key`
- Verifica que la API key es válida

### Error: "Team ID not found"
- Ejecuta `node linear-backlog-manager.js` para obtener el Team ID
- Agrega el Team ID a `linear-config.env`

### Error: "Push blocked due to secrets"
- GitHub detectó una API key en el código
- Usa variables de entorno en lugar de hardcodear API keys
- Verifica que `linear-config.env` no esté en el commit

## 📚 Recursos

- [Linear API Documentation](https://developers.linear.app/docs/graphql/working-with-the-graphql-api)
- [MCP Server Documentation](https://github.com/modelcontextprotocol)
- [Linear MCP Server](https://github.com/jerhadf/linear-mcp-server)

## 🤝 Contribución

1. No commites archivos con API keys
2. Usa variables de entorno para configuración sensible
3. Documenta nuevos scripts en este README
4. Mantén los scripts seguros y reutilizables
