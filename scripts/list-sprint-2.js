#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function listSprint2Stories() {
  console.log('🔍 Buscando historias del Sprint 2...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Obtener todos los issues
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            url
            description
            assignee {
              id
              name
              email
            }
            estimate
            priority
            state {
              id
              name
              type
            }
            team {
              id
              name
            }
            labels {
              nodes {
                name
              }
            }
            createdAt
            updatedAt
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;
    
    // Filtrar issues del Sprint 2
    const sprint2Issues = allIssues.filter(issue => {
      if (!issue.description) return false;
      return issue.description.includes('Sprint: 2') || issue.description.includes('Sprint 2');
    });

    if (sprint2Issues.length === 0) {
      console.log('❌ No se encontraron historias para el Sprint 2');
      console.log('\n🔍 Buscando en todas las historias...');
      
      // Mostrar todas las historias para referencia
      allIssues.forEach(issue => {
        if (issue.description && issue.description.includes('Sprint:')) {
          const sprintMatch = issue.description.match(/Sprint:\s*(\d+)/);
          if (sprintMatch) {
            console.log(`📋 Issue #${issue.number}: ${issue.title} - Sprint: ${sprintMatch[1]}`);
          }
        }
      });
      return;
    }

    console.log(`📋 Historias encontradas en Sprint 2: ${sprint2Issues.length}\n`);

    sprint2Issues.forEach(issue => {
      console.log(`📋 Issue #${issue.number}: ${issue.title}`);
      console.log(`   📝 Estado: ${issue.state?.name || 'Sin estado'}`);
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
      }
      
      console.log('   ────────────────────────────────────────────────────────────');
    });

    // Resumen
    const totalStoryPoints = sprint2Issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
    const assignedIssues = sprint2Issues.filter(issue => issue.assignee).length;
    
    console.log('\n📊 RESUMEN DEL SPRINT 2:');
    console.log(`   📋 Total de historias: ${sprint2Issues.length}`);
    console.log(`   📊 Total Story Points: ${totalStoryPoints}`);
    console.log(`   👤 Historias asignadas: ${assignedIssues}/${sprint2Issues.length}`);
    console.log(`   📈 Promedio de puntos por historia: ${(totalStoryPoints / sprint2Issues.length).toFixed(1)}`);

  } catch (error) {
    console.error('❌ Error al buscar historias del Sprint 2:', error.message);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  listSprint2Stories();
}

module.exports = { listSprint2Stories };
