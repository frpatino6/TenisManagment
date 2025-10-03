#!/usr/bin/env node

/**
 * Script para corregir los estados de las historias del Sprint 1
 * Mover de "In Review" a "In Progress" si es necesario
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function fixSprint1States() {
  try {
    console.log('🔧 Corrigiendo estados del Sprint 1...\n');

    const { teamId } = getLinearConfig();

    // Obtener estados disponibles
    const statesQuery = `
      query {
        workflowStates(first: 20) {
          nodes {
            id
            name
            type
            team {
              id
            }
          }
        }
      }
    `;

    const statesResponse = await makeLinearRequest(statesQuery);
    const states = statesResponse.data.workflowStates.nodes.filter(
      state => state.team.id === teamId
    );

    console.log('📋 Estados disponibles:');
    states.forEach(state => {
      console.log(`  - ${state.name} (${state.type})`);
    });

    // Buscar estado "In Progress" específicamente
    const inProgressState = states.find(state => 
      state.name === 'In Progress'
    );

    if (!inProgressState) {
      console.log('❌ No se encontró estado "In Progress"');
      return;
    }

    console.log(`\n🎯 Estado objetivo: ${inProgressState.name} (${inProgressState.type})`);

    // Obtener historias del Sprint 1 (US-001 a US-004)
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            state {
              id
              name
            }
            estimate
            priority
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar historias del Sprint 1 (US-001 a US-004)
    const sprint1Issues = allIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      if (match) {
        const number = parseInt(match[1]);
        return number >= 1 && number <= 4;
      }
      return false;
    });

    console.log(`\n📋 Encontradas ${sprint1Issues.length} historias del Sprint 1`);

    // Verificar y corregir estados
    let correctedCount = 0;
    for (const issue of sprint1Issues) {
      console.log(`\n📝 Verificando: ${issue.title} (#${issue.number})`);
      console.log(`  Estado actual: ${issue.state.name}`);
      
      if (issue.state.name !== inProgressState.name) {
        console.log(`  🔄 Moviendo a: ${inProgressState.name}`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              stateId: "${inProgressState.id}"
            }) {
              issue {
                id
                title
                state {
                  name
                }
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          console.log(`  ✅ Movido a: ${updatedIssue.state.name}`);
          correctedCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`  ✅ Ya está en el estado correcto`);
      }
    }

    console.log(`\n🎉 ¡Corrección completada!`);
    console.log(`📊 Historias corregidas: ${correctedCount}/${sprint1Issues.length}`);

    // Mostrar estado final
    console.log('\n📋 ESTADO FINAL DEL SPRINT 1:');
    console.log('─'.repeat(50));
    
    sprint1Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                          issue.priority === 2 ? '⚡ High' : 
                          issue.priority === 3 ? '💡 Medium' : '📝 Low';
      
      console.log(`  ${issue.title} (#${issue.number})`);
      console.log(`    ${priorityText} | ${issue.estimate} pts | Estado: ${issue.state.name}`);
    });

  } catch (error) {
    console.error('❌ Error corrigiendo estados:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
fixSprint1States();
