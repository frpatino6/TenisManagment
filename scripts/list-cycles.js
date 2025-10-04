#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function listCycles() {
  console.log('🔄 Consultando Cycles (Sprints) en Linear...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Obtener todos los cycles
    const cyclesQuery = `
      query {
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
                estimate
              }
            }
          }
        }
      }
    `;

    const cyclesResponse = await makeLinearRequest(cyclesQuery);
    const cycles = cyclesResponse.data.cycles.nodes;
    
    if (cycles.length === 0) {
      console.log('❌ No se encontraron cycles en Linear');
      return;
    }

    console.log(`🔄 Cycles encontrados: ${cycles.length}\n`);

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
      
      // Resumen de issues
      const totalIssues = cycle.issues.nodes.length;
      const completedIssues = cycle.issues.nodes.filter(issue => 
        issue.state.name === 'Done' || issue.state.name === 'Completed'
      ).length;
      const totalStoryPoints = cycle.issues.nodes.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
      const assignedIssues = cycle.issues.nodes.filter(issue => issue.assignee).length;
      
      console.log(`   📋 Issues: ${totalIssues} (${completedIssues} completados)`);
      console.log(`   📊 Story Points: ${totalStoryPoints}`);
      console.log(`   👤 Issues asignados: ${assignedIssues}/${totalIssues}`);
      
      // Mostrar issues del cycle
      if (totalIssues > 0) {
        console.log(`   📋 Issues en este cycle:`);
        cycle.issues.nodes.forEach(issue => {
          const status = issue.state.name === 'Done' || issue.state.name === 'Completed' ? '✅' : '🔄';
          const assignee = issue.assignee ? issue.assignee.name : 'Sin asignar';
          const points = issue.estimate || 'N/A';
          console.log(`      ${status} #${issue.number}: ${issue.title.substring(0, 50)} | ${assignee} | ${points} pts`);
        });
      }
      
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

  } catch (error) {
    console.error('❌ Error al consultar cycles:', error.message);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  listCycles();
}

module.exports = { listCycles };
