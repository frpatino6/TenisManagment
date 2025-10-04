#!/usr/bin/env node

/**
 * Script para verificar si las historias están asignadas a los sprints
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function verifySprintAssignments() {
  try {
    console.log('🔍 Verificando asignaciones de historias a sprints...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener todos los sprints
    console.log('📋 Obteniendo sprints...');
    
    const getSprintsQuery = `
      query {
        cycles(first: 10) {
          nodes {
            id
            name
            number
            state
            startsAt
            endsAt
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

    const sprintsResponse = await makeLinearRequest(getSprintsQuery);
    const sprints = sprintsResponse.data.cycles.nodes;

    console.log(`📋 Sprints encontrados: ${sprints.length}\n`);

    // 2. Mostrar información de cada sprint
    for (const sprint of sprints) {
      console.log(`🚀 Sprint: ${sprint.name} (#${sprint.number})`);
      console.log(`   📅 Estado: ${sprint.state}`);
      console.log(`   📊 Issues asignadas: ${sprint.issues.nodes.length}`);
      
      if (sprint.issues.nodes.length > 0) {
        console.log(`   📋 Issues:`);
        sprint.issues.nodes.forEach(issue => {
          console.log(`      - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
        });
      } else {
        console.log(`   ⚠️  No hay issues asignadas a este sprint`);
      }
      console.log('');
    }

    // 3. Obtener todas las historias de testing
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

    // 4. Analizar asignaciones
    const assignedToSprint = testingIssues.filter(issue => issue.cycle !== null);
    const notAssignedToSprint = testingIssues.filter(issue => issue.cycle === null);

    console.log('📊 ANÁLISIS DE ASIGNACIONES:');
    console.log('─'.repeat(60));
    console.log(`✅ Asignadas a sprint: ${assignedToSprint.length}`);
    console.log(`❌ NO asignadas a sprint: ${notAssignedToSprint.length}`);

    if (assignedToSprint.length > 0) {
      console.log('\n✅ HISTORIAS ASIGNADAS A SPRINTS:');
      console.log('─'.repeat(60));
      assignedToSprint.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
        console.log(`   🚀 Sprint: ${issue.cycle.name} (#${issue.cycle.number})`);
        console.log(`   📁 Proyecto: ${issue.project.name}`);
        console.log(`   👤 Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
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

    // 5. Resumen por sprint
    console.log('📊 RESUMEN POR SPRINT:');
    console.log('─'.repeat(60));
    
    const sprintSummary = {};
    assignedToSprint.forEach(issue => {
      const sprintName = issue.cycle.name;
      if (!sprintSummary[sprintName]) {
        sprintSummary[sprintName] = {
          count: 0,
          issues: []
        };
      }
      sprintSummary[sprintName].count++;
      sprintSummary[sprintName].issues.push(issue);
    });

    Object.entries(sprintSummary).forEach(([sprintName, data]) => {
      console.log(`🚀 ${sprintName}:`);
      console.log(`   📊 Issues: ${data.count}`);
      console.log(`   📋 Lista:`);
      data.issues.forEach(issue => {
        console.log(`      - ${issue.title} (#${issue.number})`);
      });
      console.log('');
    });

    // 6. Verificar si hay problemas
    if (notAssignedToSprint.length > 0) {
      console.log('⚠️  PROBLEMA DETECTADO:');
      console.log('─'.repeat(60));
      console.log(`Hay ${notAssignedToSprint.length} historias de testing que NO están asignadas a ningún sprint.`);
      console.log('Esto significa que el script anterior no funcionó correctamente.');
      console.log('');
      console.log('💡 SOLUCIÓN:');
      console.log('Ejecutar el script de asignación nuevamente o asignar manualmente.');
    } else {
      console.log('✅ TODAS LAS HISTORIAS ESTÁN ASIGNADAS A SPRINTS');
    }

  } catch (error) {
    console.error('❌ Error verificando asignaciones:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
verifySprintAssignments();
