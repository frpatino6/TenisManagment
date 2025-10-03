#!/bin/bash

# Script para configurar variables de entorno en Render de forma segura
# Este script NO expone las claves en el código

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

echo "🔧 Configurando variables de entorno para Render..."
echo ""

# Variables de entorno que necesitas configurar en Render Dashboard
echo "📋 Variables de entorno que debes configurar en Render Dashboard:"
echo "================================================================"
echo ""
echo "1. Ve a: https://dashboard.render.com"
echo "2. Selecciona tu servicio: tennis-management-backend"
echo "3. Ve a la pestaña 'Environment'"
echo "4. Agrega las siguientes variables:"
echo ""

echo "🔑 Variables críticas:"
echo "   NODE_ENV = production"
echo "   PORT = 3000"
echo "   MONGO_URI = mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tennis_mgmt"
echo "   JWT_SECRET = tennis_management_secret_key_2024"
echo ""

echo "🔥 Variables de Firebase:"
echo "   FIREBASE_PROJECT_ID = tennis-management-fcd54"
echo "   FIREBASE_CLIENT_EMAIL = firebase-adminsdk-fbsvc@tennis-management-fcd54.iam.gserviceaccount.com"
echo "   FIREBASE_PRIVATE_KEY = [La clave privada completa que me proporcionaste]"
echo ""

echo "🌐 Variables de CORS y Rate Limiting:"
echo "   CORS_ORIGINS = https://tennis-management-fcd54.web.app"
echo "   JSON_LIMIT = 1mb"
echo "   RATE_LIMIT_WINDOW_MS = 900000"
echo "   RATE_LIMIT_MAX = 100"
echo "   RATE_LIMIT_AUTH_MAX = 20"
echo ""

echo "⚠️  IMPORTANTE:"
echo "   - Copia EXACTAMENTE los valores mostrados arriba"
echo "   - Para FIREBASE_PRIVATE_KEY, copia toda la clave incluyendo los saltos de línea"
echo "   - Asegúrate de que no haya espacios extra al inicio o final"
echo ""

echo "✅ Una vez configuradas las variables, ejecuta:"
echo "   ./deploy-to-render.sh"
echo ""

print_success "Configuración de variables de entorno completada"
