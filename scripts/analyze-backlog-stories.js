#!/usr/bin/env node

/**
 * Script para analizar historias en backlog y ver su formato actual
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function analyzeBacklogStories() {
  try {
    console.log('📋 Analizando historias en backlog...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los proyectos en backlog
    const projectsQuery = `
      query {
        projects(first: 20) {
          nodes {
            id
            name
            state
            issues {
              nodes {
                id
                title
                description
                number
                state {
                  name
                }
                labels {
                  nodes {
                    name
                    color
                  }
                }
                estimate
                priority
                url
              }
            }
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const allProjects = projectsResponse.data.projects.nodes;

    // Filtrar proyectos en backlog
    const backlogProjects = allProjects.filter(project => 
      project.state === 'backlog'
    );

    console.log(`📋 Proyectos en backlog: ${backlogProjects.length}\n`);

    let totalStories = 0;
    const storiesToUpdate = [];

    for (const project of backlogProjects) {
      console.log(`📝 Proyecto: ${project.name}`);
      console.log(`   📊 Issues: ${project.issues.nodes.length}`);
      
      if (project.issues.nodes.length > 0) {
        for (const issue of project.issues.nodes) {
          totalStories++;
          console.log(`\n   📋 Issue #${issue.number}: ${issue.title}`);
          console.log(`      📝 Descripción actual:`);
          console.log(`      ${issue.description || 'Sin descripción'}`);
          console.log(`      🏷️  Labels: ${issue.labels.nodes.map(l => l.name).join(', ') || 'Sin labels'}`);
          console.log(`      📊 Estimate: ${issue.estimate || 'Sin estimación'}`);
          console.log(`      ⚡ Priority: ${issue.priority}`);
          console.log(`      🔗 URL: ${issue.url}`);
          
          // Analizar si necesita actualización
          const needsUpdate = {
            hasDescription: !!issue.description,
            hasLabels: issue.labels.nodes.length > 0,
            hasEstimate: !!issue.estimate,
            descriptionFormat: issue.description ? issue.description.includes('## Descripción') : false,
            hasAcceptanceCriteria: issue.description ? issue.description.includes('## Criterios de Aceptación') : false
          };
          
          console.log(`      🔍 Análisis:`);
          console.log(`         - Tiene descripción: ${needsUpdate.hasDescription ? '✅' : '❌'}`);
          console.log(`         - Tiene labels: ${needsUpdate.hasLabels ? '✅' : '❌'}`);
          console.log(`         - Tiene estimación: ${needsUpdate.hasEstimate ? '✅' : '❌'}`);
          console.log(`         - Formato estándar: ${needsUpdate.descriptionFormat ? '✅' : '❌'}`);
          console.log(`         - Criterios de aceptación: ${needsUpdate.hasAcceptanceCriteria ? '✅' : '❌'}`);
          
          if (!needsUpdate.hasDescription || !needsUpdate.hasLabels || !needsUpdate.hasEstimate || 
              !needsUpdate.descriptionFormat || !needsUpdate.hasAcceptanceCriteria) {
            storiesToUpdate.push({
              id: issue.id,
              number: issue.number,
              title: issue.title,
              currentDescription: issue.description,
              project: project.name,
              needsUpdate
            });
          }
        }
      }
      console.log('\n' + '─'.repeat(60) + '\n');
    }

    console.log(`📊 RESUMEN DEL ANÁLISIS:`);
    console.log(`─`.repeat(50));
    console.log(`📋 Total de historias analizadas: ${totalStories}`);
    console.log(`🔄 Historias que necesitan actualización: ${storiesToUpdate.length}`);
    console.log(`✅ Historias ya estandarizadas: ${totalStories - storiesToUpdate.length}`);

    if (storiesToUpdate.length > 0) {
      console.log(`\n🔄 HISTORIAS A ACTUALIZAR:`);
      console.log(`─`.repeat(50));
      storiesToUpdate.forEach(story => {
        console.log(`📋 #${story.number}: ${story.title}`);
        console.log(`   📁 Proyecto: ${story.project}`);
        console.log(`   ❌ Faltan: ${Object.entries(story.needsUpdate)
          .filter(([key, value]) => !value)
          .map(([key]) => key.replace(/([A-Z])/g, ' $1').toLowerCase())
          .join(', ')}`);
      });
    }

    return storiesToUpdate;

  } catch (error) {
    console.error('❌ Error analizando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
analyzeBacklogStories();
