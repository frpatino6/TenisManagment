#!/bin/bash

# Script para corregir la configuración de Render
# Este script identifica y corrige problemas de configuración

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔧 Analizando problemas de configuración de Render..."
echo ""

# 1. Verificar variables de entorno requeridas
print_status "Verificando variables de entorno requeridas..."

# JWT_SECRET es crítico
if ! grep -q "JWT_SECRET" render.yaml || grep -q "sync: false" render.yaml; then
    print_error "JWT_SECRET no está configurado correctamente en render.yaml"
    print_warning "JWT_SECRET es requerido y debe tener al menos 10 caracteres"
fi

# MONGO_URI es crítico
if ! grep -q "MONGO_URI" render.yaml || grep -q "sync: false" render.yaml; then
    print_error "MONGO_URI no está configurado correctamente en render.yaml"
    print_warning "MONGO_URI es requerido para conectar a la base de datos"
fi

# FIREBASE variables
if ! grep -q "FIREBASE_PRIVATE_KEY" render.yaml || grep -q "sync: false" render.yaml; then
    print_warning "FIREBASE_PRIVATE_KEY no está configurado (opcional pero recomendado)"
fi

if ! grep -q "FIREBASE_CLIENT_EMAIL" render.yaml || grep -q "sync: false" render.yaml; then
    print_warning "FIREBASE_CLIENT_EMAIL no está configurado (opcional pero recomendado)"
fi

echo ""

# 2. Crear render.yaml corregido
print_status "Creando render.yaml corregido..."

cat > render-fixed.yaml << 'EOF'
services:
  - type: web
    name: tennis-management-backend
    env: node
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm start
    healthCheckPath: /health
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 3000
      - key: MONGO_URI
        value: mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tenisManagment
      - key: JWT_SECRET
        value: tennis_management_jwt_secret_key_2024_production
      - key: FIREBASE_PROJECT_ID
        value: tennis-management-fcd54
      - key: FIREBASE_PRIVATE_KEY
        value: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
      - key: FIREBASE_CLIENT_EMAIL
        value: firebase-adminsdk-xxxxx@tennis-management-fcd54.iam.gserviceaccount.com
      - key: CORS_ORIGINS
        value: https://tennis-management-fcd54.web.app
      - key: JSON_LIMIT
        value: 1mb
      - key: RATE_LIMIT_WINDOW_MS
        value: 900000
      - key: RATE_LIMIT_MAX
        value: 100
      - key: RATE_LIMIT_AUTH_MAX
        value: 20
EOF

print_success "render-fixed.yaml creado"

# 3. Mostrar diferencias
echo ""
print_status "Diferencias entre render.yaml actual y corregido:"
echo "================================================"
diff render.yaml render-fixed.yaml || true

echo ""
print_warning "IMPORTANTE: Necesitas configurar las siguientes variables en Render Dashboard:"
echo ""
echo "1. Ve a: https://dashboard.render.com"
echo "2. Selecciona tu servicio: tennis-management-backend"
echo "3. Ve a 'Environment'"
echo "4. Configura las siguientes variables:"
echo ""
echo "   🔑 JWT_SECRET: tennis_management_jwt_secret_key_2024_production"
echo "   🗄️  MONGO_URI: mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tenisManagment"
echo "   🔥 FIREBASE_PRIVATE_KEY: [Tu clave privada de Firebase]"
echo "   📧 FIREBASE_CLIENT_EMAIL: [Tu email de servicio de Firebase]"
echo ""
echo "5. Después de configurar las variables, haz un nuevo despliegue:"
echo "   ./deploy-to-render.sh"
echo ""

# 4. Crear script de verificación
print_status "Creando script de verificación..."

cat > verify-deployment.sh << 'EOF'
#!/bin/bash

echo "🔍 Verificando estado del despliegue..."

# Esperar un momento
sleep 10

echo "🌐 Verificando endpoint principal..."
curl -s -w "HTTP Status: %{http_code}\n" https://tennis-management-backend.onrender.com/ || echo "❌ Servicio no disponible"

echo ""
echo "🏥 Verificando endpoint de health..."
curl -s -w "HTTP Status: %{http_code}\n" https://tennis-management-backend.onrender.com/health || echo "❌ Health check no disponible"

echo ""
echo "📊 Si el servicio devuelve 200, el despliegue fue exitoso."
echo "📊 Si devuelve 404 o 500, revisa los logs en Render Dashboard."
EOF

chmod +x verify-deployment.sh
print_success "Script de verificación creado: verify-deployment.sh"

echo ""
print_success "Análisis completado. Revisa los problemas identificados arriba."
