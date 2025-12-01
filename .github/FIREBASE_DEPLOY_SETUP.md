# 🔥 Configuración de Deploy a Firebase Hosting en GitHub Actions

## ⚠️ Error Actual

El deploy a Firebase está fallando con el siguiente error:
```
SyntaxError: Unterminated string in JSON at position 2295
Error: Failed to authenticate, have you run firebase login?
```

## 🔍 Diagnóstico

El problema está en el secret `FIREBASE_SERVICE_ACCOUNT` en GitHub. El JSON está mal formado o incompleto.

## ✅ Solución: Configurar el Secret Correctamente

### 1. Generar Clave de Servicio en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto: `tennis-management-fcd54`
3. Ve a **⚙️ Configuración del proyecto** → **Cuentas de servicio**
4. Haz clic en **"Generar nueva clave privada"**
5. Se descargará un archivo JSON (ej: `tennis-management-fcd54-firebase-adminsdk-xxxxx.json`)

### 2. Configurar el Secret en GitHub

1. Ve a tu repositorio en GitHub: `https://github.com/frpatino6/TenisManagment`
2. Ve a **Settings** → **Secrets and variables** → **Actions**
3. Busca el secret `FIREBASE_SERVICE_ACCOUNT` (o créalo si no existe)
4. **IMPORTANTE**: Copia el contenido **COMPLETO** del archivo JSON descargado
5. Pega el JSON completo en el valor del secret

### 3. Formato Correcto del Secret

El secret debe contener el JSON completo, por ejemplo:

```json
{
  "type": "service_account",
  "project_id": "tennis-management-fcd54",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@tennis-management-fcd54.iam.gserviceaccount.com",
  "client_id": "xxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40tennis-management-fcd54.iam.gserviceaccount.com"
}
```

### 4. Verificar el JSON

Antes de guardar, verifica que:
- ✅ El JSON esté completo (no cortado)
- ✅ No haya saltos de línea adicionales
- ✅ Las comillas estén correctamente escapadas
- ✅ El `private_key` tenga los `\n` correctos

### 5. Alternativa: Usar Base64

Si el JSON tiene problemas con caracteres especiales, puedes codificarlo en Base64:

```bash
# En local, codifica el JSON
cat firebase-service-account.json | base64 -w 0

# Luego en el workflow, decodifícalo:
- name: Decode Firebase credentials
  run: |
    echo '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}' | base64 -d > /tmp/firebase-key.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/firebase-key.json
```

## 🔧 Verificar Configuración

### Verificar firebase.json

Asegúrate de que `mobile/firebase.json` existe y está configurado:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Verificar Permisos de la Cuenta de Servicio

1. En Firebase Console, ve a **IAM & Admin** → **Service Accounts**
2. Verifica que la cuenta de servicio tenga permisos de:
   - Firebase Hosting Admin
   - Firebase Admin

## 🚀 Probar el Deploy

Una vez configurado el secret correctamente:

1. Haz push a la rama `main`
2. El workflow se ejecutará automáticamente
3. Verifica los logs en **Actions** → **Deploy Frontend to Firebase**

## 📝 Notas Importantes

- ⚠️ El deploy **solo se ejecuta** en pushes a `main`, no en PRs
- ⚠️ El secret `FIREBASE_SERVICE_ACCOUNT` debe ser el JSON **completo** y **válido**
- ⚠️ No compartas el archivo JSON públicamente
- ✅ El workflow verifica que `build/web` existe antes de deployar

## 🔄 Si el Error Persiste

1. Regenera la clave de servicio en Firebase
2. Actualiza el secret en GitHub con el nuevo JSON
3. Verifica que el proyecto ID sea correcto: `tennis-management-fcd54`
4. Revisa los logs detallados con `DEBUG: '*'` habilitado

