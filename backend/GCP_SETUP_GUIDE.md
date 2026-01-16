# ☁️ Guía de Configuración GCP (Free Tier)

Esta guía te llevará paso a paso para configurar tu máquina virtual gratuita en Google Cloud Platform y desplegar tu backend.

## 1. Crear la Máquina Virtual (VM)

1.  Ve a [Google Cloud Console](https://console.cloud.google.com/).
2.  **Selecciona tu proyecto existente** (el de Firebase, `tennis-management-fcd54`) o crea uno nuevo.
    *   *Tip:* Usar el mismo proyecto de Firebase es ideal para tener todo junto.
3.  Ve a **Compute Engine** > **Instancias de VM**.
    *   *Nota:* Si es la primera vez que entras aquí, verás un botón azul que dice **Enable**. Haz clic en él y espera unos minutos a que se habilite la API.
4.  Una vez habilitado, haz clic en **Crear instancia**.
5.  **Configuración Crucial para Free Tier**:
    *   **Nombre:** `tennis-backend`
    *   **Región:** `us-central1` (Iowa) o `us-west1` (Oregon) o `us-east1` (South Carolina). *Solo estas son gratis*.
    *   **Zona:** Cualquiera (ej: `us-central1-a`).
    *   **Tipo de máquina:** `e2-micro` (2 vCPU, 1 GB memoria). *Busca la etiqueta "Micro"*.
    *   **Disco de arranque:**
        *   Tipo: **Disco persistente estándar** (Standard Persistent Disk).
        *   Tamaño: **30 GB** (El máximo gratuito).
        *   Imagen: **Ubuntu 22.04 LTS** (x86/64, amd64).
    *   **Firewall:** Marca las casillas:
        *   ✅ Permitir tráfico HTTP
        *   ✅ Permitir tráfico HTTPS
6.  Haz clic en **Crear**.

---

## 2. Configurar IP Estática y Firewall

Para que tu backend siempre tenga la misma dirección y el puerto 3000 esté abierto.

1.  **Reservar IP Estática**:
    *   Ve a **Red de VPC** > **Direcciones IP**.
    *   Busca la IP externa de tu VM `tennis-backend`.
    *   Haz clic en los tres puntos al final de la línea > **Promover a dirección IP estática**.
    *   Dale un nombre y reserva.

2.  **Abrir Puerto 3000**:
    *   Ve a **Red de VPC** > **Firewall**.
    *   Haz clic en **Crear regla de firewall**.
    *   **Nombre:** `allow-backend-3000`.
    *   **Destinos:** `Todas las instancias de la red`.
    *   **Rangos de IP de origen:** `0.0.0.0/0` (Todo el mundo).
    *   **Protocolos y puertos:** Marca `TCP` y escribe `3000, 80, 443`.
    *   Haz clic en **Crear**.

---

## 3. Instalar Docker en la VM

1.  En la lista de VMs, haz clic en el botón **SSH** al lado de tu instancia. Se abrirá una terminal en tu navegador.
2.  Ejecuta estos comandos uno por uno para instalar Docker:

```bash
# Actualizar sistema
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg

# Agregar llave GPG de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Dar permisos a tu usuario (para no usar sudo con docker)
sudo usermod -aG docker $USER
```
3.  **Cierra la ventana SSH y vuelve a abrirla** para aplicar los permisos.

---

## 4. Desplegar el Backend

### A. Preparar la imagen (Automático con GitHub Actions)
1.  Ve a tu repositorio en GitHub > **Actions**.
2.  Selecciona el workflow **"Build & Push Backend Docker Image"**.
3.  Ejecútalo manualmente (`Run workflow`).
4.  Espera a que termine. Esto creará la imagen `ghcr.io/tu-usuario/tenismanagment/backend:latest`.

### B. Configurar en la VM
1.  Conéctate por **SSH** a la VM.
2.  Crea una carpeta para el proyecto:
    ```bash
    mkdir tennis-backend
    cd tennis-backend
    ```
3.  Crea el archivo `.env` (Copia el contenido de tu `.env` local, pero cambia `MONGO_URI` para que apunte a Atlas):
    ```bash
    nano .env
    # Pega tu contenido. Guarda con Ctrl+O, Enter. Sal con Ctrl+X.
    ```
    > ⚠️ **Importante**:
    > 1. Asegúrate de que `MONGO_URI` sea la URL de conexión a MongoDB Atlas.
    > 2. Agrega esta línea para permitir que tu Flutter Web (Localhost) se conecte:
    >    `CORS_ORIGINS=http://localhost:XYZ,https://tennis-management-fcd54.web.app` 
    >    *(Reemplaza XYZ con el puerto que use tu flutter run -d chrome, suelen ser variables)*
    > ⚠️ **Importante**: Asegúrate de que `MONGO_URI` sea la URL de conexión a MongoDB Atlas, no `localhost`.

4.  Copia el `docker-compose.yml` que creamos:
    ```bash
    nano docker-compose.yml
    # Pega el contenido con Caddy (ver abajo)
    ```

    **Contenido de docker-compose.yml:**
    ```yaml
    services:
      backend:
        container_name: tennis-backend
        image: ghcr.io/frpatino6/tenismanagment/backend:latest
        restart: always
        # Ports are handled by Caddy
        # ports:
        #   - "3000:3000" 
        env_file:
          - .env
        environment:
          - NODE_ENV=production
        logging:
          driver: "json-file"
          options:
            max-size: "10m"
            max-file: "3"

      caddy:
        image: caddy:2-alpine
        restart: always
        ports:
          - "80:80"
          - "443:443"
        command: caddy reverse-proxy --from https://34.57.81.166.nip.io --to http://backend:3000
        depends_on:
          - backend
    ```

### C. Iniciar Servicio
```bash
# Iniciar sesión en el registro de GitHub (necesitarás un Personal Access Token)
# O haz tu paquete público en GitHub Packages settings para no necesitar login.
docker login ghcr.io -u TU_USUARIO_GITHUB -p TU_TOKEN_GITHUB

# Descargar y arrancar
docker compose pull
docker compose up -d
```

¡Listo! Tu backend debería estar corriendo en `https://34.57.81.166.nip.io` (Seguro con HTTPS).

---

## 5. 🔄 Rutina de Despliegue (Actualizar versión)

Cada vez que quieras subir cambios nuevos a producción:

1.  **En GitHub:**
    *   Haz merge de tus cambios a `main`.
    *   Ve a **Actions** -> **Build & Push Backend** -> **Run workflow**.

2.  **En la VM (SSH):**
    ```bash
    # 1. Descargar la nueva versión de la imagen (FUNDAMENTAL)
    sudo docker compose pull

    # 2. Recrear el contenedor con esa nueva imagen
    sudo docker compose up -d --remove-orphans
    ```

---

## 6. ⚙️ Actualizar Variables de Entorno (.env)

Si necesitas cambiar la base de datos, claves o configuración CORS:

1.  **Edita el archivo (Recomendado usar nano):**
    ```bash
    nano .env
    # Edita, Ctrl+O (Guardar), Ctrl+X (Salir)
    ```

2.  **⚠️ IMPORTANTE: Aplicar cambios**
    No uses `restart`. Debes recrear el contenedor para que lea las variables nuevas:
    ```bash
    sudo docker compose up -d --force-recreate backend
    ```
