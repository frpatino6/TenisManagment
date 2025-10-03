#!/bin/bash

echo "🔍 Verificando estado del despliegue..."

# Esperar un momento
sleep 10

echo "🌐 Verificando endpoint principal..."
curl -s -w "HTTP Status: %{http_code}\n" https://tennis-management-backend.onrender.com/ || echo "❌ Servicio no disponible"

echo ""
echo "🏥 Verificando endpoint de health..."
curl -s -w "HTTP Status: %{http_code}\n" https://tennis-management-backend.onrender.com/health || echo "❌ Health check no disponible"

echo ""
echo "📊 Si el servicio devuelve 200, el despliegue fue exitoso."
echo "📊 Si devuelve 404 o 500, revisa los logs en Render Dashboard."
