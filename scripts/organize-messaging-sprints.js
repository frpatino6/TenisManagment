#!/usr/bin/env node

/**
 * Script para organizar las historias de mensajería en sprints
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Definir los sprints y sus historias
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

async function organizeMessagingSprints() {
  try {
    console.log('🚀 Organizando historias de mensajería en sprints...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los issues
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            state {
              id
              name
            }
            team {
              id
              name
            }
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

    console.log(`📋 Encontradas ${messagingIssues.length} historias de mensajería`);

    // Obtener estados disponibles
    const statesQuery = `
      query {
        workflowStates(first: 20) {
          nodes {
            id
            name
            type
            team {
              id
            }
          }
        }
      }
    `;

    const statesResponse = await makeLinearRequest(statesQuery);
    const states = statesResponse.data.workflowStates.nodes.filter(
      state => state.team.id === teamId
    );

    // Mapear estados por tipo
    const stateMap = {};
    states.forEach(state => {
      stateMap[state.type] = state.id;
    });

    console.log('📊 Estados disponibles:');
    Object.entries(stateMap).forEach(([type, id]) => {
      console.log(`  - ${type}: ${id}`);
    });

    // Organizar por sprints
    for (const [sprintName, storyTitles] of Object.entries(sprintOrganization)) {
      console.log(`\n📅 Organizando: ${sprintName}`);
      
      for (const storyTitle of storyTitles) {
        const issue = messagingIssues.find(issue => issue.title === storyTitle);
        
        if (issue) {
          console.log(`  📝 ${issue.title} (#${issue.number})`);
          
          // Mover a estado "In Progress" si está en "Todo"
          if (issue.state.name === 'Todo' || issue.state.name === 'Backlog') {
            const updateMutation = `
              mutation {
                issueUpdate(id: "${issue.id}", input: {
                  stateId: "${stateMap.IN_PROGRESS || stateMap.STARTED}"
                }) {
                  issue {
                    id
                    title
                    state {
                      name
                    }
                  }
                }
              }
            `;
            
            try {
              const updateResponse = await makeLinearRequest(updateMutation);
              const updatedIssue = updateResponse.data.issueUpdate.issue;
              console.log(`    ✅ Movido a: ${updatedIssue.state.name}`);
            } catch (error) {
              console.log(`    ⚠️  No se pudo mover: ${error.message}`);
            }
          } else {
            console.log(`    ℹ️  Ya en estado: ${issue.state.name}`);
          }
        } else {
          console.log(`  ❌ No encontrado: ${storyTitle}`);
        }
      }
    }

    console.log('\n🎉 ¡Organización de sprints completada!');
    console.log('\n📊 Resumen de Sprints:');
    Object.entries(sprintOrganization).forEach(([sprint, stories]) => {
      console.log(`- ${sprint}: ${stories.length} historias`);
    });

  } catch (error) {
    console.error('❌ Error organizando sprints:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
organizeMessagingSprints();
