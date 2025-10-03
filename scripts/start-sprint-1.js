#!/usr/bin/env node

/**
 * Script para iniciar el Sprint 1 moviendo las historias a "In Progress"
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function startSprint1() {
  try {
    console.log('🚀 Iniciando Sprint 1: Backend de Mensajería...\n');

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

    // Buscar estado "In Progress" o "Started"
    const inProgressState = states.find(state => 
      state.type === 'started' || 
      state.name.toLowerCase().includes('progress') ||
      state.name.toLowerCase().includes('started')
    );

    if (!inProgressState) {
      console.log('❌ No se encontró estado "In Progress". Estados disponibles:');
      states.forEach(state => {
        console.log(`  - ${state.name} (${state.type})`);
      });
      return;
    }

    console.log(`📋 Estado encontrado: ${inProgressState.name} (${inProgressState.type})`);

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

    console.log(`📋 Encontradas ${sprint1Issues.length} historias del Sprint 1`);

    // Mover historias a "In Progress"
    let movedCount = 0;
    for (const issue of sprint1Issues) {
      if (issue.state.name !== inProgressState.name) {
        console.log(`📝 Moviendo: ${issue.title} (#${issue.number})`);
        
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
          movedCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`ℹ️  ${issue.title} (#${issue.number}) ya está en ${issue.state.name}`);
      }
    }

    console.log(`\n🎉 ¡Sprint 1 iniciado!`);
    console.log(`📊 Historias movidas a "In Progress": ${movedCount}/${sprint1Issues.length}`);

    // Mostrar resumen del Sprint 1
    console.log('\n📋 RESUMEN DEL SPRINT 1:');
    console.log('─'.repeat(50));
    
    sprint1Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                          issue.priority === 2 ? '⚡ High' : 
                          issue.priority === 3 ? '💡 Medium' : '📝 Low';
      
      console.log(`  ${issue.title} (#${issue.number})`);
      console.log(`    ${priorityText} | ${issue.estimate} pts | ${issue.state.name}`);
      console.log('');
    });

    console.log('🚀 ¡Listo para comenzar el desarrollo del Sprint 1!');
    console.log('📝 Próximo paso: Comenzar con US-001: Modelo de Datos de Mensajes');

  } catch (error) {
    console.error('❌ Error iniciando Sprint 1:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
startSprint1();
