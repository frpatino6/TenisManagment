#!/bin/bash

# Script para ejecutar la app en modo PRODUCCIÓN
# 
# Uso:
#   ./scripts/run_prod.sh
#   ./scripts/run_prod.sh android
#   ./scripts/run_prod.sh ios

set -e

echo "🚀 Ejecutando Tennis Management en modo PRODUCCIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Backend: https://cloudflow-uat.duckdns.org"
echo "🔧 Flavor: prod"
echo "📦 App Name: Tennis Management"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detectar plataforma si no se especifica
PLATFORM=${1:-}

if [ -z "$PLATFORM" ]; then
    echo "✨ Detectando dispositivos disponibles..."
    echo ""
fi

# Ejecutar Flutter con el flavor prod
flutter run \
    --flavor prod \
    --target lib/main_prod.dart \
    ${PLATFORM:+-d $PLATFORM}

echo ""
echo "✅ App ejecutada exitosamente"

