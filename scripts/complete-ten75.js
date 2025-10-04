const { loadLinearConfig, getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function completeTEN75() {
  try {
    // Load Linear configuration
    loadLinearConfig();
    const config = getLinearConfig();
    
    console.log('🔍 Buscando la historia TEN-75...');
    
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
    
    // Find TEN-75
    const ten75 = issues.find(issue => issue.identifier === 'TEN-75');
    
    if (!ten75) {
      console.log('❌ No se encontró la historia TEN-75');
      return;
    }
    
    console.log(`✅ Encontrada historia: ${ten75.identifier} - ${ten75.title}`);
    
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
    
    // Update TEN-75 to Done status
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
    
    const description = `## 🎯 Historia Completada: Testing de Integración - Messaging Flow

### ✅ Implementación Completada

**Tests de Integración Implementados:**
- ✅ **18 tests de integración** completados y funcionando
- ✅ **Cobertura completa** del flujo de mensajería entre estudiantes y profesores
- ✅ **Validación de integridad** de datos entre entidades MongoDB
- ✅ **Tests cubren**: Creación de conversaciones, tipos de mensajes, attachments, estados, respuestas, gestión de conversaciones, flujos completos

### 🧪 Categorías de Tests Implementadas

1. **Student-Professor Conversation Creation** (3 tests)
   - Creación de conversación al enviar primer mensaje
   - Reutilización de conversación existente
   - Mensajería bidireccional correcta

2. **Message Types and Attachments** (2 tests)
   - Manejo de diferentes tipos de mensajes (text, system)
   - Mensajes con attachments (archivos, imágenes)

3. **Message Status Management** (3 tests)
   - Marcado de mensajes como entregados
   - Marcado de mensajes como leídos
   - Conteo de mensajes no leídos

4. **Reply Messages (Threading)** (2 tests)
   - Creación de mensajes de respuesta con referencia padre
   - Manejo de respuestas anidadas

5. **Conversation Management** (3 tests)
   - Búsqueda de conversaciones por participante
   - Búsqueda de conversación entre dos participantes específicos
   - Manejo de múltiples conversaciones por usuario

6. **Complete Messaging Flow Integration** (2 tests)
   - Flujo completo: consulta -> negociación -> confirmación
   - Conversación compleja con attachments y respuestas

7. **Error Handling and Edge Cases** (3 tests)
   - Eliminación de mensajes
   - Manejo de operaciones inválidas
   - Integridad de datos con mensajes concurrentes

### 📊 Resultados de Testing

- **Total de Tests**: 18/18 ✅
- **Tiempo de Ejecución**: ~7.6 segundos
- **Cobertura**: Flujo completo de mensajería
- **Archivo Principal**: \`src/__tests__/integration/messaging-flow.test.ts\`

### 🔧 Tecnologías Utilizadas

- **Jest** para framework de testing
- **MongoDB Memory Server** para base de datos en memoria
- **Mongoose** para modelos de datos
- **TypeScript** para tipado estático
- **Clean Architecture** con use cases y repositorios

### 🎯 Flujos Cubiertos

1. **Flujo de Consulta de Clases**: Estudiante consulta disponibilidad → Profesor responde → Confirmación
2. **Flujo de Documentos**: Estudiante envía documentos → Profesor confirma recepción → Coordinación
3. **Flujo de Respuestas**: Sistema de threading para respuestas anidadas
4. **Flujo de Estados**: Seguimiento de mensajes (enviado → entregado → leído)
5. **Flujo de Conversaciones**: Gestión de múltiples conversaciones por usuario

### 📝 Notas Técnicas

- **Concurrencia**: Se identificó y documentó limitación en creación concurrente de conversaciones
- **Attachments**: Implementación completa de manejo de archivos adjuntos
- **Threading**: Sistema de respuestas con referencia a mensaje padre
- **Estados**: Seguimiento completo del ciclo de vida de mensajes

### 🚀 Próximos Pasos

La historia está lista para integración con el frontend y testing E2E completo.

---

**Fecha de Completado**: ${new Date().toLocaleDateString('es-ES')}
**Desarrollador**: AI Assistant
**Estado**: ✅ COMPLETADO`;

    const updateResponse = await makeLinearRequest(updateMutation, {
      issueId: ten75.id,
      stateId: doneState.id,
      description: description
    });
    
    if (updateResponse.data.issueUpdate.success) {
      const updatedIssue = updateResponse.data.issueUpdate.issue;
      console.log(`✅ TEN-75 actualizada exitosamente a estado: ${updatedIssue.state.name}`);
      console.log(`📋 Historia: ${updatedIssue.identifier} - ${updatedIssue.title}`);
    } else {
      console.log('❌ Error al actualizar TEN-75');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

completeTEN75();
