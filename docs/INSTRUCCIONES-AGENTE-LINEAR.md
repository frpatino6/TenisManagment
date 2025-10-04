# 🚨 INSTRUCCIONES CRÍTICAS PARA AGENTE - CONEXIÓN CON LINEAR

## ⚠️ PROBLEMA IDENTIFICADO:
El agente no pudo conectarse a Linear para análisis de testing. Estas son las instrucciones EXACTAS que debe seguir.

## 📋 PASOS OBLIGATORIOS:

### 1️⃣ VERIFICAR CONFIGURACIÓN DE LINEAR
**Ejecutar estos comandos en orden:**

```bash
# Navegar al directorio correcto
cd /home/fernando/Documentos/TenisManagment

# Verificar que existe el archivo de configuración
ls -la config/linear-config.env

# Verificar que existe el archivo de configuración de Cursor
ls -la config/cursor_linear_config.json
```

### 2️⃣ PROBAR CONEXIÓN CON LINEAR
**Usar el script de verificación:**

```bash
# Ejecutar script de prueba de conexión
node scripts/test-linear-connection.js
```

**Si este comando falla, ejecutar:**
```bash
# Verificar que Node.js funciona
node --version

# Verificar que el script existe
ls -la scripts/test-linear-connection.js

# Verificar que las dependencias están instaladas
npm list
```

### 3️⃣ USAR SCRIPTS EXISTENTES DE LINEAR
**NO crear nuevos scripts. Usar los existentes:**

```bash
# Listar todos los scripts disponibles
ls -la scripts/

# Script principal de gestión de Linear
node scripts/linear-backlog-manager.js

# Script de análisis de backlog
node scripts/analyze-backlog-stories.js

# Script de verificación de conexión
node scripts/test-linear-connection.js
```

### 4️⃣ VERIFICAR ARCHIVOS DE CONFIGURACIÓN
**Revisar el contenido de los archivos:**

```bash
# Ver configuración de Linear (sin mostrar API key completo)
head -5 config/linear-config.env

# Ver configuración de Cursor
cat config/cursor_linear_config.json
```

### 5️⃣ SI NADA FUNCIONA - USAR MCP
**Como último recurso, usar las herramientas MCP:**

```bash
# Verificar si MCP está disponible
# (El agente debe usar las herramientas MCP disponibles en su entorno)
```

## 🔧 ARCHIVOS DE CONFIGURACIÓN ESPERADOS:

### `config/linear-config.env` debe contener:
```
LINEAR_API_KEY=lin_api_xxxxxxxxxxxxx
LINEAR_TEAM_ID=aaa1982d-5837-4cda-9f43-979abaa9f508
```

### `config/cursor_linear_config.json` debe contener:
```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-linear"],
      "env": {
        "LINEAR_API_KEY": "lin_api_xxxxxxxxxxxxx"
      }
    }
  }
}
```

## 📋 SCRIPTS DISPONIBLES EN `/scripts/`:

### Scripts de Linear:
- `linear-backlog-manager.js` - Gestión principal de Linear
- `test-linear-connection.js` - Prueba de conexión
- `analyze-backlog-stories.js` - Análisis de historias
- `standardize-backlog-stories.js` - Estandarización
- `create-feature-branch.js` - Creación de branches

### Scripts de Sprint Management:
- `sprint-management/start-sprint-1.js`
- `sprint-management/update-sprint-progress.js`

## 🚨 COMANDOS DE EMERGENCIA:

### Si NADA funciona, ejecutar en orden:
```bash
# 1. Verificar directorio de trabajo
pwd
# Debe mostrar: /home/fernando/Documentos/TenisManagment

# 2. Verificar estructura de archivos
ls -la
ls -la config/
ls -la scripts/

# 3. Verificar Node.js
node --version
npm --version

# 4. Instalar dependencias si es necesario
npm install

# 5. Probar script más simple
node scripts/test-linear-connection.js
```

## 📞 INFORMACIÓN DE DEBUGGING:

### Si el agente reporta errores, debe incluir:
1. **Mensaje de error completo**
2. **Comando que ejecutó**
3. **Directorio donde está trabajando** (`pwd`)
4. **Lista de archivos en config/** (`ls -la config/`)
5. **Lista de archivos en scripts/** (`ls -la scripts/`)

### Ejemplo de reporte de error:
```
ERROR: Cannot connect to Linear
COMMAND: node scripts/test-linear-connection.js
DIRECTORY: /home/fernando/Documentos/TenisManagment
CONFIG FILES: linear-config.env exists, cursor_linear_config.json exists
SCRIPTS: test-linear-connection.js exists
NODE VERSION: v18.17.0
```

## ✅ CRITERIOS DE ÉXITO:

### El agente habrá resuelto el problema cuando:
1. ✅ `node scripts/test-linear-connection.js` ejecuta sin errores
2. ✅ Muestra información del usuario de Linear
3. ✅ Muestra lista de proyectos disponibles
4. ✅ Puede ejecutar `node scripts/linear-backlog-manager.js`

## 🚫 LO QUE NO DEBE HACER:

- ❌ NO crear nuevos scripts de Linear
- ❌ NO modificar archivos de configuración
- ❌ NO instalar nuevas dependencias sin consultar
- ❌ NO trabajar en directorios incorrectos
- ❌ NO usar APIs de Linear directamente

## 📋 CHECKLIST FINAL:

Antes de reportar que "no puede conectarse", el agente debe verificar:

- [ ] Está en el directorio correcto: `/home/fernando/Documentos/TenisManagment`
- [ ] Archivo `config/linear-config.env` existe
- [ ] Archivo `config/cursor_linear_config.json` existe
- [ ] Script `scripts/test-linear-connection.js` existe
- [ ] Node.js está instalado y funciona
- [ ] Ejecutó `node scripts/test-linear-connection.js`
- [ ] Incluyó el mensaje de error completo en su reporte

---

**Si el agente sigue sin poder conectarse después de seguir TODOS estos pasos, entonces hay un problema más profundo que requiere investigación adicional.**
