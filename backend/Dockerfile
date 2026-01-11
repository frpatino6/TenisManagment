# Stage 1: Builder
# Usamos una imagen ligera de Node.js para construir
FROM node:20-alpine AS builder

# Establecemos el directorio de trabajo
WORKDIR /app

# Copiamos los archivos de definición de paquetes
COPY package*.json ./

# Instalamos TODAS las dependencias (incluyendo devDependencies para compilar TS)
RUN npm ci --ignore-scripts

# Copiamos el código fuente
COPY . .

# Compilamos el proyecto TypeScript
RUN npm run build

# Stage 2: Runner
# Empezamos desde cero con una imagen limpia para producción
FROM node:20-alpine AS runner

WORKDIR /app

# Copiamos package.json para instalar solo dependencias de producción
COPY package*.json ./

# Instalamos SOLO dependencias de producción (ahorra espacio)
RUN npm ci --only=production --ignore-scripts

# Copiamos los archivos compilados del stage anterior (builder)
COPY --from=builder /app/dist ./dist

# Copiamos carpetas necesarias que no se compilan (si las hay, como configuración estática)
# COPY --from=builder /app/config ./config 
# (Nota: Asegúrate de que tu código lea configs desde donde debe. 
# Si usas 'config' folder en runtime, descomenta la línea de arriba)

# Exponemos el puerto de la aplicación
EXPOSE 3000

# Usuario no root por seguridad
USER node

# Comando de inicio
CMD ["node", "dist/presentation/server.js"]
