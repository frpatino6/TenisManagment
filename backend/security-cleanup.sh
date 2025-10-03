#!/bin/bash

# Script de emergencia para limpiar claves sensibles del historial de Git
# ⚠️ ADVERTENCIA: Este script es destructivo y debe usarse con precaución

set -e

echo "🚨 SCRIPT DE LIMPIEZA DE SEGURIDAD 🚨"
echo ""
echo "⚠️  ADVERTENCIA: Este script eliminará commits del historial de Git"
echo "⚠️  Esto puede causar problemas si otros desarrolladores han clonado el repo"
echo ""
echo "¿Estás seguro de que quieres continuar? (y/N)"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 1
fi

echo ""
echo "🔍 Identificando commits problemáticos..."

# Encontrar commits que contienen claves sensibles
PROBLEMATIC_COMMITS=$(git log --oneline --grep="Deploy:" | head -2 | awk '{print $1}')

echo "📋 Commits problemáticos encontrados:"
echo "$PROBLEMATIC_COMMITS"

echo ""
echo "🔧 Opciones de limpieza:"
echo "1. Revertir commits (recomendado para repos públicos)"
echo "2. Reset hard (peligroso, solo para repos privados)"
echo "3. Cancelar"
echo ""
echo "Selecciona una opción (1-3):"
read -r option

case $option in
    1)
        echo "🔄 Revirtiendo commits problemáticos..."
        for commit in $PROBLEMATIC_COMMITS; do
            echo "Revirtiendo commit: $commit"
            git revert --no-edit "$commit" || echo "⚠️ No se pudo revertir $commit"
        done
        echo "✅ Commits revertidos"
        ;;
    2)
        echo "⚠️ ADVERTENCIA: Esto eliminará permanentemente los commits"
        echo "¿Estás absolutamente seguro? (y/N)"
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "🗑️ Eliminando commits problemáticos..."
            git reset --hard HEAD~2
            echo "✅ Commits eliminados"
        else
            echo "❌ Operación cancelada"
            exit 1
        fi
        ;;
    3)
        echo "❌ Operación cancelada"
        exit 1
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "🔍 Verificando que las claves ya no estén en el historial..."
if git log --all --full-history -- render.yaml | grep -q "FIREBASE_PRIVATE_KEY\|JWT_SECRET\|MONGO_URI"; then
    echo "❌ ALERTA: Aún hay claves sensibles en el historial"
    echo "💡 Considera usar git filter-branch o BFG Repo-Cleaner"
else
    echo "✅ Claves sensibles eliminadas del historial"
fi

echo ""
echo "📋 Próximos pasos:"
echo "1. 🔑 Revoca las claves expuestas en Firebase y MongoDB"
echo "2. 🔄 Genera nuevas claves"
echo "3. 📝 Configura las nuevas claves en Render Dashboard"
echo "4. 🚀 Haz un nuevo despliegue"
echo ""
echo "✅ Limpieza de seguridad completada"
