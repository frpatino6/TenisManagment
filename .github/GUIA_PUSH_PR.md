# 🚀 Guía Rápida: Push y Crear PR

## ¿Tengo que hacer esto manualmente cada vez?

**Respuesta corta:** No, puedes automatizarlo. Ya configuré algunas cosas para simplificar el proceso.

## ✅ Lo que ya está configurado

1. **Credenciales guardadas** - Git guardará tus credenciales (solo te pedirá una vez más)
2. **Scripts de ayuda** - Creé scripts para automatizar el proceso

## 🎯 Opciones Disponibles

### Opción 1: Todo Automático (Recomendado)

Usa el script rápido que hace commit, push y te ayuda a crear el PR:

```bash
cd /home/fernando/Documentos/Development/TenisManagment
./.github/scripts/quick-push.sh "mensaje del commit" "Título del PR"
```

**Ejemplo:**
```bash
./.github/scripts/quick-push.sh "fix: Corregir error en login" "Corregir error de autenticación"
```

### Opción 2: Solo Crear PR

Si ya hiciste commit y push manualmente:

```bash
./.github/scripts/create-pr.sh "Título del PR" "Descripción del PR"
```

### Opción 3: Manual (como ahora)

Si prefieres control total:

```bash
# 1. Commit
git add .
git commit -m "mensaje"

# 2. Push
git push origin tu-rama

# 3. Crear PR (usando GitHub CLI o manualmente en la web)
```

## 🔧 Usar GitHub CLI (Más Fácil)

Si instalas GitHub CLI, puedes crear PRs desde la terminal:

```bash
# Instalar (solo una vez)
sudo apt install gh  # Linux
# o
brew install gh      # macOS

# Autenticar (solo una vez)
gh auth login

# Luego crear PR es súper fácil:
gh pr create --title "Título" --body "Descripción"
```

## 📋 Flujo Recomendado

### Para cambios pequeños:
1. Haz tus cambios
2. Ejecuta: `./.github/scripts/quick-push.sh "descripción" "título PR"`
3. Listo ✅

### Para cambios grandes:
1. Haz commit de tus cambios
2. Haz push manualmente
3. Usa: `./.github/scripts/create-pr.sh "título" "descripción"`

## ⚠️ Notas Importantes

- **No subas secretos**: Siempre revisa que no estés subiendo archivos con credenciales
- **Revisa antes de push**: Usa `git status` para ver qué estás subiendo
- **Mensajes claros**: Usa mensajes de commit descriptivos

## 🆘 Si algo falla

Si el push falla por autenticación:
1. Verifica que el credential helper esté configurado: `git config --global credential.helper`
2. Si no está, ejecuta: `git config --global credential.helper store`
3. Intenta push de nuevo (te pedirá credenciales una vez más)

