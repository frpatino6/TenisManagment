# 🔗 Linear Integration Scripts

Scripts para integración y gestión con Linear (project management).

## 📋 Scripts Disponibles

### **Verificación y Diagnóstico**
- `check-issue-identifiers.js` - Verifica los identifiers reales de los issues
- `check-linear-features.js` - Verifica funcionalidades disponibles en Linear
- `verify-linear-setup.js` - Verifica la configuración de Linear
- `simple-linear-check.js` - Verificación simple de conexión

### **Asociación de Issues**
- `associate-issues-correct.js` - Asocia issues a projects usando identifiers correctos
- `associate-issues-direct.js` - Asociación directa de issues a projects
- `associate-issues-to-projects.js` - Asocia issues a projects con mapeo detallado
- `simple-associate.js` - Asociación simple usando fetch nativo

### **Configuración de Projects**
- `setup-sprint-projects.js` - Configura projects para organizar sprints
- `setup-sprint-milestones.js` - Configura milestones en Linear

### **Corrección de Estados**
- `fix-project-associations.js` - Corrige asociaciones de issues a projects
- `fix-sprint-1-status.js` - Corrige el estado de los issues del Sprint 1

### **Utilidades**
- `simple-associate.js` - Script simple para asociación básica

## 🚀 Uso

```bash
# Verificar configuración
node scripts/linear/verify-linear-setup.js

# Asociar issues a projects
node scripts/linear/associate-issues-correct.js

# Verificar funcionalidades
node scripts/linear/check-linear-features.js
```

## 📊 Funcionalidades

- ✅ Verificación de conexión a Linear
- ✅ Asociación de issues a projects/sprints
- ✅ Configuración de milestones y fechas
- ✅ Corrección de estados de issues
- ✅ Diagnóstico de problemas de integración
