# CI/CD Workflows Disabled

Los workflows de CI/CD han sido temporalmente deshabilitados debido a problemas de despliegue.

## Estado Actual:
- ❌ `ci-cd.yml` - Deshabilitado (solo triggers manuales)
- ❌ `deploy-backend.yml` - Deshabilitado (solo triggers manuales)  
- ❌ `deploy-frontend.yml` - Deshabilitado (solo triggers manuales)

## Para Reactivar:
1. Descomenta las secciones `on:` en cada workflow
2. Comenta la sección `workflow_dispatch`
3. Haz commit y push

## Despliegue Manual:
- **Backend**: Se puede desplegar manualmente en Render
- **Frontend**: Se puede desplegar manualmente con `firebase deploy`

## Fecha de Deshabilitación:
$(date)
