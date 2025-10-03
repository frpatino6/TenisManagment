#!/bin/bash

# Script para despliegue real a Render
# Este script hace commit y push de los cambios para trigger el despliegue automático en Render

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

echo "🚀 Iniciando despliegue real a Render..."
echo ""

# 1. Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    print_error "No se encontró package.json. Ejecuta este script desde el directorio del backend."
    exit 1
fi

# 2. Verificar que no hay cambios sin commitear
print_status "Verificando estado de Git..."
if [ -n "$(git status --porcelain)" ]; then
    print_warning "Hay cambios sin commitear. Haciendo commit automático..."
    
    # Agregar todos los cambios
    git add .
    
    # Hacer commit con mensaje automático
    git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S') - Despliegue automático a Render"
    
    print_success "Cambios committeados"
else
    print_success "No hay cambios pendientes"
fi

# 3. Verificar que el build funciona
print_status "Verificando build local..."
npm run build
print_success "Build local exitoso"

# 4. Verificar configuración de Render
print_status "Verificando configuración de Render..."
if [ ! -f "render.yaml" ]; then
    print_error "render.yaml no encontrado"
    exit 1
fi

if ! grep -q "tennis-management-backend" render.yaml; then
    print_error "Servicio 'tennis-management-backend' no configurado en render.yaml"
    exit 1
fi

print_success "Configuración de Render válida"

# 5. Hacer push a la rama main
print_status "Haciendo push a origin/main..."
git push origin main

if [ $? -eq 0 ]; then
    print_success "Push exitoso a origin/main"
else
    print_error "Error en el push"
    exit 1
fi

# 6. Mostrar información del despliegue
echo ""
echo "🎉 Despliegue iniciado exitosamente!"
echo ""
echo "📊 Información del despliegue:"
echo "   🌍 Ambiente: Production"
echo "   📦 Servicio: tennis-management-backend"
echo "   🔗 URL: https://tennis-management-backend.onrender.com"
echo "   ⏰ Iniciado: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Monitorea el progreso en: https://dashboard.render.com"
echo "   2. El despliegue puede tomar 2-5 minutos"
echo "   3. Verifica que el servicio esté 'Live'"
echo "   4. Prueba la URL del servicio"
echo ""
echo "🔍 Para verificar el estado:"
echo "   curl https://tennis-management-backend.onrender.com/health"
echo ""
print_success "¡Despliegue en progreso!"
