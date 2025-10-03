#!/usr/bin/env node

/**
 * Script para crear proyectos detallados del sistema de mensajería
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function createDetailedMessagingProjects() {
  try {
    console.log('📁 Creando proyectos detallados del sistema de mensajería...\n');

    const { teamId } = getLinearConfig();

    // Definir los proyectos detallados
    const projects = [
      {
        name: "Backend - Sistema de Mensajería",
        description: "APIs y modelos de datos para el sistema de mensajería entre profesores y estudiantes.",
        issues: ["US-001", "US-002", "US-003", "US-004", "US-010"],
        color: "#3B82F6" // Azul
      },
      {
        name: "Frontend - Chat y Comunicación", 
        description: "Interfaces de usuario para chat, conversaciones y comunicación en tiempo real.",
        issues: ["US-005", "US-006", "US-007", "US-008"],
        color: "#10B981" // Verde
      },
      {
        name: "Notificaciones y Tiempo Real",
        description: "Sistema de notificaciones push y comunicación en tiempo real.",
        issues: ["US-009"],
        color: "#F59E0B" // Amarillo
      },
      {
        name: "Gestión de Estudiantes",
        description: "Funcionalidades para gestión y seguimiento de estudiantes.",
        issues: ["US-011"],
        color: "#8B5CF6" // Púrpura
      },
      {
        name: "Testing y Optimización",
        description: "Testing, optimización y documentación del sistema de mensajería.",
        issues: ["US-012"],
        color: "#EF4444" // Rojo
      }
    ];

    const createdProjects = [];

    // Crear cada proyecto
    for (const projectData of projects) {
      console.log(`📁 Creando proyecto: ${projectData.name}`);
      
      const createProjectMutation = `
        mutation {
          projectCreate(input: {
            name: "${projectData.name}"
            description: "${projectData.description}"
            teamIds: ["${teamId}"]
            state: "planned"
            startDate: "${new Date().toISOString().split('T')[0]}"
            targetDate: "${new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]}"
          }) {
            project {
              id
              name
              description
              state
              startDate
              targetDate
              url
            }
          }
        }
      `;

      const projectResponse = await makeLinearRequest(createProjectMutation);
      const project = projectResponse.data.projectCreate.project;
      
      createdProjects.push({
        ...project,
        issues: projectData.issues,
        color: projectData.color
      });

      console.log(`  ✅ Creado: ${project.name}`);
      console.log(`  🔗 URL: ${project.url}`);
    }

    console.log(`\n📊 Total de proyectos creados: ${createdProjects.length}`);

    // Obtener todas las historias de mensajería
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            state {
              name
            }
            estimate
            priority
            labels {
              nodes {
                name
              }
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

    console.log(`\n📋 Encontradas ${messagingIssues.length} historias de mensajería`);

    // Asignar historias a sus proyectos correspondientes
    let totalAssigned = 0;
    
    for (const project of createdProjects) {
      console.log(`\n📝 Asignando historias a: ${project.name}`);
      
      const projectIssues = messagingIssues.filter(issue => {
        const match = issue.title.match(/US-(\d{3}):/);
        if (match) {
          const issueNumber = `US-${match[1]}`;
          return project.issues.includes(issueNumber);
        }
        return false;
      });

      console.log(`  📊 Historias a asignar: ${projectIssues.length}`);

      for (const issue of projectIssues) {
        console.log(`  📝 Asignando: ${issue.title} (#${issue.number})`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              projectId: "${project.id}"
            }) {
              issue {
                id
                title
                project {
                  name
                }
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          console.log(`    ✅ Asignado a: ${updatedIssue.project.name}`);
          totalAssigned++;
        } catch (error) {
          console.log(`    ⚠️  Error: ${error.message}`);
        }
      }
    }

    console.log(`\n🎉 ¡Proyectos detallados creados y configurados!`);
    console.log(`📊 Total de historias asignadas: ${totalAssigned}/${messagingIssues.length}`);

    // Mostrar resumen detallado
    console.log('\n📋 RESUMEN DE PROYECTOS DETALLADOS:');
    console.log('═'.repeat(80));
    
    for (const project of createdProjects) {
      const projectIssues = messagingIssues.filter(issue => {
        const match = issue.title.match(/US-(\d{3}):/);
        if (match) {
          const issueNumber = `US-${match[1]}`;
          return project.issues.includes(issueNumber);
        }
        return false;
      });

      const totalStoryPoints = projectIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
      
      console.log(`\n📁 ${project.name}`);
      console.log(`   📅 Duración: ${project.startDate} → ${project.targetDate}`);
      console.log(`   📊 Historias: ${projectIssues.length} | Story Points: ${totalStoryPoints}`);
      console.log(`   🔗 URL: ${project.url}`);
      
      if (projectIssues.length > 0) {
        console.log(`   📝 Historias:`);
        projectIssues.forEach(issue => {
          const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
          console.log(`     ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
        });
      }
    }

    console.log('\n🎯 BENEFICIOS DE LA ORGANIZACIÓN DETALLADA:');
    console.log('─'.repeat(50));
    console.log('✅ Separación clara entre backend y frontend');
    console.log('✅ Proyectos más manejables y enfocados');
    console.log('✅ Mejor tracking del progreso por área');
    console.log('✅ Asignación de responsables más específica');
    console.log('✅ Milestones más claros y alcanzables');

  } catch (error) {
    console.error('❌ Error creando proyectos detallados:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
createDetailedMessagingProjects();
