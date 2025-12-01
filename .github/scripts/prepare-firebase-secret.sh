#!/bin/bash

# Script para preparar el contenido del secret FIREBASE_SERVICE_ACCOUNT
# para GitHub Actions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIREBASE_JSON="$REPO_ROOT/config/tennis-management-fcd54-firebase-adminsdk-fbsvc-d634c02236.json"
OUTPUT_FILE="$REPO_ROOT/.github/FIREBASE_SECRET_CONTENT.txt"

echo "🔥 Preparando contenido del secret FIREBASE_SERVICE_ACCOUNT..."
echo ""

# Verificar que el archivo existe
if [ ! -f "$FIREBASE_JSON" ]; then
    echo "❌ Error: No se encontró el archivo JSON de Firebase"
    echo "   Buscado en: $FIREBASE_JSON"
    exit 1
fi

# Validar JSON
echo "✅ Validando JSON..."
if ! python3 -m json.tool "$FIREBASE_JSON" > /dev/null 2>&1; then
    echo "❌ Error: El archivo JSON no es válido"
    exit 1
fi

# Leer el contenido completo
JSON_CONTENT=$(cat "$FIREBASE_JSON")

# Verificar que el JSON tiene todos los campos requeridos
REQUIRED_FIELDS=("type" "project_id" "private_key" "client_email")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$JSON_CONTENT" | grep -q "\"$field\""; then
        echo "❌ Error: Falta el campo requerido: $field"
        exit 1
    fi
done

# Contar caracteres
CHAR_COUNT=$(echo -n "$JSON_CONTENT" | wc -c)
echo "✅ JSON válido con $CHAR_COUNT caracteres"
echo ""

# Crear archivo con el contenido listo para copiar
echo "$JSON_CONTENT" > "$OUTPUT_FILE"

echo "✅ Contenido preparado en: $OUTPUT_FILE"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Abre el archivo: $OUTPUT_FILE"
echo "   2. Copia TODO el contenido (Cmd/Ctrl + A, Cmd/Ctrl + C)"
echo "   3. Ve a GitHub: https://github.com/frpatino6/TenisManagment/settings/secrets/actions"
echo "   4. Busca o crea el secret: FIREBASE_SERVICE_ACCOUNT"
echo "   5. Pega el contenido completo en el valor del secret"
echo "   6. Haz clic en 'Update secret'"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Asegúrate de copiar TODO el JSON (desde { hasta })"
echo "   - No debe haber saltos de línea adicionales al inicio o final"
echo "   - El JSON debe estar en una sola línea o con formato correcto"
echo ""

