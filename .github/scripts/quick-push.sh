#!/bin/bash

# Script rápido para commit, push y crear PR
# Uso: ./scripts/quick-push.sh "mensaje del commit" "Título del PR"

set -e

COMMIT_MSG="${1:-Update}"
PR_TITLE="${2:-$COMMIT_MSG}"
BRANCH=$(git branch --show-current)

echo "🚀 Proceso rápido de push y PR"
echo "================================"
echo "Rama: $BRANCH"
echo "Commit: $COMMIT_MSG"
echo ""

# Verificar cambios
if [ -z "$(git status --porcelain)" ]; then
    echo "⚠️  No hay cambios para commitear"
    exit 1
fi

# Agregar todos los cambios
echo "📝 Agregando cambios..."
git add .

# Commit
echo "💾 Creando commit..."
git commit -m "$COMMIT_MSG"

# Push
echo "📤 Haciendo push..."
git push origin "$BRANCH" || {
    echo "⚠️  Push falló. ¿Quieres intentar de nuevo? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
        git push origin "$BRANCH"
    else
        exit 1
    fi
}

echo ""
echo "✅ Push completado exitosamente"
echo ""
echo "Para crear el PR, ejecuta:"
echo "   ./.github/scripts/create-pr.sh \"$PR_TITLE\""

