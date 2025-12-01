# 🔥 Instrucciones para Actualizar el Secret de Firebase en GitHub

## ⚡ Pasos Rápidos

### 1. Ejecutar el script preparatorio (Opcional)

```bash
cd /home/fernando/Documentos/Development/TenisManagment
.github/scripts/prepare-firebase-secret.sh
```

Esto creará un archivo `.github/FIREBASE_SECRET_CONTENT.txt` con el contenido listo para copiar.

### 2. Obtener el contenido del JSON

Abre el archivo:
```
config/tennis-management-fcd54-firebase-adminsdk-fbsvc-d634c02236.json
```

O el archivo preparado:
```
.github/FIREBASE_SECRET_CONTENT.txt
```

### 3. Copiar el contenido COMPLETO

1. Abre el archivo JSON
2. Selecciona TODO el contenido (Cmd/Ctrl + A)
3. Copia (Cmd/Ctrl + C)
4. **Asegúrate de que el JSON esté completo** desde `{` hasta `}`

### 4. Actualizar el Secret en GitHub

1. Ve a: https://github.com/frpatino6/TenisManagment/settings/secrets/actions
2. Busca el secret: **`FIREBASE_SERVICE_ACCOUNT`**
3. Haz clic en **"Update"** (o crea uno nuevo si no existe)
4. En el campo **Value**, pega el JSON completo que copiaste
5. Haz clic en **"Update secret"**

### 5. Verificar

El JSON debe tener aproximadamente **2409 caracteres** y contener estos campos:
- ✅ `type`: "service_account"
- ✅ `project_id`: "tennis-management-fcd54"
- ✅ `private_key`: "-----BEGIN PRIVATE KEY-----..."
- ✅ `client_email`: "firebase-adminsdk-fbsvc@tennis-management-fcd54.iam.gserviceaccount.com"

## ✅ Verificación Final

Una vez actualizado el secret:

1. El próximo push a `main` activará el workflow
2. El deploy a Firebase debería funcionar correctamente
3. Si hay errores, revisa los logs en **Actions** → **Deploy Frontend to Firebase**

## 🔍 Si el Error Persiste

Si después de actualizar el secret sigue habiendo errores:

1. **Regenera la clave de servicio en Firebase**:
   - Ve a Firebase Console → Configuración → Cuentas de servicio
   - Genera una nueva clave privada
   - Descarga el JSON nuevo

2. **Actualiza el archivo local**:
   - Reemplaza `config/tennis-management-fcd54-firebase-adminsdk-fbsvc-d634c02236.json`
   - Ejecuta el script de nuevo

3. **Actualiza el secret en GitHub** con el nuevo JSON

## 📝 Nota de Seguridad

⚠️ **NUNCA** commits el archivo JSON de Firebase al repositorio público. El archivo en `config/` está ahí por comodidad, pero:
- ✅ Está en `.gitignore` (verificar)
- ✅ Solo se usa para generar el secret
- ✅ El secret en GitHub está encriptado

