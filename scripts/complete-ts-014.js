#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function completeTS014() {
  console.log('🎯 Completando TS-014: Testing de Repositorios - Messaging...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Buscar la issue TS-014
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

    console.log('🔍 Buscando issue TS-014...');
    const issueResponse = await makeLinearRequest(issueQuery);
    const issues = issueResponse.data.team.issues.nodes;
    
    const ts014 = issues.find(issue => issue.number === 70); // TS-014 es issue #70
    
    if (!ts014) {
      console.log('❌ No se encontró la issue TS-014 (#70)');
      return;
    }

    console.log(`✅ Issue encontrada: #${ts014.number} - ${ts014.title}`);
    console.log(`📊 Estado actual: ${ts014.state.name}`);

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
          id: "${ts014.id}",
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
  completeTS014();
}

module.exports = { completeTS014 };
