#!/usr/bin/env node

/**
 * Script para mover proyectos de mensajería a estado "planned"
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function moveMessagingProjectsToPlanned() {
  try {
    console.log('📋 Moviendo proyectos de mensajería a "planned"...\n');

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

    // Filtrar solo los proyectos de mensajería que creé (excluyendo el Sprint 1 que debe quedarse en progreso)
    const messagingProjectsToMove = allProjects.filter(project => 
      (project.name.toLowerCase().includes('mensajería') || 
       project.name.toLowerCase().includes('messaging') ||
       project.name.toLowerCase().includes('chat') ||
       project.name.toLowerCase().includes('notificaciones') ||
       project.name.toLowerCase().includes('estudiantes') ||
       project.name.toLowerCase().includes('testing')) &&
      !project.name.toLowerCase().includes('sprint 1') &&
      !project.name.toLowerCase().includes('backend - sistema')
    );

    console.log(`📋 Proyectos de mensajería a mover a "planned": ${messagingProjectsToMove.length}`);

    // Mover cada proyecto a estado "planned"
    let movedCount = 0;
    for (const project of messagingProjectsToMove) {
      console.log(`📝 Procesando proyecto: ${project.name}`);
      console.log(`   📅 Estado actual: ${project.state}`);
      console.log(`   📊 Issues en el proyecto: ${project.issues.nodes.length}`);
      
      // Mover proyecto a estado "planned"
      const updateMutation = `
        mutation {
          projectUpdate(id: "${project.id}", input: {
            state: "planned"
          }) {
            project {
              id
              name
              state
            }
          }
        }
      `;
      
      try {
        const updateResponse = await makeLinearRequest(updateMutation);
        const updatedProject = updateResponse.data.projectUpdate.project;
        console.log(`   ✅ Movido a: ${updatedProject.state}`);
        movedCount++;

        // Mostrar issues del proyecto
        if (project.issues.nodes.length > 0) {
          console.log(`   📋 Issues en el proyecto:`);
          project.issues.nodes.forEach(issue => {
            console.log(`     - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
          });
        }
      } catch (error) {
        console.log(`   ⚠️  Error: ${error.message}`);
      }
    }

    console.log(`\n🎉 ¡Proyectos de mensajería movidos a "planned"!`);
    console.log(`📊 Proyectos movidos: ${movedCount}/${messagingProjectsToMove.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN FINAL:');
    console.log('─'.repeat(50));
    console.log('🚀 In Progress: Backend - Sistema de Mensajería (Sprint 1)');
    console.log('📋 Planned: Proyectos de mensajería (Sprints 2 y 3)');
    console.log('📋 Backlog: Proyectos de Multi-Tenancy, Billing, etc.');
    console.log('✅ Organización perfecta para desarrollo secuencial');

  } catch (error) {
    console.error('❌ Error moviendo proyectos de mensajería:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
moveMessagingProjectsToPlanned();
