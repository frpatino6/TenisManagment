#!/usr/bin/env node

/**
 * Script simple para verificar el estado de los sprints y asignaciones
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function checkSprintStatus() {
  try {
    console.log('🔍 Verificando estado de sprints y asignaciones...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener historias de testing
    console.log('📋 Obteniendo historias de testing...');
    
    const getTestingIssuesQuery = `
      query {
        issues(first: 50, filter: { 
          labels: { name: { eq: "testing" } }
        }) {
          nodes {
            id
            title
            number
            state {
              name
            }
            cycle {
              id
              name
              number
            }
            project {
              name
            }
            assignee {
              name
            }
          }
        }
      }
    `;

    const testingIssuesResponse = await makeLinearRequest(getTestingIssuesQuery);
    const testingIssues = testingIssuesResponse.data.issues.nodes;

    console.log(`📋 Historias de testing encontradas: ${testingIssues.length}\n`);

    // 2. Analizar asignaciones
    const assignedToSprint = testingIssues.filter(issue => issue.cycle !== null);
    const notAssignedToSprint = testingIssues.filter(issue => issue.cycle === null);

    console.log('📊 ANÁLISIS DE ASIGNACIONES:');
    console.log('─'.repeat(60));
    console.log(`✅ Asignadas a sprint: ${assignedToSprint.length}`);
    console.log(`❌ NO asignadas a sprint: ${notAssignedToSprint.length}`);

    if (assignedToSprint.length > 0) {
      console.log('\n✅ HISTORIAS ASIGNADAS A SPRINTS:');
      console.log('─'.repeat(60));
      
      // Agrupar por sprint
      const sprintGroups = {};
      assignedToSprint.forEach(issue => {
        const sprintName = issue.cycle.name;
        if (!sprintGroups[sprintName]) {
          sprintGroups[sprintName] = [];
        }
        sprintGroups[sprintName].push(issue);
      });

      Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
        console.log(`🚀 ${sprintName}:`);
        console.log(`   📊 Issues: ${issues.length}`);
        issues.forEach(issue => {
          console.log(`      - ${issue.title} (#${issue.number})`);
        });
        console.log('');
      });
    }

    if (notAssignedToSprint.length > 0) {
      console.log('\n❌ HISTORIAS NO ASIGNADAS A SPRINTS:');
      console.log('─'.repeat(60));
      notAssignedToSprint.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
        console.log(`   📁 Proyecto: ${issue.project.name}`);
        console.log(`   👤 Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
        console.log(`   ⚠️  NO está en ningún sprint`);
        console.log('');
      });
    }

    // 3. Verificar si hay problemas
    if (notAssignedToSprint.length > 0) {
      console.log('⚠️  PROBLEMA DETECTADO:');
      console.log('─'.repeat(60));
      console.log(`Hay ${notAssignedToSprint.length} historias de testing que NO están asignadas a ningún sprint.`);
      console.log('Esto significa que el script anterior no funcionó correctamente.');
      console.log('');
      console.log('💡 SOLUCIÓN:');
      console.log('Necesitamos ejecutar el script de asignación nuevamente.');
      
      return {
        hasIssues: true,
        notAssigned: notAssignedToSprint,
        assigned: assignedToSprint
      };
    } else {
      console.log('✅ TODAS LAS HISTORIAS ESTÁN ASIGNADAS A SPRINTS');
      return {
        hasIssues: false,
        assigned: assignedToSprint
      };
    }

  } catch (error) {
    console.error('❌ Error verificando estado:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
checkSprintStatus();
