#!/bin/bash

# Script para construir APK/AAB en modo DESARROLLO
# 
# Uso:
#   ./scripts/build_dev.sh          # APK debug
#   ./scripts/build_dev.sh apk      # APK debug
#   ./scripts/build_dev.sh appbundle # AAB release

set -e

BUILD_TYPE=${1:-apk}

echo "📦 Construyendo Tennis Management (DESARROLLO)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Flavor: dev"
echo "📱 Build type: $BUILD_TYPE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$BUILD_TYPE" = "appbundle" ]; then
    echo "🏗️  Construyendo App Bundle (AAB) para Google Play..."
    flutter build appbundle \
        --flavor dev \
        --target lib/main_dev.dart
    
    echo ""
    echo "✅ App Bundle construido exitosamente"
    echo "📍 Ubicación: build/app/outputs/bundle/devRelease/app-dev-release.aab"
else
    echo "🏗️  Construyendo APK..."
    flutter build apk \
        --flavor dev \
        --target lib/main_dev.dart
    
    echo ""
    echo "✅ APK construido exitosamente"
    echo "📍 Ubicación: build/app/outputs/flutter-apk/app-dev-release.apk"
fi

echo ""
echo "📱 Puedes instalar el APK con:"
echo "   adb install build/app/outputs/flutter-apk/app-dev-release.apk"

