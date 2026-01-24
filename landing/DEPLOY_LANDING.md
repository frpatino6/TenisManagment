# Despliegue de Landing (Firebase Hosting)

Este proyecto usa **Firebase Hosting multi-site**. La landing se publica en el sitio:

- **Site ID:** `courthub-landing`
- **Project ID:** `tennis-management-fcd54`
- **URL:** https://courthub-landing.web.app

## 1) Build

```bash
cd /home/fernando/Documentos/Development/TenisManagment/landing
npm ci
npm run build
```

El build genera `dist/tenis-management-landing/browser`.  
El script `postbuild` copia `index.csr.html` → `index.html` para hosting estático.

## 2) Deploy (con token)

```bash
npx firebase-tools deploy --only hosting:courthub-landing \
  --project tennis-management-fcd54 \
  --token "TU_TOKEN"
```

## 3) Deploy (login interactivo)

Si tienes sesión abierta en Firebase CLI:

```bash
npx firebase-tools deploy --only hosting:courthub-landing \
  --project tennis-management-fcd54
```

## 4) Dominio personalizado

El dominio `courthub.co` debe vincularse al site `courthub-landing` en Firebase Hosting.
Sigue el wizard de Firebase y agrega en DNS:

- **A (@):** `199.36.158.100`
- **TXT (@):** `hosting-site=courthub-landing`

---

### Notas
- El frontend principal usa el **hosting principal** del proyecto.  
  La landing **no** debe desplegarse en ese sitio para no pisarlo.
- Archivo de configuración: `landing/firebase.json`
