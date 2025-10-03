#!/usr/bin/env node

/**
 * Script para mover todas las historias de Multi-Tenancy Backend al backlog
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function moveMultiTenancyToBacklog() {
  try {
    console.log('🔄 Moviendo historias de Multi-Tenancy Backend al backlog...\n');

    const { teamId } = getLinearConfig();

    // Obtener estado "Backlog"
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

    const backlogState = states.find(state => 
      state.name === 'Backlog' || state.type === 'backlog'
    );

    if (!backlogState) {
      console.log('❌ No se encontró estado "Backlog"');
      console.log('Estados disponibles:');
      states.forEach(state => {
        console.log(`  - ${state.name} (${state.type})`);
      });
      return;
    }

    console.log(`📋 Estado objetivo: ${backlogState.name} (${backlogState.type})`);

    // Obtener todas las issues
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
            labels {
              nodes {
                name
              }
            }
            estimate
            priority
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar historias de Multi-Tenancy
    const multiTenancyIssues = allIssues.filter(issue => {
      // Buscar por título que contenga "Multi-Tenancy" o "MT-"
      const titleMatch = issue.title.toLowerCase().includes('multi-tenancy') || 
                        issue.title.includes('MT-') ||
                        issue.title.includes('US-MT-');
      
      // Buscar por labels que contengan "multi-tenancy"
      const labelMatch = issue.labels.nodes.some(label => 
        label.name.toLowerCase().includes('multi-tenancy') ||
        label.name.toLowerCase().includes('tenant')
      );
      
      return titleMatch || labelMatch;
    });

    console.log(`📋 Encontradas ${multiTenancyIssues.length} historias de Multi-Tenancy`);

    if (multiTenancyIssues.length === 0) {
      console.log('ℹ️  No se encontraron historias de Multi-Tenancy');
      return;
    }

    // Mostrar historias encontradas
    console.log('\n📝 Historias de Multi-Tenancy encontradas:');
    multiTenancyIssues.forEach(issue => {
      const labels = issue.labels.nodes.map(label => label.name).join(', ');
      const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                          issue.priority === 2 ? '⚡ High' : 
                          issue.priority === 3 ? '💡 Medium' : '📝 Low';
      
      console.log(`  - ${issue.title} (#${issue.number})`);
      console.log(`    ${priorityText} | ${issue.estimate || 'N/A'} pts | Estado: ${issue.state.name}`);
      console.log(`    Labels: ${labels}`);
      console.log('');
    });

    // Mover historias al backlog
    let movedCount = 0;
    for (const issue of multiTenancyIssues) {
      if (issue.state.name !== backlogState.name) {
        console.log(`🔄 Moviendo: ${issue.title} (#${issue.number})`);
        console.log(`  De: ${issue.state.name} → A: ${backlogState.name}`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              stateId: "${backlogState.id}"
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

    console.log(`\n🎉 ¡Proceso completado!`);
    console.log(`📊 Historias movidas al backlog: ${movedCount}/${multiTenancyIssues.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN FINAL:');
    console.log('─'.repeat(50));
    console.log(`Total historias de Multi-Tenancy: ${multiTenancyIssues.length}`);
    console.log(`Movidas al backlog: ${movedCount}`);
    console.log(`Ya estaban en backlog: ${multiTenancyIssues.length - movedCount}`);

  } catch (error) {
    console.error('❌ Error moviendo historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
moveMultiTenancyToBacklog();
