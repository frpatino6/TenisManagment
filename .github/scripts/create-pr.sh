#!/bin/bash

# Script para crear PR automáticamente
# Uso: ./scripts/create-pr.sh "Título del PR" "Descripción del PR"

set -e

BRANCH=$(git branch --show-current)
BASE_BRANCH="main"
TITLE="${1:-$BRANCH}"
DESCRIPTION="${2:-}"

if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Cambios desde la rama $BRANCH"
fi

echo "🔍 Verificando estado del repositorio..."

# Verificar que hay cambios para hacer push
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Tienes cambios sin commit. ¿Quieres continuar? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "❌ Cancelado"
        exit 1
    fi
fi

# Verificar que la rama está adelantada
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [ -z "$REMOTE" ]; then
    echo "📤 La rama no tiene upstream. Haciendo push..."
    git push -u origin "$BRANCH"
elif [ "$LOCAL" != "$REMOTE" ]; then
    echo "📤 Haciendo push de cambios..."
    git push
else
    echo "✅ La rama ya está actualizada en remoto"
fi

echo ""
echo "🚀 Creando Pull Request..."
echo "   Título: $TITLE"
echo "   Desde: $BRANCH"
echo "   Hacia: $BASE_BRANCH"
echo ""

# Usar GitHub CLI si está disponible
if command -v gh &> /dev/null; then
    gh pr create --title "$TITLE" --body "$DESCRIPTION" --base "$BASE_BRANCH" --head "$BRANCH"
    echo "✅ PR creado exitosamente"
else
    echo "ℹ️  GitHub CLI no está instalado. Puedes crear el PR manualmente en:"
    echo "   https://github.com/frpatino6/TenisManagment/compare/$BASE_BRANCH...$BRANCH"
    echo ""
    echo "O instala GitHub CLI:"
    echo "   sudo apt install gh  # Linux"
    echo "   brew install gh      # macOS"
fi

