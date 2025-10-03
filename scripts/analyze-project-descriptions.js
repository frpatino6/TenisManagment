#!/usr/bin/env node

/**
 * Script para analizar descripciones de proyectos
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function analyzeProjectDescriptions() {
  try {
    console.log('📋 Analizando descripciones de proyectos...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los proyectos
    const projectsQuery = `
      query {
        projects(first: 20) {
          nodes {
            id
            name
            description
            state
            startDate
            targetDate
            url
            issues {
              nodes {
                id
                title
                number
                state {
                  name
                }
              }
            }
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const allProjects = projectsResponse.data.projects.nodes;

    console.log(`📋 Proyectos analizados: ${allProjects.length}\n`);

    const projectsToUpdate = [];

    for (const project of allProjects) {
      console.log(`📝 Proyecto: ${project.name}`);
      console.log(`   📅 Estado: ${project.state}`);
      console.log(`   📊 Issues: ${project.issues.nodes.length}`);
      console.log(`   📝 Descripción actual:`);
      console.log(`   ${project.description || 'Sin descripción'}`);
      
      // Analizar si necesita descripción
      const needsDescription = !project.description || 
                              project.description.length < 100 ||
                              !project.description.includes('## Objetivo') ||
                              !project.description.includes('## Alcance');
      
      console.log(`   🔍 Necesita descripción: ${needsDescription ? '❌ SÍ' : '✅ NO'}`);
      
      if (needsDescription) {
        projectsToUpdate.push({
          id: project.id,
          name: project.name,
          state: project.state,
          currentDescription: project.description,
          issuesCount: project.issues.nodes.length
        });
      }
      
      console.log('\n' + '─'.repeat(60) + '\n');
    }

    console.log(`📊 RESUMEN DEL ANÁLISIS:`);
    console.log(`─`.repeat(50));
    console.log(`📋 Total de proyectos: ${allProjects.length}`);
    console.log(`🔄 Proyectos que necesitan descripción: ${projectsToUpdate.length}`);
    console.log(`✅ Proyectos con descripción completa: ${allProjects.length - projectsToUpdate.length}`);

    if (projectsToUpdate.length > 0) {
      console.log(`\n🔄 PROYECTOS A ACTUALIZAR:`);
      console.log(`─`.repeat(50));
      projectsToUpdate.forEach(project => {
        console.log(`📋 ${project.name}`);
        console.log(`   📅 Estado: ${project.state}`);
        console.log(`   📊 Issues: ${project.issuesCount}`);
        console.log(`   📝 Descripción actual: ${project.currentDescription ? 'Parcial' : 'Sin descripción'}`);
      });
    }

    return projectsToUpdate;

  } catch (error) {
    console.error('❌ Error analizando proyectos:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
analyzeProjectDescriptions();
