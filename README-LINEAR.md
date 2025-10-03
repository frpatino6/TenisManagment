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

### User Stories (10):
- **Sprint 1:** Multi-Tenancy Foundation (16 pts)
- **Sprint 2:** Authentication & Authorization (18 pts)
- **Sprint 3:** Onboarding & Signup (16 pts)
- **Sprint 6:** Subscription & Billing (21 pts)
- **Sprint 8:** Admin Dashboard (8 pts)
- **Sprint 9:** Analytics & Reporting (8 pts)
- **Sprint 10:** Mobile App Features (5 pts)
- **Sprint 11:** Go-to-Market (21 pts)

**Total:** 32 issues, 169 story points

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
