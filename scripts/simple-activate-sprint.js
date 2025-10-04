#!/usr/bin/env node

/**
 * Script simple para activar Sprint Testing 1 y mover historias
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function simpleActivateSprint() {
  try {
    console.log('🚀 Activando Sprint Testing 1...\n');

    // 1. Obtener todas las historias TS-XXX que están en Sprint Testing 1
    console.log('📋 Obteniendo historias del Sprint Testing 1...');
    
    const getIssuesQuery = `
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
            }
            assignee {
              id
              name
            }
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(getIssuesQuery);
    const allIssues = issuesResponse.data.issues.nodes.filter(issue => 
      issue.title.startsWith('TS-')
    );

    // Filtrar las que están en Sprint Testing 1
    const sprint1Issues = allIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 1 - Configuración y Core'
    );

    console.log(`📊 Historias en Sprint Testing 1: ${sprint1Issues.length}`);

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

    // 4. Mover las primeras 5 historias a "In Progress"
    console.log('\n📝 Moviendo historias a "In Progress"...');
    
    const storiesToMove = sprint1Issues.slice(0, 5);
    
    console.log(`📊 Moviendo ${storiesToMove.length} historias:`);
    
    let movedCount = 0;
    for (const issue of storiesToMove) {
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
          movedCount++;
        } else {
          console.log(`   ❌ Error moviendo: ${issue.title}`);
        }
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
      }
      
      console.log(''); // Línea en blanco para separar
    }

    console.log(`🎉 Movimiento completado: ${movedCount}/${storiesToMove.length} historias`);

    // 5. Verificar el estado final
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

    const finalSprint1Issues = finalAllIssues.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 1 - Configuración y Core'
    );

    // Contar por estado
    const stateCounts = {};
    finalSprint1Issues.forEach(issue => {
      const stateName = issue.state.name;
      stateCounts[stateName] = (stateCounts[stateName] || 0) + 1;
    });

    console.log('\n📊 ESTADO FINAL DEL SPRINT TESTING 1:');
    console.log('─'.repeat(60));
    console.log(`📊 Total issues: ${finalSprint1Issues.length}`);
    
    Object.entries(stateCounts).forEach(([state, count]) => {
      console.log(`   ${state}: ${count} historias`);
    });

    // Mostrar las historias en "In Progress"
    const inProgressIssues = finalSprint1Issues.filter(issue => 
      issue.state.name === 'In Progress'
    );

    if (inProgressIssues.length > 0) {
      console.log('\n✅ HISTORIAS EN "IN PROGRESS":');
      inProgressIssues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
        console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
      });
    }

    // 6. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`✅ Sprint Testing 1 activado`);
    console.log(`📊 Total issues: ${finalSprint1Issues.length}`);
    console.log(`✅ En "In Progress": ${stateCounts['In Progress'] || 0}`);
    console.log(`📋 En "Backlog": ${stateCounts['Backlog'] || 0}`);
    
    console.log('\n💡 PRÓXIMOS PASOS:');
    console.log('1. Refrescar la página en Linear');
    console.log('2. Ir al Sprint Testing 1');
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
simpleActivateSprint();
