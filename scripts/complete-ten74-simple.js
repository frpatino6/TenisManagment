const { getLinearConfig, makeLinearRequest, loadLinearConfig } = require('./scripts/linear-utils');

async function completeTEN74() {
  try {
    console.log('🎯 Completando TEN-74: Testing de Integración - Student Flow...');
    
    loadLinearConfig();
    const config = getLinearConfig();
    
    // Get all issues to find TEN-74
    const getIssuesQuery = `
      query {
        issues(first: 100, filter: { team: { id: { eq: "${config.teamId}" } } }) {
          nodes {
            id
            identifier
            title
            state {
              id
              name
            }
          }
        }
      }
    `;

    const response = await makeLinearRequest(getIssuesQuery);
    const issues = response.data?.issues?.nodes || [];
    
    const ten74 = issues.find(issue => issue.identifier === 'TEN-74');
    
    if (!ten74) {
      console.log('❌ No se encontró TEN-74 en la lista de issues');
      return;
    }

    console.log(`📋 Historia encontrada: ${ten74.identifier}: ${ten74.title}`);
    console.log(`📊 Estado actual: ${ten74.state.name}`);

    // Get team states to find Done state
    const getStatesQuery = `
      query {
        team(id: "${config.teamId}") {
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

    const statesResponse = await makeLinearRequest(getStatesQuery);
    const states = statesResponse.data?.team?.states?.nodes || [];
    
    // Find the "Done" state
    const doneState = states.find(state => 
      state.name.toLowerCase() === 'done' || 
      state.name.toLowerCase() === 'completed' ||
      state.type === 'completed'
    );

    if (!doneState) {
      console.log('❌ No se encontró el estado "Done"');
      return;
    }

    console.log(`✅ Usando estado: ${doneState.name}`);
    
    // Update the story to Done status with simple description
    const updateMutation = `
      mutation {
        issueUpdate(
          id: "${ten74.id}",
          input: {
            stateId: "${doneState.id}",
            description: "✅ COMPLETADO: Testing de Integración - Student Flow\\n\\nSe implementaron 10 tests de integración completos para el flujo de estudiantes:\\n\\n- Student Registration Integration\\n- Student-Professor-Schedule Integration\\n- Student Payment Integration\\n- Student Service Request Integration\\n- Complete Student Flow Integration\\n\\nTodos los tests pasan exitosamente (10/10) y validan la integridad de datos entre entidades MongoDB.\\n\\nArchivos creados:\\n- src/__tests__/integration/student-flow-basic.test.ts\\n\\nFecha: ${new Date().toISOString().split('T')[0]}"
          }
        ) {
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

    const updateResponse = await makeLinearRequest(updateMutation);
    
    if (updateResponse.data?.issueUpdate?.issue) {
      const updatedIssue = updateResponse.data.issueUpdate.issue;
      console.log('✅ Historia completada exitosamente:');
      console.log(`   📋 ${updatedIssue.identifier}: ${updatedIssue.title}`);
      console.log(`   📊 Estado: ${updatedIssue.state.name}`);
    } else {
      console.log('❌ Error al completar la historia');
      if (updateResponse.errors) {
        console.log('Errores:', updateResponse.errors);
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

completeTEN74();
