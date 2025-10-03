# MCP Server para Automatización de Despliegues a Render

Este servidor MCP (Model Context Protocol) proporciona herramientas para automatizar el proceso de despliegue del backend de Tennis Management a la plataforma Render.

## 🚀 Características

- **Despliegue automatizado** a Render con validación previa
- **Monitoreo en tiempo real** del estado de despliegues
- **Gestión de logs** y historial de despliegues
- **Rollback automático** a versiones anteriores
- **Actualización de variables de entorno**
- **Validación de builds** locales antes del despliegue

## 📋 Herramientas Disponibles

### 1. `deploy_to_render`
Despliega el backend a Render con validación previa.

**Parámetros:**
- `environment`: Ambiente de despliegue (production/staging)
- `clear_cache`: Limpiar caché durante el despliegue
- `commit_sha`: SHA del commit específico a desplegar

**Ejemplo:**
```json
{
  "environment": "production",
  "clear_cache": true
}
```

### 2. `check_deployment_status`
Verifica el estado actual del servicio en Render.

**Parámetros:**
- `service_name`: Nombre del servicio (default: tennis-management-backend)

### 3. `get_deployment_logs`
Obtiene logs del servicio o despliegue específico.

**Parámetros:**
- `service_name`: Nombre del servicio
- `deploy_id`: ID del despliegue específico (opcional)
- `lines`: Número de líneas de logs (default: 100)

### 4. `get_deployment_history`
Muestra el historial de despliegues recientes.

**Parámetros:**
- `service_name`: Nombre del servicio
- `limit`: Número de despliegues a mostrar (default: 10)

### 5. `rollback_deployment`
Hace rollback a un despliegue anterior.

**Parámetros:**
- `service_name`: Nombre del servicio
- `deploy_id`: ID del despliegue al cual hacer rollback (o 'previous')

### 6. `update_environment_variables`
Actualiza variables de entorno en Render.

**Parámetros:**
- `service_name`: Nombre del servicio
- `variables`: Objeto con las variables a actualizar

**Ejemplo:**
```json
{
  "variables": {
    "NODE_ENV": "production",
    "API_VERSION": "v2"
  }
}
```

### 7. `validate_build`
Valida que el build local funcione correctamente.

**Parámetros:**
- `run_tests`: Ejecutar tests (default: true)
- `check_dependencies`: Verificar dependencias (default: true)

### 8. `monitor_deployment`
Monitorea el progreso de un despliegue en tiempo real.

**Parámetros:**
- `service_name`: Nombre del servicio
- `deploy_id`: ID del despliegue a monitorear
- `timeout_minutes`: Tiempo máximo de monitoreo (default: 10)

## ⚙️ Configuración

### 1. Instalar Dependencias

```bash
# Instalar dependencias del servidor MCP
npm install --save-dev @modelcontextprotocol/sdk node-fetch dotenv

# O usar el package.json específico
npm install --package-lock-only package-mcp.json
```

### 2. Configurar Variables de Entorno

Copia `env.mcp.example` a `.env.mcp` y configura:

```bash
cp env.mcp.example .env.mcp
```

Edita `.env.mcp` con tus valores:

```env
RENDER_API_KEY=tu_api_key_de_render
RENDER_SERVICE_ID=tennis-management-backend
RENDER_ENVIRONMENT=production
```

### 3. Obtener API Key de Render

1. Ve a [Render Dashboard](https://dashboard.render.com)
2. Navega a Account Settings > API Keys
3. Crea una nueva API Key
4. Copia la key a tu archivo `.env.mcp`

### 4. Configurar Cursor/Claude Desktop

Agrega la configuración del servidor MCP a tu archivo de configuración:

```json
{
  "mcpServers": {
    "render-deploy": {
      "command": "node",
      "args": ["/ruta/completa/al/backend/mcp-deploy-server-enhanced.js"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

## 🚀 Uso

### Iniciar el Servidor

```bash
# Modo desarrollo
npm run dev

# Modo producción
npm start
```

### Ejemplos de Uso

#### Despliegue Básico
```bash
# Desplegar a producción
deploy_to_render --environment production

# Desplegar con caché limpio
deploy_to_render --environment production --clear_cache true
```

#### Monitoreo
```bash
# Verificar estado
check_deployment_status

# Ver logs
get_deployment_logs --lines 50

# Ver historial
get_deployment_history --limit 5
```

#### Rollback
```bash
# Rollback al despliegue anterior
rollback_deployment --deploy_id previous

# Rollback a un despliegue específico
rollback_deployment --deploy_id abc123def456
```

## 🔧 Flujo de Despliegue

1. **Validación Local**
   - Verificación de dependencias
   - Linting y type-checking
   - Build del proyecto
   - Ejecución de tests (opcional)

2. **Despliegue a Render**
   - Trigger del despliegue via API
   - Monitoreo del progreso
   - Verificación del estado final

3. **Post-Despliegue**
   - Verificación de logs
   - Validación de endpoints
   - Notificación de estado

## 🛠️ Troubleshooting

### Error: "API Key no válida"
- Verifica que `RENDER_API_KEY` esté configurada correctamente
- Asegúrate de que la API Key tenga permisos suficientes

### Error: "Servicio no encontrado"
- Verifica que `RENDER_SERVICE_ID` coincida con el nombre del servicio en Render
- Usa el ID exacto del servicio si el nombre no funciona

### Error: "Build falló"
- Ejecuta `validate_build` para identificar problemas locales
- Verifica que todas las dependencias estén instaladas
- Revisa los logs de build en Render Dashboard

### Error: "Timeout en monitoreo"
- Aumenta `timeout_minutes` en la configuración
- Verifica manualmente el estado en Render Dashboard

## 📚 Recursos Adicionales

- [Render API Documentation](https://render.com/docs/api)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Tennis Management Backend](https://github.com/tu-repo/tennis-management-backend)

## 🤝 Contribución

Para contribuir al servidor MCP:

1. Fork el repositorio
2. Crea una rama para tu feature
3. Implementa los cambios
4. Agrega tests si es necesario
5. Envía un Pull Request

## 📄 Licencia

MIT License - ver archivo LICENSE para más detalles.
