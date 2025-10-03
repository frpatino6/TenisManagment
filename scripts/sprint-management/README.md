# 🏃 Sprint Management Scripts

Scripts específicos para la gestión de sprints y seguimiento de progreso.

## 📋 Scripts Disponibles

### **Gestión de Sprints**
- `start-sprint-1.js` - Inicia el Sprint 1 - Multi-Tenancy Foundation
- `remove-duplicates-sprint1.js` - Elimina issues duplicados del Sprint 1
- `update-sprint-progress.js` - Actualiza y sigue el progreso del sprint

## 🚀 Uso

### **Iniciar Sprint 1**
```bash
node scripts/sprint-management/start-sprint-1.js
```

### **Eliminar Duplicados**
```bash
node scripts/sprint-management/remove-duplicates-sprint1.js
```

### **Actualizar Progreso**
```bash
# Ver progreso actual
node scripts/sprint-management/update-sprint-progress.js

# Mover issue a "Done"
node scripts/sprint-management/update-sprint-progress.js done TEN-6

# Agregar comentario de progreso
node scripts/sprint-management/update-sprint-progress.js comment TEN-6 "Progreso actualizado"
```

## 📊 Funcionalidades

### **start-sprint-1.js**
- ✅ Mueve issues del Sprint 1 a "In Progress"
- ✅ Configura fechas de inicio y fin del sprint
- ✅ Actualiza el project con fechas del sprint
- ✅ Muestra resumen del sprint iniciado

### **remove-duplicates-sprint1.js**
- ✅ Identifica y elimina issues duplicados
- ✅ Mantiene solo los issues únicos
- ✅ Optimiza story points del sprint
- ✅ Muestra resumen de optimización

### **update-sprint-progress.js**
- ✅ Muestra progreso actual del sprint
- ✅ Calcula porcentaje de completado
- ✅ Genera burndown chart visual
- ✅ Permite mover issues a "Done"
- ✅ Permite agregar comentarios de progreso

## 📈 Métricas Disponibles

- **Issues completados**: X/Y
- **Story points completados**: X/Y
- **Progreso porcentual**: X%
- **Burndown chart**: Visual
- **Issues en progreso**: Lista
- **Issues pendientes**: Lista
