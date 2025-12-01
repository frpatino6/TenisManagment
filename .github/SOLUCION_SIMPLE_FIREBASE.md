# 🔥 Solución Simple: Error de Deploy a Firebase

## El Problema

El deploy está fallando porque está intentando crear un "preview" automático para tu PR, pero el secret de Firebase en GitHub tiene el JSON incompleto.

## Solución en 3 Pasos

### 1. Abre este archivo y copia TODO el contenido:
```
config/tennis-management-fcd54-firebase-adminsdk-fbsvc-d634c02236.json
```

### 2. Ve a GitHub y actualiza el secret:
1. Ve a: https://github.com/frpatino6/TenisManagment/settings/secrets/actions
2. Busca: **FIREBASE_SERVICE_ACCOUNT**
3. Haz clic en "Update"
4. Pega TODO el JSON que copiaste
5. Guarda

### 3. Listo

El deploy funcionará automáticamente cuando hagas push a `main`.

## Nota Importante

El error que viste es porque GitHub está intentando crear un "preview" del PR. Esto es normal, pero el secret necesita estar bien configurado. Una vez actualices el secret, funcionará cuando hagas merge a `main`.

