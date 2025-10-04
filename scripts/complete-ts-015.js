#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function completeTS015() {
  console.log('🎯 Completando TS-015: Testing de Autenticación Firebase...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Buscar la issue TS-015
    const issueQuery = `
      query {
        team(id: "${teamId}") {
          issues(first: 50) {
            nodes {
              id
              title
              number
              state {
                id
                name
              }
            }
          }
        }
      }
    `;

    console.log('🔍 Buscando issue TS-015...');
    const issueResponse = await makeLinearRequest(issueQuery);
    const issues = issueResponse.data.team.issues.nodes;
    
    const ts015 = issues.find(issue => issue.number === 71); // TS-015 es issue #71
    
    if (!ts015) {
      console.log('❌ No se encontró la issue TS-015 (#71)');
      return;
    }

    console.log(`✅ Issue encontrada: #${ts015.number} - ${ts015.title}`);
    console.log(`📊 Estado actual: ${ts015.state.name}`);

    // Buscar el estado "Done"
    const statesQuery = `
      query {
        team(id: "${teamId}") {
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

    console.log('🔍 Buscando estado "Done"...');
    const statesResponse = await makeLinearRequest(statesQuery);
    const states = statesResponse.data.team.states.nodes;
    
    const doneState = states.find(state => state.name === 'Done' || state.name === 'Completed');
    
    if (!doneState) {
      console.log('❌ No se encontró el estado "Done"');
      return;
    }

    console.log(`✅ Estado "Done" encontrado: ${doneState.name} (${doneState.type})`);

    // Actualizar la issue a estado "Done"
    const updateMutation = `
      mutation {
        issueUpdate(
          id: "${ts015.id}",
          input: {
            stateId: "${doneState.id}"
          }
        ) {
          success
          issue {
            id
            title
            number
            state {
              name
            }
          }
        }
      }
    `;

    console.log('🔄 Actualizando estado a "Done"...');
    const updateResponse = await makeLinearRequest(updateMutation);
    
    if (updateResponse.data.issueUpdate.success) {
      const updatedIssue = updateResponse.data.issueUpdate.issue;
      console.log(`\n🎉 ¡Issue completada exitosamente!`);
      console.log(`📋 Issue #${updatedIssue.number}: ${updatedIssue.title}`);
      console.log(`📊 Nuevo estado: ${updatedIssue.state.name}`);
      console.log(`🔗 URL: https://linear.app/tennis-management-system/issue/TEN-${updatedIssue.number}`);
    } else {
      console.log('❌ Error al actualizar la issue');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('🔍 Detalles:', error);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  completeTS015();
}

module.exports = { completeTS015 };
