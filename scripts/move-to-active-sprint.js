#!/usr/bin/env node

/**
 * Script para mover las historias de mensajería al sprint activo
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function moveToActiveSprint() {
  try {
    console.log('🚀 Moviendo historias de mensajería al sprint activo...\n');

    const { teamId } = getLinearConfig();

    // Obtener sprints activos
    const sprintsQuery = `
      query {
        team(id: "${teamId}") {
          activeCycle {
            id
            name
            number
            startsAt
            endsAt
          }
        }
      }
    `;

    const sprintsResponse = await makeLinearRequest(sprintsQuery);
    let activeCycle = sprintsResponse.data.team.activeCycle;

    if (!activeCycle) {
      console.log('❌ No hay sprint activo. Creando uno nuevo...');
      
      // Crear nuevo sprint
      const createCycleMutation = `
        mutation {
          cycleCreate(input: {
            name: "Sprint - Sistema de Mensajería"
            teamId: "${teamId}"
            startsAt: "${new Date().toISOString()}"
            endsAt: "${new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString()}"
          }) {
            cycle {
              id
              name
              number
            }
          }
        }
      `;
      
      const createResponse = await makeLinearRequest(createCycleMutation);
      const newCycle = createResponse.data.cycleCreate.cycle;
      console.log(`✅ Sprint creado: ${newCycle.name} (ID: ${newCycle.id})`);
      
      // Usar el nuevo sprint
      activeCycle = newCycle;
    } else {
      console.log(`📅 Sprint activo encontrado: ${activeCycle.name} (ID: ${activeCycle.id})`);
    }

    // Obtener historias de mensajería
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
            cycle {
              id
              name
            }
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar historias de mensajería (US-001 a US-012)
    const messagingIssues = allIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      if (match) {
        const number = parseInt(match[1]);
        return number >= 1 && number <= 12;
      }
      return false;
    });

    console.log(`📋 Encontradas ${messagingIssues.length} historias de mensajería`);

    // Mover historias al sprint activo
    let movedCount = 0;
    for (const issue of messagingIssues) {
      if (!issue.cycle || issue.cycle.id !== activeCycle.id) {
        console.log(`📝 Moviendo: ${issue.title} (#${issue.number})`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              cycleId: "${activeCycle.id}"
            }) {
              issue {
                id
                title
                cycle {
                  name
                }
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          console.log(`  ✅ Movido a: ${updatedIssue.cycle.name}`);
          movedCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`ℹ️  ${issue.title} (#${issue.number}) ya está en el sprint activo`);
      }
    }

    console.log(`\n🎉 ¡Proceso completado!`);
    console.log(`📊 Historias movidas: ${movedCount}/${messagingIssues.length}`);
    console.log(`📅 Sprint activo: ${activeCycle.name}`);

    // Mostrar resumen del sprint
    console.log('\n📋 Resumen del Sprint:');
    console.log('─'.repeat(50));
    
    const sprintIssues = allIssues.filter(issue => 
      issue.cycle && issue.cycle.id === activeCycle.id
    );
    
    console.log(`Total de issues en sprint: ${sprintIssues.length}`);
    
    const messagingInSprint = sprintIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      if (match) {
        const number = parseInt(match[1]);
        return number >= 1 && number <= 12;
      }
      return false;
    });
    
    console.log(`Historias de mensajería en sprint: ${messagingInSprint.length}`);
    
    if (messagingInSprint.length > 0) {
      console.log('\n📝 Historias de mensajería en el sprint:');
      messagingInSprint.forEach(issue => {
        console.log(`  - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    }

  } catch (error) {
    console.error('❌ Error moviendo historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
moveToActiveSprint();
