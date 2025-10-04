#!/usr/bin/env node

/**
 * Script para activar Sprint Testing 1 y mover historias a In Progress
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function activateSprintAndMoveStories() {
  try {
    console.log('🚀 Activando Sprint Testing 1 y moviendo historias...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener el Sprint Testing 1
    console.log('📋 Obteniendo Sprint Testing 1...');
    
    const getSprintQuery = `
      query {
        cycles(first: 10) {
          nodes {
            id
            name
            number
            state
            issues {
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
      }
    `;

    const sprintResponse = await makeLinearRequest(getSprintQuery);
    const sprints = sprintResponse.data.cycles.nodes;

    const sprintTesting1 = sprints.find(sprint => 
      sprint.name === 'Sprint Testing 1 - Configuración y Core'
    );

    if (!sprintTesting1) {
      console.log('❌ No se encontró el Sprint Testing 1');
      return;
    }

    console.log(`📋 Sprint encontrado: ${sprintTesting1.name} (#${sprintTesting1.number})`);
    console.log(`📊 Issues en el sprint: ${sprintTesting1.issues.nodes.length}`);

    // 2. Obtener el estado "In Progress"
    console.log('\n📋 Obteniendo estado "In Progress"...');
    
    const getStatesQuery = `
      query {
        workflowStates(first: 20) {
          nodes {
            id
            name
            type
          }
        }
      }
    `;

    const statesResponse = await makeLinearRequest(getStatesQuery);
    const inProgressState = statesResponse.data.workflowStates.nodes.find(
      state => state.name === 'In Progress'
    );

    if (!inProgressState) {
      console.log('❌ No se encontró el estado "In Progress"');
      return;
    }

    console.log(`✅ Estado "In Progress" encontrado: ${inProgressState.name} (${inProgressState.id})`);

    // 3. Obtener el usuario actual para asignar las historias
    console.log('\n👤 Obteniendo usuario actual...');
    
    const getCurrentUserQuery = `
      query {
        viewer {
          id
          name
          email
        }
      }
    `;

    const userResponse = await makeLinearRequest(getCurrentUserQuery);
    const currentUser = userResponse.data.viewer;

    console.log(`👤 Usuario actual: ${currentUser.name} (${currentUser.email})`);

    // 4. Activar el sprint (cambiar estado a "Active")
    console.log('\n🚀 Activando el sprint...');
    
    const activateSprintMutation = `
      mutation {
        cycleUpdate(
          id: "${sprintTesting1.id}"
          input: {
            state: "active"
          }
        ) {
          success
          cycle {
            id
            name
            state
          }
        }
      }
    `;

    const activateResponse = await makeLinearRequest(activateSprintMutation);
    
    if (activateResponse.data.cycleUpdate?.success) {
      console.log('✅ Sprint activado correctamente');
    } else {
      console.log('⚠️  No se pudo activar el sprint (puede que ya esté activo)');
    }

    // 5. Mover las primeras 5 historias a "In Progress"
    console.log('\n📝 Moviendo historias a "In Progress"...');
    
    const storiesToMove = sprintTesting1.issues.nodes.slice(0, 5);
    
    console.log(`📊 Moviendo ${storiesToMove.length} historias a "In Progress":`);
    
    let movedCount = 0;
    for (const issue of storiesToMove) {
      console.log(`📝 Moviendo: ${issue.title} (#${issue.number})`);
      
      const updateIssueMutation = `
        mutation {
          issueUpdate(
            id: "${issue.id}"
            input: {
              stateId: "${inProgressState.id}"
              assigneeId: "${currentUser.id}"
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
              assignee {
                name
              }
            }
          }
        }
      `;

      try {
        const updateResponse = await makeLinearRequest(updateIssueMutation);
        
        if (updateResponse.data.issueUpdate?.success) {
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          console.log(`   ✅ Movido a: ${updatedIssue.state.name} - Asignado a: ${updatedIssue.assignee.name}`);
          movedCount++;
        } else {
          console.log(`   ❌ Error moviendo: ${issue.title}`);
        }
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
      }
    }

    console.log(`\n🎉 Movimiento completado: ${movedCount}/${storiesToMove.length} historias`);

    // 6. Verificar el estado final
    console.log('\n🔍 Verificando estado final...');
    
    const finalSprintQuery = `
      query {
        cycle(id: "${sprintTesting1.id}") {
          id
          name
          state
          issues {
            nodes {
              id
              title
              number
              state {
                name
              }
              assignee {
                name
              }
            }
          }
        }
      }
    `;

    const finalResponse = await makeLinearRequest(finalSprintQuery);
    const finalSprint = finalResponse.data.cycle;

    console.log(`📊 Estado final del sprint: ${finalSprint.state}`);
    console.log(`📊 Issues en el sprint: ${finalSprint.issues.nodes.length}`);
    
    // Contar por estado
    const stateCounts = {};
    finalSprint.issues.nodes.forEach(issue => {
      const stateName = issue.state.name;
      stateCounts[stateName] = (stateCounts[stateName] || 0) + 1;
    });

    console.log('\n📊 DISTRIBUCIÓN POR ESTADO:');
    Object.entries(stateCounts).forEach(([state, count]) => {
      console.log(`   ${state}: ${count} historias`);
    });

    // 7. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`🚀 Sprint: ${finalSprint.name}`);
    console.log(`📊 Estado: ${finalSprint.state}`);
    console.log(`📊 Total issues: ${finalSprint.issues.nodes.length}`);
    console.log(`✅ En "In Progress": ${stateCounts['In Progress'] || 0}`);
    console.log(`📋 En "Backlog": ${stateCounts['Backlog'] || 0}`);
    
    console.log('\n💡 PRÓXIMOS PASOS:');
    console.log('1. Refrescar la página en Linear');
    console.log('2. Verificar que el sprint esté activo');
    console.log('3. Las historias en "In Progress" deberían ser visibles');
    console.log('4. Comenzar a trabajar en las historias asignadas');

  } catch (error) {
    console.error('❌ Error activando sprint:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
activateSprintAndMoveStories();
