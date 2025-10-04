# 🔥 Configuración de Firebase Auth

## 📋 Pasos para configurar Firebase

### 1. Crear proyecto en Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en **"Crear un proyecto"**
3. **Nombre del proyecto:** `Tennis Management`
4. **Habilita Google Analytics** (opcional)
5. Haz clic en **"Crear proyecto"**

### 2. Habilitar Authentication
1. En el menú lateral, haz clic en **"Authentication"**
2. Haz clic en **"Comenzar"** (Get started)
3. Ve a la pestaña **"Sign-in method"**
4. **Habilita "Google"** como proveedor:
   - Haz clic en **"Google"**
   - **Habilita** el toggle
   - **Project support email:** tu email
   - Haz clic en **"Guardar"**

### 3. Obtener configuración del proyecto
1. Ve a **"Configuración del proyecto"** (ícono de engranaje)
2. Haz clic en **"Configuración del proyecto"**
3. En la pestaña **"General"**, busca **"Tus aplicaciones"**
4. **Haz clic en el ícono de web** `</>`
5. **Nombre de la app:** `Tennis Management Backend`
6. **Habilita Firebase Hosting** (opcional)
7. Haz clic en **"Registrar app"**
8. **Copia la configuración** que aparece

### 4. Generar clave de servicio
1. En Firebase Console, ve a **"Configuración del proyecto"**
2. Pestaña **"Cuentas de servicio"**
3. Haz clic en **"Generar nueva clave privada"**
4. **Descarga el archivo JSON**

### 5. Configurar variables de entorno
Actualiza tu archivo `.env` con los valores del archivo JSON descargado:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=tennis-management
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nTU_PRIVATE_KEY_AQUI\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tennis-management.iam.gserviceaccount.com
```

## 🚀 Endpoints disponibles

### POST `/api/auth/firebase/verify`
Verifica un token de Firebase y crea/actualiza el usuario en la base de datos.

**Request:**
```json
{
  "idToken": "firebase_id_token_aqui"
}
```

**Response:**
```json
{
  "accessToken": "jwt_access_token",
  "refreshToken": "jwt_refresh_token",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "User Name",
    "role": "student"
  }
}
```

### GET `/api/auth/firebase/me`
Obtiene información del usuario autenticado.

**Headers:**
```
Authorization: Bearer firebase_id_token
```

**Response:**
```json
{
  "id": "user_id",
  "email": "user@example.com",
  "name": "User Name",
  "role": "student"
}
```

## 📱 Integración con Flutter

### Dependencias en pubspec.yaml:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.1.6
  http: ^1.1.0
```

### Ejemplo de uso en Flutter:
```dart
// 1. Autenticar con Google
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

// 2. Obtener token y enviar al backend
String? idToken = await userCredential.user?.getIdToken();
final response = await http.post(
  Uri.parse('http://localhost:3000/api/auth/firebase/verify'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'idToken': idToken}),
);

// 3. Usar el JWT del backend para requests posteriores
Map<String, dynamic> authData = jsonDecode(response.body);
String backendToken = authData['accessToken'];
```

## 🔧 Notas importantes

- El backend genera sus propios JWT después de verificar el token de Firebase
- Los usuarios se crean automáticamente como "student" por defecto
- Se vincula la cuenta de Firebase con el usuario existente si ya existe el email
- El middleware `firebaseAuthMiddleware` verifica tokens de Firebase directamente
- Los endpoints existentes siguen funcionando con JWT tradicional
