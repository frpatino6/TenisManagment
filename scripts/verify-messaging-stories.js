#!/usr/bin/env node

/**
 * Script para verificar las historias de mensajería creadas
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function verifyMessagingStories() {
  try {
    console.log('🔍 Verificando historias de mensajería creadas...\n');

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
            state {
              id
              name
            }
            priority
            estimate
            labels {
              nodes {
                name
              }
            }
            createdAt
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar solo las historias de mensajería (US-001 a US-012)
    const messagingIssues = allIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      if (match) {
        const number = parseInt(match[1]);
        return number >= 1 && number <= 12;
      }
      return false;
    });

    console.log(`📋 Historias de mensajería encontradas: ${messagingIssues.length}\n`);

    // Organizar por sprints
    const sprintOrganization = {
      "Sprint 1: Backend de Mensajería": [
        "US-001: Modelo de Datos de Mensajes",
        "US-002: API de Envío de Mensajes", 
        "US-003: API de Conversaciones",
        "US-004: API de Historial de Mensajes"
      ],
      "Sprint 2: Frontend de Chat": [
        "US-005: Pantalla de Lista de Conversaciones",
        "US-006: Pantalla de Chat Individual",
        "US-007: Integración con Perfil de Estudiante",
        "US-008: Estados de Carga y Error"
      ],
      "Sprint 3: Funcionalidades Avanzadas": [
        "US-009: Notificaciones en Tiempo Real",
        "US-010: API de Historial de Clases del Estudiante",
        "US-011: Pantalla de Historial de Clases",
        "US-012: Optimizaciones y Testing"
      ]
    };

    let totalPoints = 0;
    let totalStories = 0;

    for (const [sprintName, storyTitles] of Object.entries(sprintOrganization)) {
      console.log(`📅 ${sprintName}`);
      console.log('─'.repeat(50));
      
      let sprintPoints = 0;
      let sprintStories = 0;

      for (const storyTitle of storyTitles) {
        const issue = messagingIssues.find(issue => issue.title === storyTitle);
        
        if (issue) {
          const labels = issue.labels.nodes.map(label => label.name).join(', ');
          const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                              issue.priority === 2 ? '⚡ High' : 
                              issue.priority === 3 ? '💡 Medium' : '📝 Low';
          
          console.log(`  ✅ ${issue.title}`);
          console.log(`     #${issue.number} | ${priorityText} | ${issue.estimate} pts | ${issue.state.name}`);
          console.log(`     Labels: ${labels}`);
          console.log(`     URL: ${issue.url}`);
          console.log('');
          
          sprintPoints += issue.estimate || 0;
          sprintStories++;
        } else {
          console.log(`  ❌ ${storyTitle} - NO ENCONTRADO`);
          console.log('');
        }
      }
      
      console.log(`📊 Sprint: ${sprintStories} historias, ${sprintPoints} story points\n`);
      totalPoints += sprintPoints;
      totalStories += sprintStories;
    }

    console.log('🎯 RESUMEN GENERAL');
    console.log('═'.repeat(50));
    console.log(`📋 Total de historias: ${totalStories}/12`);
    console.log(`📊 Total de story points: ${totalPoints}/45`);
    console.log(`📅 Sprints organizados: 3`);
    
    if (totalStories === 12) {
      console.log('\n🎉 ¡Todas las historias de mensajería han sido creadas exitosamente!');
    } else {
      console.log(`\n⚠️  Faltan ${12 - totalStories} historias por crear`);
    }

    // Mostrar historias recientes
    console.log('\n🕒 HISTORIAS MÁS RECIENTES:');
    console.log('─'.repeat(50));
    const recentIssues = messagingIssues
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5);
    
    recentIssues.forEach(issue => {
      const createdDate = new Date(issue.createdAt).toLocaleString();
      console.log(`  ${issue.title} (#${issue.number}) - ${createdDate}`);
    });

  } catch (error) {
    console.error('❌ Error verificando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
verifyMessagingStories();
