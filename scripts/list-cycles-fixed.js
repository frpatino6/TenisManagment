#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function listCycles() {
  console.log('🔄 Consultando Cycles (Sprints) en Linear...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Primero intentar obtener cycles del team específico
    const cyclesQuery = `
      query {
        team(id: "${teamId}") {
          id
          name
          cycles(first: 20) {
            nodes {
              id
              number
              name
              description
              state
              startsAt
              endsAt
              completedAt
              createdAt
              updatedAt
            }
          }
        }
      }
    `;

    console.log('🔍 Ejecutando consulta de cycles...');
    const cyclesResponse = await makeLinearRequest(cyclesQuery);
    
    if (!cyclesResponse.data || !cyclesResponse.data.team) {
      console.log('❌ No se pudo obtener información del team');
      return;
    }

    const team = cyclesResponse.data.team;
    const cycles = team.cycles.nodes;
    
    console.log(`🏢 Team: ${team.name}`);
    console.log(`🔄 Cycles encontrados: ${cycles.length}\n`);

    if (cycles.length === 0) {
      console.log('❌ No se encontraron cycles en este team');
      return;
    }

    cycles.forEach(cycle => {
      const startDate = cycle.startsAt ? new Date(cycle.startsAt).toLocaleDateString() : 'Sin fecha';
      const endDate = cycle.endsAt ? new Date(cycle.endsAt).toLocaleDateString() : 'Sin fecha';
      const completedDate = cycle.completedAt ? new Date(cycle.completedAt).toLocaleDateString() : 'No completado';
      
      console.log(`🔄 Cycle #${cycle.number}: ${cycle.name || 'Sin nombre'}`);
      console.log(`   📝 Descripción: ${cycle.description || 'Sin descripción'}`);
      console.log(`   📊 Estado: ${cycle.state}`);
      console.log(`   📅 Inicio: ${startDate}`);
      console.log(`   📅 Fin: ${endDate}`);
      console.log(`   ✅ Completado: ${completedDate}`);
      console.log('   ────────────────────────────────────────────────────────────');
    });

    // Resumen general
    const activeCycles = cycles.filter(cycle => cycle.state === 'active');
    const completedCycles = cycles.filter(cycle => cycle.state === 'completed');
    const plannedCycles = cycles.filter(cycle => cycle.state === 'planned');
    
    console.log('\n📊 RESUMEN DE CYCLES:');
    console.log(`   🔄 Total de cycles: ${cycles.length}`);
    console.log(`   🟢 Cycles activos: ${activeCycles.length}`);
    console.log(`   ✅ Cycles completados: ${completedCycles.length}`);
    console.log(`   📋 Cycles planificados: ${plannedCycles.length}`);

    // Ahora obtener issues para cada cycle
    console.log('\n🔍 Obteniendo issues por cycle...');
    
    for (const cycle of cycles) {
      const issuesQuery = `
        query {
          cycle(id: "${cycle.id}") {
            issues(first: 50) {
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
                estimate
              }
            }
          }
        }
      `;

      try {
        const issuesResponse = await makeLinearRequest(issuesQuery);
        const cycleIssues = issuesResponse.data.cycle?.issues?.nodes || [];
        
        if (cycleIssues.length > 0) {
          console.log(`\n📋 Issues en Cycle #${cycle.number} (${cycle.name || 'Sin nombre'}):`);
          
          const completedIssues = cycleIssues.filter(issue => 
            issue.state.name === 'Done' || issue.state.name === 'Completed'
          ).length;
          const totalStoryPoints = cycleIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
          const assignedIssues = cycleIssues.filter(issue => issue.assignee).length;
          
          console.log(`   📊 Total: ${cycleIssues.length} issues, ${completedIssues} completados`);
          console.log(`   📊 Story Points: ${totalStoryPoints}`);
          console.log(`   👤 Asignados: ${assignedIssues}/${cycleIssues.length}`);
          
          cycleIssues.forEach(issue => {
            const status = issue.state.name === 'Done' || issue.state.name === 'Completed' ? '✅' : '🔄';
            const assignee = issue.assignee ? issue.assignee.name : 'Sin asignar';
            const points = issue.estimate || 'N/A';
            console.log(`      ${status} #${issue.number}: ${issue.title.substring(0, 50)} | ${assignee} | ${points} pts`);
          });
        }
      } catch (error) {
        console.log(`   ❌ Error obteniendo issues para cycle #${cycle.number}: ${error.message}`);
      }
    }

  } catch (error) {
    console.error('❌ Error al consultar cycles:', error.message);
    console.log('🔍 Detalles del error:', error);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  listCycles();
}

module.exports = { listCycles };
