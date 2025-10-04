#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function checkCycle5Details() {
  console.log('🔍 Analizando Cycle #5: Sprint Testing 2 - Infrastructure y Integration...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Primero obtener el ID del cycle #5
    const cyclesQuery = `
      query {
        team(id: "${teamId}") {
          cycles(first: 10) {
            nodes {
              id
              number
              name
              description
              startsAt
              endsAt
            }
          }
        }
      }
    `;

    console.log('🔍 Obteniendo información del cycle #5...');
    const cyclesResponse = await makeLinearRequest(cyclesQuery);
    const cycles = cyclesResponse.data.team.cycles.nodes;
    
    const cycle5 = cycles.find(cycle => cycle.number === 5);
    if (!cycle5) {
      console.log('❌ No se encontró el cycle #5');
      return;
    }

    console.log(`✅ Cycle #5 encontrado: ${cycle5.name}`);
    console.log(`📝 Descripción: ${cycle5.description}`);
    console.log(`📅 Período: ${new Date(cycle5.startsAt).toLocaleDateString()} - ${new Date(cycle5.endsAt).toLocaleDateString()}`);

    // Ahora obtener todas las issues del cycle #5
    const issuesQuery = `
      query {
        cycle(id: "${cycle5.id}") {
          issues(first: 50) {
            nodes {
              id
              title
              number
              description
              state {
                name
                type
              }
              assignee {
                name
                email
              }
              estimate
              priority
              labels {
                nodes {
                  name
                }
              }
              createdAt
              updatedAt
              url
            }
          }
        }
      }
    `;

    console.log('\n🔍 Obteniendo issues del cycle #5...');
    const issuesResponse = await makeLinearRequest(issuesQuery);
    const issues = issuesResponse.data.cycle.issues.nodes;

    console.log(`\n📋 Issues encontradas en Cycle #5: ${issues.length}\n`);

    if (issues.length === 0) {
      console.log('❌ No se encontraron issues en el cycle #5');
      return;
    }

    // Agrupar por estado
    const issuesByState = {
      'In Progress': issues.filter(issue => issue.state.name === 'In Progress'),
      'Backlog': issues.filter(issue => issue.state.name === 'Backlog'),
      'Todo': issues.filter(issue => issue.state.name === 'Todo'),
      'Done': issues.filter(issue => issue.state.name === 'Done'),
      'Completed': issues.filter(issue => issue.state.name === 'Completed'),
      'Other': issues.filter(issue => !['In Progress', 'Backlog', 'Todo', 'Done', 'Completed'].includes(issue.state.name))
    };

    // Mostrar issues por estado
    Object.entries(issuesByState).forEach(([state, stateIssues]) => {
      if (stateIssues.length > 0) {
        console.log(`\n📊 ${state.toUpperCase()} (${stateIssues.length} issues):`);
        console.log('─'.repeat(80));
        
        stateIssues.forEach(issue => {
          console.log(`\n📋 Issue #${issue.number}: ${issue.title}`);
          console.log(`   👤 Asignado: ${issue.assignee?.name || 'Sin asignar'}`);
          console.log(`   📊 Story Points: ${issue.estimate || 'Sin estimar'}`);
          console.log(`   ⚡ Prioridad: ${issue.priority || 'Sin prioridad'}`);
          console.log(`   🏷️  Labels: ${issue.labels?.nodes?.map(l => l.name).join(', ') || 'Sin labels'}`);
          console.log(`   🔗 URL: ${issue.url}`);
          
          // Extraer descripción si existe
          if (issue.description) {
            const lines = issue.description.split('\n');
            const descriptionLine = lines.find(line => line.includes('## Descripción'));
            if (descriptionLine) {
              const descIndex = lines.indexOf(descriptionLine);
              if (descIndex + 1 < lines.length) {
                console.log(`   📄 Descripción: ${lines[descIndex + 1].trim()}`);
              }
            }
            
            // Extraer criterios de aceptación si existen
            const criteriaLine = lines.find(line => line.includes('## Criterios de Aceptación'));
            if (criteriaLine) {
              console.log(`   ✅ Criterios de Aceptación: Disponibles`);
            }
            
            // Extraer Definition of Done si existe
            const doneLine = lines.find(line => line.includes('## Definition of Done'));
            if (doneLine) {
              console.log(`   🎯 Definition of Done: Disponible`);
            }
          }
        });
      }
    });

    // Resumen estadístico
    const totalStoryPoints = issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
    const assignedIssues = issues.filter(issue => issue.assignee).length;
    const completedIssues = issues.filter(issue => issue.state.name === 'Done' || issue.state.name === 'Completed').length;
    const inProgressIssues = issues.filter(issue => issue.state.name === 'In Progress').length;
    const backlogIssues = issues.filter(issue => issue.state.name === 'Backlog' || issue.state.name === 'Todo').length;

    console.log('\n📊 RESUMEN DEL CYCLE #5:');
    console.log('═'.repeat(50));
    console.log(`📋 Total de issues: ${issues.length}`);
    console.log(`📊 Total Story Points: ${totalStoryPoints}`);
    console.log(`👤 Issues asignados: ${assignedIssues}/${issues.length} (${Math.round(assignedIssues/issues.length*100)}%)`);
    console.log(`✅ Issues completados: ${completedIssues}/${issues.length} (${Math.round(completedIssues/issues.length*100)}%)`);
    console.log(`🔄 Issues en progreso: ${inProgressIssues}/${issues.length} (${Math.round(inProgressIssues/issues.length*100)}%)`);
    console.log(`📋 Issues en backlog: ${backlogIssues}/${issues.length} (${Math.round(backlogIssues/issues.length*100)}%)`);
    console.log(`📈 Promedio de puntos por issue: ${(totalStoryPoints / issues.length).toFixed(1)}`);

    // Análisis por categorías
    const categories = {
      'Testing': issues.filter(issue => issue.title.includes('TS-') || issue.labels?.nodes?.some(l => l.name.includes('testing'))),
      'Infrastructure': issues.filter(issue => issue.labels?.nodes?.some(l => l.name.includes('infrastructure'))),
      'Integration': issues.filter(issue => issue.labels?.nodes?.some(l => l.name.includes('integration'))),
      'E2E': issues.filter(issue => issue.labels?.nodes?.some(l => l.name.includes('e2e'))),
      'Documentation': issues.filter(issue => issue.labels?.nodes?.some(l => l.name.includes('documentation')))
    };

    console.log('\n🏷️  ANÁLISIS POR CATEGORÍAS:');
    console.log('─'.repeat(50));
    Object.entries(categories).forEach(([category, categoryIssues]) => {
      if (categoryIssues.length > 0) {
        const categoryPoints = categoryIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        console.log(`🔸 ${category}: ${categoryIssues.length} issues, ${categoryPoints} pts`);
      }
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('🔍 Detalles:', error);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  checkCycle5Details();
}

module.exports = { checkCycle5Details };


