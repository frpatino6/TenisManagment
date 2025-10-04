#!/usr/bin/env node

/**
 * Script final para verificar el estado de los sprints
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function finalSprintVerification() {
  try {
    console.log('🔍 Verificación final del estado de sprints...\n');

    const { teamId } = getLinearConfig();

    // Obtener historias de testing
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

    // Filtrar solo las historias TS-XXX (las que creamos)
    const tsIssues = testingIssues.filter(issue => issue.title.startsWith('TS-'));
    const otherIssues = testingIssues.filter(issue => !issue.title.startsWith('TS-'));

    console.log(`📊 Historias TS-XXX (nuestras): ${tsIssues.length}`);
    console.log(`📊 Otras historias de testing: ${otherIssues.length}\n`);

    // Analizar asignaciones de historias TS-XXX
    const assignedToSprint = tsIssues.filter(issue => issue.cycle !== null);
    const notAssignedToSprint = tsIssues.filter(issue => issue.cycle === null);

    console.log('📊 ANÁLISIS DE HISTORIAS TS-XXX:');
    console.log('─'.repeat(60));
    console.log(`✅ Asignadas a sprint: ${assignedToSprint.length}`);
    console.log(`❌ NO asignadas a sprint: ${notAssignedToSprint.length}`);

    if (assignedToSprint.length > 0) {
      console.log('\n✅ HISTORIAS TS-XXX ASIGNADAS A SPRINTS:');
      console.log('─'.repeat(60));
      
      // Agrupar por sprint
      const sprintGroups = {};
      assignedToSprint.forEach(issue => {
        const sprintName = issue.cycle?.name || 'Sin nombre';
        if (!sprintGroups[sprintName]) {
          sprintGroups[sprintName] = [];
        }
        sprintGroups[sprintName].push(issue);
      });

      Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
        console.log(`🚀 ${sprintName}:`);
        console.log(`   📊 Issues: ${issues.length}`);
        console.log(`   📋 Lista:`);
        issues.forEach(issue => {
          console.log(`      - ${issue.title} (#${issue.number})`);
        });
        console.log('');
      });
    }

    if (notAssignedToSprint.length > 0) {
      console.log('\n❌ HISTORIAS TS-XXX NO ASIGNADAS A SPRINTS:');
      console.log('─'.repeat(60));
      notAssignedToSprint.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
        console.log(`   📁 Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
        console.log(`   👤 Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
        console.log('');
      });
    }

    // Mostrar otras historias de testing
    if (otherIssues.length > 0) {
      console.log('\n📋 OTRAS HISTORIAS DE TESTING (no TS-XXX):');
      console.log('─'.repeat(60));
      otherIssues.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
        console.log(`   📁 Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
        console.log(`   🚀 Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
        console.log(`   👤 Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
        console.log('');
      });
    }

    // Resumen final
    console.log('🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    
    if (notAssignedToSprint.length === 0) {
      console.log('✅ TODAS LAS HISTORIAS TS-XXX ESTÁN ASIGNADAS A SPRINTS');
      console.log(`📊 Total de historias TS-XXX: ${tsIssues.length}`);
      console.log(`📊 Asignadas a sprints: ${assignedToSprint.length}`);
      
      // Calcular story points
      const totalStoryPoints = tsIssues.reduce((sum, issue) => {
        // Extraer story points del título o usar valor por defecto
        const match = issue.title.match(/\((\d+)\s*SP\)/);
        return sum + (match ? parseInt(match[1]) : 5);
      }, 0);
      
      console.log(`📊 Story Points estimados: ${totalStoryPoints}`);
      console.log(`⏱️  Estimación: ${Math.ceil(totalStoryPoints / 20)} semanas`);
    } else {
      console.log(`⚠️  HAY ${notAssignedToSprint.length} HISTORIAS TS-XXX SIN ASIGNAR A SPRINTS`);
    }

  } catch (error) {
    console.error('❌ Error en verificación final:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
finalSprintVerification();
