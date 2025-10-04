const { loadLinearConfig, getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function completeTEN73() {
  try {
    // Load Linear configuration
    loadLinearConfig();
    const config = getLinearConfig();
    
    console.log('🔍 Buscando la historia TEN-73...');
    
    // Fetch all issues for the team
    const issuesQuery = `
      query GetIssues($teamId: String!) {
        team(id: $teamId) {
          issues {
            nodes {
              id
              identifier
              title
              description
              state {
                name
                type
              }
            }
          }
        }
      }
    `;
    
    const issuesResponse = await makeLinearRequest(issuesQuery, { teamId: config.teamId });
    const issues = issuesResponse.data.team.issues.nodes;
    
    // Find TEN-73
    const ten73 = issues.find(issue => issue.identifier === 'TEN-73');
    
    if (!ten73) {
      console.log('❌ No se encontró la historia TEN-73');
      return;
    }
    
    console.log(`✅ Encontrada historia: ${ten73.identifier} - ${ten73.title}`);
    
    // Fetch all states to find "Done" state
    const statesQuery = `
      query GetStates($teamId: String!) {
        team(id: $teamId) {
          states {
            nodes {
              id
              name
              type
            }
          }
        }
      }
    `;
    
    const statesResponse = await makeLinearRequest(statesQuery, { teamId: config.teamId });
    const states = statesResponse.data.team.states.nodes;
    const doneState = states.find(state => state.name === 'Done');
    
    if (!doneState) {
      console.log('❌ No se encontró el estado "Done"');
      return;
    }
    
    console.log(`✅ Encontrado estado: ${doneState.name}`);
    
    // Update TEN-73 to Done status
    const updateMutation = `
      mutation UpdateIssue($issueId: String!, $stateId: String!, $description: String!) {
        issueUpdate(id: $issueId, input: { stateId: $stateId, description: $description }) {
          success
          issue {
            id
            identifier
            title
            state {
              name
            }
          }
        }
      }
    `;
    
    const description = `## 🎯 Historia Completada: Testing de Integración - Professor Flow

### ✅ Implementación Completada

**Tests de Integración Implementados:**
- ✅ **20 tests de integración** completados y funcionando
- ✅ **Cobertura completa** del flujo de profesores desde registro hasta ganancias
- ✅ **Validación de integridad** de datos entre entidades MongoDB
- ✅ **Tests cubren**: Registro, gestión de horarios, interacciones con estudiantes, servicios, ingresos, flujos completos

### 🧪 Categorías de Tests Implementadas

1. **Professor Registration and Profile Management** (3 tests)
   - Creación de perfil de profesor desde AuthUser
   - Actualización de información del perfil
   - Creación de perfil a través del dashboard

2. **Schedule Management Integration** (3 tests)
   - Creación y gestión de disponibilidad de horarios
   - Manejo de múltiples horarios para el mismo profesor
   - Eliminación de horarios

3. **Student-Professor Interaction Integration** (3 tests)
   - Manejo de reservas de estudiantes en horarios de profesores
   - Seguimiento de ingresos del profesor por pagos de estudiantes
   - Flujo de trabajo de finalización de clases

4. **Service Management Integration** (3 tests)
   - Creación y gestión de servicios
   - Manejo de múltiples servicios para profesor
   - Actualización de precios de servicios

5. **Income and Analytics Integration** (3 tests)
   - Seguimiento de ingresos mensuales del profesor
   - Seguimiento de ingresos semanales del profesor
   - Seguimiento de ganancias totales y clases completadas

6. **Complete Professor Workflow Integration** (2 tests)
   - Flujo completo: configuración -> horario -> enseñar -> ganar
   - Manejo de profesor gestionando múltiples estudiantes y horarios

7. **Error Handling and Edge Cases** (3 tests)
   - Manejo de eliminación en cascada de profesor
   - Operaciones de horarios inválidas
   - Integridad de datos con operaciones concurrentes

### 📊 Resultados de Testing

- **Total de Tests**: 20/20 ✅
- **Tiempo de Ejecución**: ~6.8 segundos
- **Cobertura**: Flujo completo de profesores
- **Archivo Principal**: \`src/__tests__/integration/professor-flow.test.ts\`

### 🔧 Tecnologías Utilizadas

- **Jest** para framework de testing
- **MongoDB Memory Server** para base de datos en memoria
- **Mongoose** para modelos de datos
- **TypeScript** para tipado estático
- **Clean Architecture** con use cases y repositorios

### 🎯 Flujos Cubiertos

1. **Flujo de Registro de Profesor**: AuthUser → Creación de perfil → Actualización de información
2. **Flujo de Gestión de Horarios**: Creación → Disponibilidad → Eliminación → Múltiples horarios
3. **Flujo de Interacción con Estudiantes**: Reservas → Pagos → Finalización de clases
4. **Flujo de Gestión de Servicios**: Creación → Actualización → Precios
5. **Flujo de Seguimiento de Ingresos**: Mensual → Semanal → Total → Clases completadas
6. **Flujo Completo de Trabajo**: Setup → Horario → Enseñar → Ganar

### 📝 Notas Técnicas

- **Validación de Modelos**: Se corrigieron errores de validación de campos requeridos (phone, professorId, category)
- **Integridad de Datos**: Verificación completa de relaciones entre entidades
- **Operaciones Concurrentes**: Manejo de operaciones simultáneas con integridad de datos
- **Cascada de Eliminación**: Manejo de eliminación de profesores y datos relacionados

### 🚀 Próximos Pasos

La historia está lista para integración con el frontend y testing E2E completo.

---

**Fecha de Completado**: ${new Date().toLocaleDateString('es-ES')}
**Desarrollador**: AI Assistant
**Estado**: ✅ COMPLETADO`;

    const updateResponse = await makeLinearRequest(updateMutation, {
      issueId: ten73.id,
      stateId: doneState.id,
      description: description
    });
    
    if (updateResponse.data.issueUpdate.success) {
      const updatedIssue = updateResponse.data.issueUpdate.issue;
      console.log(`✅ TEN-73 actualizada exitosamente a estado: ${updatedIssue.state.name}`);
      console.log(`📋 Historia: ${updatedIssue.identifier} - ${updatedIssue.title}`);
    } else {
      console.log('❌ Error al actualizar TEN-73');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

completeTEN73();
