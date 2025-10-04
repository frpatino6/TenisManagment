#!/usr/bin/env node

/**
 * Script para activar Sprint Testing 2 y 3 y mover historias a In Progress
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function activateSprints2And3() {
  try {
    console.log('🚀 Activando Sprint Testing 2 y 3...\n');

    // 1. Obtener todas las historias TS-XXX
    console.log('📋 Obteniendo historias TS-XXX...');
    
    const getTSIssuesQuery = `
      query {
        issues(first: 50, filter: { 
          labels: { name: { eq: "testing" } }
        }) {
          nodes {
            id
            title
            number
            state {
              id
              name
            }
            cycle {
              id
              name
              number
            }
            assignee {
              id
              name
            }
          }
        }
      }
    `;

    const tsIssuesResponse = await makeLinearRequest(getTSIssuesQuery);
    const allTSIssues = tsIssuesResponse.data.issues.nodes.filter(issue => 
      issue.title.startsWith('TS-')
    );

    console.log(`📊 Total historias TS-XXX: ${allTSIssues.length}`);

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

    console.log(`✅ Estado "In Progress" encontrado: ${inProgressState.name}`);

    // 3. Obtener el usuario actual
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

    console.log(`👤 Usuario actual: ${currentUser.name}`);

    // 4. Filtrar historias por sprint
    const sprint2Issues = allTSIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 2 - Infrastructure y Integration'
    );

    const sprint3Issues = allTSIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 3 - E2E y Documentación'
    );

    console.log(`\n📊 Sprint Testing 2: ${sprint2Issues.length} historias`);
    console.log(`📊 Sprint Testing 3: ${sprint3Issues.length} historias`);

    // 5. Activar Sprint Testing 2
    console.log('\n🚀 ACTIVANDO SPRINT TESTING 2...');
    console.log('─'.repeat(60));
    
    if (sprint2Issues.length > 0) {
      // Mover las primeras 3 historias a "In Progress"
      const sprint2StoriesToMove = sprint2Issues.slice(0, 3);
      
      console.log(`📝 Moviendo ${sprint2StoriesToMove.length} historias a "In Progress":`);
      
      let sprint2MovedCount = 0;
      for (const issue of sprint2StoriesToMove) {
        console.log(`📝 Moviendo: ${issue.title} (#${issue.number})`);
        console.log(`   Estado actual: ${issue.state.name}`);
        
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
            console.log(`   ✅ Movido a: ${updatedIssue.state.name}`);
            console.log(`   👤 Asignado a: ${updatedIssue.assignee.name}`);
            sprint2MovedCount++;
          } else {
            console.log(`   ❌ Error moviendo: ${issue.title}`);
          }
        } catch (error) {
          console.log(`   ❌ Error: ${error.message}`);
        }
        
        console.log(''); // Línea en blanco para separar
      }

      console.log(`🎉 Sprint 2 - Movimiento completado: ${sprint2MovedCount}/${sprint2StoriesToMove.length} historias`);
    } else {
      console.log('⚠️  No hay historias en Sprint Testing 2');
    }

    // 6. Activar Sprint Testing 3
    console.log('\n🚀 ACTIVANDO SPRINT TESTING 3...');
    console.log('─'.repeat(60));
    
    if (sprint3Issues.length > 0) {
      // Mover las primeras 2 historias a "In Progress"
      const sprint3StoriesToMove = sprint3Issues.slice(0, 2);
      
      console.log(`📝 Moviendo ${sprint3StoriesToMove.length} historias a "In Progress":`);
      
      let sprint3MovedCount = 0;
      for (const issue of sprint3StoriesToMove) {
        console.log(`📝 Moviendo: ${issue.title} (#${issue.number})`);
        console.log(`   Estado actual: ${issue.state.name}`);
        
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
            console.log(`   ✅ Movido a: ${updatedIssue.state.name}`);
            console.log(`   👤 Asignado a: ${updatedIssue.assignee.name}`);
            sprint3MovedCount++;
          } else {
            console.log(`   ❌ Error moviendo: ${issue.title}`);
          }
        } catch (error) {
          console.log(`   ❌ Error: ${error.message}`);
        }
        
        console.log(''); // Línea en blanco para separar
      }

      console.log(`🎉 Sprint 3 - Movimiento completado: ${sprint3MovedCount}/${sprint3StoriesToMove.length} historias`);
    } else {
      console.log('⚠️  No hay historias en Sprint Testing 3');
    }

    // 7. Verificar el estado final
    console.log('\n🔍 Verificando estado final...');
    
    const finalIssuesQuery = `
      query {
        issues(first: 50, filter: { 
          labels: { name: { eq: "testing" } }
        }) {
          nodes {
            id
            title
            number
            state {
              name
            }
            cycle {
              name
            }
            assignee {
              name
            }
          }
        }
      }
    `;

    const finalResponse = await makeLinearRequest(finalIssuesQuery);
    const finalAllIssues = finalResponse.data.issues.nodes.filter(issue => 
      issue.title.startsWith('TS-')
    );

    // Filtrar por sprint
    const finalSprint2Issues = finalAllIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 2 - Infrastructure y Integration'
    );

    const finalSprint3Issues = finalAllIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 3 - E2E y Documentación'
    );

    // Contar por estado para Sprint 2
    const sprint2StateCounts = {};
    finalSprint2Issues.forEach(issue => {
      const stateName = issue.state.name;
      sprint2StateCounts[stateName] = (sprint2StateCounts[stateName] || 0) + 1;
    });

    // Contar por estado para Sprint 3
    const sprint3StateCounts = {};
    finalSprint3Issues.forEach(issue => {
      const stateName = issue.state.name;
      sprint3StateCounts[stateName] = (sprint3StateCounts[stateName] || 0) + 1;
    });

    console.log('\n📊 ESTADO FINAL DEL SPRINT TESTING 2:');
    console.log('─'.repeat(60));
    console.log(`📊 Total issues: ${finalSprint2Issues.length}`);
    
    Object.entries(sprint2StateCounts).forEach(([state, count]) => {
      console.log(`   ${state}: ${count} historias`);
    });

    console.log('\n📊 ESTADO FINAL DEL SPRINT TESTING 3:');
    console.log('─'.repeat(60));
    console.log(`📊 Total issues: ${finalSprint3Issues.length}`);
    
    Object.entries(sprint3StateCounts).forEach(([state, count]) => {
      console.log(`   ${state}: ${count} historias`);
    });

    // Mostrar las historias en "In Progress"
    const sprint2InProgressIssues = finalSprint2Issues.filter(issue => 
      issue.state.name === 'In Progress'
    );

    const sprint3InProgressIssues = finalSprint3Issues.filter(issue => 
      issue.state.name === 'In Progress'
    );

    if (sprint2InProgressIssues.length > 0) {
      console.log('\n✅ HISTORIAS EN "IN PROGRESS" - SPRINT 2:');
      sprint2InProgressIssues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
        console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
      });
    }

    if (sprint3InProgressIssues.length > 0) {
      console.log('\n✅ HISTORIAS EN "IN PROGRESS" - SPRINT 3:');
      sprint3InProgressIssues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
        console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
      });
    }

    // 8. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`✅ Sprint Testing 2 activado`);
    console.log(`📊 Total issues: ${finalSprint2Issues.length}`);
    console.log(`✅ En "In Progress": ${sprint2StateCounts['In Progress'] || 0}`);
    console.log(`📋 En "Backlog": ${sprint2StateCounts['Backlog'] || 0}`);
    
    console.log(`\n✅ Sprint Testing 3 activado`);
    console.log(`📊 Total issues: ${finalSprint3Issues.length}`);
    console.log(`✅ En "In Progress": ${sprint3StateCounts['In Progress'] || 0}`);
    console.log(`📋 En "Backlog": ${sprint3StateCounts['Backlog'] || 0}`);
    
    console.log('\n💡 PRÓXIMOS PASOS:');
    console.log('1. Refrescar la página en Linear');
    console.log('2. Ir a los Sprint Testing 2 y 3');
    console.log('3. Las historias en "In Progress" deberían ser visibles');
    console.log('4. Comenzar a trabajar en las historias asignadas');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
activateSprints2And3();
