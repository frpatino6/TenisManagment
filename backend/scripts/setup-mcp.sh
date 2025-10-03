#!/bin/bash

# Script de configuración para el servidor MCP de Render
# Este script configura automáticamente el entorno para el servidor MCP

set -e

echo "🚀 Configurando servidor MCP para Render..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    print_error "No se encontró package.json. Ejecuta este script desde el directorio del backend."
    exit 1
fi

# 1. Instalar dependencias del servidor MCP
print_status "Instalando dependencias del servidor MCP..."
if [ -f "package-mcp.json" ]; then
    npm install --package-lock-only package-mcp.json
    print_success "Dependencias MCP instaladas"
else
    print_warning "package-mcp.json no encontrado, instalando dependencias manualmente..."
    npm install --save-dev @modelcontextprotocol/sdk node-fetch dotenv
    print_success "Dependencias instaladas manualmente"
fi

# 2. Configurar archivo de entorno
print_status "Configurando archivo de entorno..."
if [ ! -f ".env.mcp" ]; then
    if [ -f "env.mcp.example" ]; then
        cp env.mcp.example .env.mcp
        print_success "Archivo .env.mcp creado desde ejemplo"
        print_warning "IMPORTANTE: Edita .env.mcp con tu API key de Render"
    else
        print_error "env.mcp.example no encontrado"
        exit 1
    fi
else
    print_warning ".env.mcp ya existe, no se sobrescribió"
fi

# 3. Hacer ejecutables los scripts
print_status "Configurando permisos de ejecución..."
chmod +x mcp-deploy-server.js
chmod +x mcp-deploy-server-enhanced.js
print_success "Permisos de ejecución configurados"

# 4. Verificar configuración de Render
print_status "Verificando configuración de Render..."
if [ -f "render.yaml" ]; then
    print_success "render.yaml encontrado"
else
    print_warning "render.yaml no encontrado - asegúrate de tenerlo configurado"
fi

# 5. Verificar que el servidor MCP funciona
print_status "Verificando servidor MCP..."
if node -e "require('@modelcontextprotocol/sdk')" 2>/dev/null; then
    print_success "SDK de MCP disponible"
else
    print_error "SDK de MCP no disponible - reinstala las dependencias"
    exit 1
fi

# 6. Crear script de inicio
print_status "Creando script de inicio..."
cat > start-mcp-server.sh << 'EOF'
#!/bin/bash
# Script para iniciar el servidor MCP

# Cargar variables de entorno
if [ -f ".env.mcp" ]; then
    export $(cat .env.mcp | grep -v '^#' | xargs)
fi

# Verificar que las variables necesarias estén configuradas
if [ -z "$RENDER_API_KEY" ]; then
    echo "❌ RENDER_API_KEY no está configurada en .env.mcp"
    echo "Obtén tu API key desde: https://dashboard.render.com/account/api-keys"
    exit 1
fi

if [ -z "$RENDER_SERVICE_ID" ]; then
    echo "❌ RENDER_SERVICE_ID no está configurada en .env.mcp"
    exit 1
fi

echo "🚀 Iniciando servidor MCP para Render..."
echo "📋 Servicio: $RENDER_SERVICE_ID"
echo "🌍 Ambiente: ${RENDER_ENVIRONMENT:-production}"

# Iniciar el servidor
node mcp-deploy-server-enhanced.js
EOF

chmod +x start-mcp-server.sh
print_success "Script de inicio creado: start-mcp-server.sh"

# 7. Crear script de test
print_status "Creando script de test..."
cat > test-mcp-server.sh << 'EOF'
#!/bin/bash
# Script para probar el servidor MCP

echo "🧪 Probando servidor MCP..."

# Cargar variables de entorno
if [ -f ".env.mcp" ]; then
    export $(cat .env.mcp | grep -v '^#' | xargs)
fi

# Verificar configuración
echo "📋 Verificando configuración..."
if [ -z "$RENDER_API_KEY" ]; then
    echo "❌ RENDER_API_KEY no configurada"
    exit 1
fi

if [ -z "$RENDER_SERVICE_ID" ]; then
    echo "❌ RENDER_SERVICE_ID no configurada"
    exit 1
fi

echo "✅ Configuración básica OK"

# Probar validación de build
echo "🔨 Probando validación de build..."
if npm run type-check > /dev/null 2>&1; then
    echo "✅ TypeScript check OK"
else
    echo "❌ TypeScript check falló"
fi

if npm run lint > /dev/null 2>&1; then
    echo "✅ Linting OK"
else
    echo "❌ Linting falló"
fi

if npm run build > /dev/null 2>&1; then
    echo "✅ Build OK"
else
    echo "❌ Build falló"
fi

echo "🎯 Test completado"
EOF

chmod +x test-mcp-server.sh
print_success "Script de test creado: test-mcp-server.sh"

# 8. Mostrar resumen
echo ""
echo "🎉 Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Edita .env.mcp con tu API key de Render:"
echo "   RENDER_API_KEY=tu_api_key_aqui"
echo ""
echo "2. Obtén tu API key desde:"
echo "   https://dashboard.render.com/account/api-keys"
echo ""
echo "3. Prueba la configuración:"
echo "   ./test-mcp-server.sh"
echo ""
echo "4. Inicia el servidor MCP:"
echo "   ./start-mcp-server.sh"
echo ""
echo "5. Configura Cursor/Claude Desktop con:"
echo "   mcp-config.json"
echo ""
echo "📚 Documentación completa: MCP_DEPLOY_README.md"
echo ""
print_success "¡Servidor MCP listo para usar!"
