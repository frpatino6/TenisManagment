#!/bin/bash

# Script para construir APK/AAB en modo PRODUCCIÓN
# 
# Uso:
#   ./scripts/build_prod.sh          # APK release
#   ./scripts/build_prod.sh apk      # APK release
#   ./scripts/build_prod.sh appbundle # AAB release

set -e

BUILD_TYPE=${1:-apk}

echo "📦 Construyendo Tennis Management (PRODUCCIÓN)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Flavor: prod"
echo "📱 Build type: $BUILD_TYPE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$BUILD_TYPE" = "appbundle" ]; then
    echo "🏗️  Construyendo App Bundle (AAB) para Google Play..."
    flutter build appbundle \
        --flavor prod \
        --target lib/main_prod.dart \
        --release
    
    echo ""
    echo "✅ App Bundle construido exitosamente"
    echo "📍 Ubicación: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
else
    echo "🏗️  Construyendo APK release..."
    flutter build apk \
        --flavor prod \
        --target lib/main_prod.dart \
        --release
    
    echo ""
    echo "✅ APK construido exitosamente"
    echo "📍 Ubicación: build/app/outputs/flutter-apk/app-prod-release.apk"
fi

echo ""
echo "⚠️  IMPORTANTE: Este build es para PRODUCCIÓN"
echo "📱 Puedes instalar el APK con:"
echo "   adb install build/app/outputs/flutter-apk/app-prod-release.apk"

