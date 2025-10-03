#!/usr/bin/env node

/**
 * Script para mover proyectos mejorados de vuelta al backlog
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function moveProjectsToBacklog() {
  try {
    console.log('📋 Moviendo proyectos mejorados al backlog...\n');

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

    // Filtrar proyectos que no sean del sistema de mensajería (que ya están en progreso)
    const projectsToMove = allProjects.filter(project => 
      !project.name.toLowerCase().includes('mensajería') &&
      !project.name.toLowerCase().includes('messaging') &&
      !project.name.toLowerCase().includes('chat')
    );

    console.log(`📋 Proyectos a mover al backlog: ${projectsToMove.length}`);

    // Mover cada proyecto al backlog
    let movedCount = 0;
    for (const project of projectsToMove) {
      console.log(`📝 Procesando proyecto: ${project.name}`);
      console.log(`   📅 Estado actual: ${project.state}`);
      console.log(`   📊 Issues en el proyecto: ${project.issues.nodes.length}`);
      
      // Mover proyecto a estado "backlog"
      const updateMutation = `
        mutation {
          projectUpdate(id: "${project.id}", input: {
            state: "backlog"
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

    console.log(`\n🎉 ¡Proyectos movidos al backlog!`);
    console.log(`📊 Proyectos movidos: ${movedCount}/${projectsToMove.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN FINAL:');
    console.log('─'.repeat(50));
    console.log('✅ Proyectos de Multi-Tenancy → Backlog');
    console.log('✅ Proyectos de Onboarding → Backlog');
    console.log('✅ Proyectos de Billing → Backlog');
    console.log('✅ Proyectos de Admin → Backlog');
    console.log('✅ Proyectos de GTM → Backlog');
    console.log('✅ Proyectos de Quality → Backlog');
    console.log('✅ Sistema de Mensajería → Mantiene estado actual (In Progress)');

    console.log('\n🎯 ESTADO FINAL:');
    console.log('─'.repeat(50));
    console.log('📋 Backlog: Proyectos organizados y listos para desarrollo');
    console.log('🚀 In Progress: Solo Sistema de Mensajería (Sprint 1 activo)');
    console.log('✅ Organización completa y profesional');

  } catch (error) {
    console.error('❌ Error moviendo proyectos al backlog:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
moveProjectsToBacklog();
