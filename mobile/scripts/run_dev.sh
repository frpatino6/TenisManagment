#!/bin/bash

# Script para ejecutar la app en modo DESARROLLO
# 
# Uso:
#   ./scripts/run_dev.sh
#   ./scripts/run_dev.sh android
#   ./scripts/run_dev.sh ios

set -e

echo "🚀 Ejecutando Tennis Management en modo DESARROLLO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Backend: http://10.0.2.2:3000 (localhost)"
echo "🔧 Flavor: dev"
echo "📦 App Name: Tennis DEV"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detectar plataforma si no se especifica
PLATFORM=${1:-}

if [ -z "$PLATFORM" ]; then
    echo "✨ Detectando dispositivos disponibles..."
    echo ""
fi

# Ejecutar Flutter con el flavor dev
flutter run \
    --flavor dev \
    --target lib/main_dev.dart \
    ${PLATFORM:+-d $PLATFORM}

echo ""
echo "✅ App ejecutada exitosamente"

