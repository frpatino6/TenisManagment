#!/usr/bin/env node

/**
 * Script para crear un proyecto en Linear para el sistema de mensajería
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function createMessagingProject() {
  try {
    console.log('📁 Creando proyecto para el sistema de mensajería...\n');

    const { teamId } = getLinearConfig();

    // Crear el proyecto
    const createProjectMutation = `
      mutation {
        projectCreate(input: {
          name: "Sistema de Mensajería"
          description: "Sistema completo de comunicación entre profesores y estudiantes, incluyendo chat en tiempo real, notificaciones y gestión de conversaciones."
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
    console.log('Debug - Project response:', JSON.stringify(projectResponse, null, 2));
    const project = projectResponse.data.projectCreate.project;

    console.log(`✅ Proyecto creado: ${project.name}`);
    console.log(`📅 ID: ${project.id}`);
    console.log(`🔗 URL: ${project.url}`);
    console.log(`📅 Fecha inicio: ${project.startDate}`);
    console.log(`📅 Fecha objetivo: ${project.targetDate}`);

    // Obtener todas las historias de mensajería (US-001 a US-012)
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

    // Asignar historias al proyecto
    let assignedCount = 0;
    for (const issue of messagingIssues) {
      console.log(`📝 Asignando: ${issue.title} (#${issue.number})`);
      
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
        console.log(`  ✅ Asignado a: ${updatedIssue.project.name}`);
        assignedCount++;
      } catch (error) {
        console.log(`  ⚠️  Error: ${error.message}`);
      }
    }

    console.log(`\n🎉 ¡Proyecto creado y configurado!`);
    console.log(`📊 Historias asignadas: ${assignedCount}/${messagingIssues.length}`);

    // Mostrar resumen del proyecto
    console.log('\n📋 RESUMEN DEL PROYECTO:');
    console.log('─'.repeat(60));
    console.log(`📁 Proyecto: ${project.name}`);
    console.log(`📅 Duración: ${project.startDate} → ${project.targetDate}`);
    console.log(`📊 Total de historias: ${assignedCount}`);
    
    // Calcular story points totales
    const totalStoryPoints = messagingIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
    console.log(`📊 Total de story points: ${totalStoryPoints}`);

    // Mostrar historias por sprint
    console.log('\n📅 HISTORIAS POR SPRINT:');
    
    const sprint1Issues = messagingIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      return match && parseInt(match[1]) >= 1 && parseInt(match[1]) <= 4;
    });
    
    const sprint2Issues = messagingIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      return match && parseInt(match[1]) >= 5 && parseInt(match[1]) <= 8;
    });
    
    const sprint3Issues = messagingIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      return match && parseInt(match[1]) >= 9 && parseInt(match[1]) <= 12;
    });

    console.log(`\n🏃‍♂️ Sprint 1: Backend de Mensajería (${sprint1Issues.length} historias)`);
    sprint1Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
      console.log(`  ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
    });

    console.log(`\n🏃‍♂️ Sprint 2: Frontend de Chat (${sprint2Issues.length} historias)`);
    sprint2Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
      console.log(`  ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
    });

    console.log(`\n🏃‍♂️ Sprint 3: Funcionalidades Avanzadas (${sprint3Issues.length} historias)`);
    sprint3Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
      console.log(`  ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
    });

    console.log(`\n🔗 Acceso al proyecto: ${project.url}`);

  } catch (error) {
    console.error('❌ Error creando proyecto:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
createMessagingProject();
