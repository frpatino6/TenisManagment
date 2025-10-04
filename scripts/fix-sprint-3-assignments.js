#!/usr/bin/env node

/**
 * Script para corregir las asignaciones del Sprint Testing 3
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function fixSprint3Assignments() {
  try {
    console.log('🔧 Corrigiendo asignaciones del Sprint Testing 3...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener todas las historias TS-XXX
    console.log('📋 Obteniendo historias TS-XXX...');
    
    const getTSIssuesQuery = `
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
          }
        }
      }
    `;

    const tsIssuesResponse = await makeLinearRequest(getTSIssuesQuery);
    const allTSIssues = tsIssuesResponse.data.issues.nodes.filter(issue => 
      issue.title.startsWith('TS-')
    );

    console.log(`📊 Total historias TS-XXX: ${allTSIssues.length}`);

    // 2. Obtener el Sprint Testing 3
    console.log('\n📋 Obteniendo Sprint Testing 3...');
    
    const getSprintQuery = `
      query {
        cycles(first: 10) {
          nodes {
            id
            name
            number
            state
            issues {
              nodes {
                id
                title
                number
              }
            }
          }
        }
      }
    `;

    const sprintResponse = await makeLinearRequest(getSprintQuery);
    const sprints = sprintResponse.data.cycles.nodes;

    const sprintTesting3 = sprints.find(sprint => 
      sprint.name === 'Sprint Testing 3 - E2E y Documentación'
    );

    if (!sprintTesting3) {
      console.log('❌ No se encontró el Sprint Testing 3');
      return;
    }

    console.log(`📋 Sprint encontrado: ${sprintTesting3.name} (#${sprintTesting3.number})`);
    console.log(`📊 Issues actuales en el sprint: ${sprintTesting3.issues.nodes.length}`);

    // 3. Definir las historias que deberían estar en Sprint 3
    const sprint3ExpectedIssues = [
      'TS-006', 'TS-023', 'TS-024', 'TS-026'
    ];

    console.log('\n📋 Historias que deberían estar en Sprint 3:');
    sprint3ExpectedIssues.forEach(tsNumber => {
      console.log(`   - ${tsNumber}`);
    });

    // 4. Encontrar las historias que deberían estar en Sprint 3
    const shouldBeInSprint3 = allTSIssues.filter(issue => 
      sprint3ExpectedIssues.some(tsNumber => issue.title.includes(tsNumber))
    );

    console.log(`\n📊 Historias encontradas para Sprint 3: ${shouldBeInSprint3.length}`);

    // 5. Verificar cuáles están correctamente asignadas
    const correctlyAssigned = shouldBeInSprint3.filter(issue => 
      issue.cycle?.id === sprintTesting3.id
    );

    const incorrectlyAssigned = shouldBeInSprint3.filter(issue => 
      issue.cycle?.id !== sprintTesting3.id
    );

    console.log(`✅ Correctamente asignadas: ${correctlyAssigned.length}`);
    console.log(`❌ Incorrectamente asignadas: ${incorrectlyAssigned.length}`);

    // 6. Mostrar el estado actual
    console.log('\n📊 ESTADO ACTUAL:');
    console.log('─'.repeat(60));
    
    if (correctlyAssigned.length > 0) {
      console.log('✅ HISTORIAS CORRECTAMENTE ASIGNADAS:');
      correctlyAssigned.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    }

    if (incorrectlyAssigned.length > 0) {
      console.log('\n❌ HISTORIAS INCORRECTAMENTE ASIGNADAS:');
      incorrectlyAssigned.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
        console.log(`     Sprint actual: ${issue.cycle?.name || 'Sin sprint'}`);
        console.log(`     Debería estar en: Sprint Testing 3 - E2E y Documentación`);
      });
    }

    // 7. Reasignar las historias incorrectas
    if (incorrectlyAssigned.length > 0) {
      console.log('\n🔄 Reasignando historias al Sprint Testing 3...');
      
      let reassignedCount = 0;
      for (const issue of incorrectlyAssigned) {
        console.log(`📝 Reasignando: ${issue.title} (#${issue.number})`);
        
        const updateIssueMutation = `
          mutation {
            issueUpdate(
              id: "${issue.id}"
              input: {
                cycleId: "${sprintTesting3.id}"
              }
            ) {
              success
              issue {
                id
                title
                number
                cycle {
                  name
                }
              }
            }
          }
        `;

        try {
          const updateResponse = await makeLinearRequest(updateIssueMutation);
          
          if (updateResponse.data.issueUpdate?.success) {
            const updatedIssue = updateResponse.data.issueUpdate.issue;
            console.log(`   ✅ Reasignado a: ${updatedIssue.cycle.name}`);
            reassignedCount++;
          } else {
            console.log(`   ❌ Error reasignando: ${issue.title}`);
          }
        } catch (error) {
          console.log(`   ❌ Error: ${error.message}`);
        }
      }

      console.log(`\n🎉 Reasignación completada: ${reassignedCount}/${incorrectlyAssigned.length} historias`);
    }

    // 8. Verificar el estado final
    console.log('\n🔍 Verificando estado final del Sprint Testing 3...');
    
    const finalSprintQuery = `
      query {
        cycle(id: "${sprintTesting3.id}") {
          id
          name
          number
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
    `;

    const finalResponse = await makeLinearRequest(finalSprintQuery);
    const finalSprint = finalResponse.data.cycle;

    console.log(`📊 Issues finales en Sprint 3: ${finalSprint.issues.nodes.length}`);
    
    if (finalSprint.issues.nodes.length > 0) {
      console.log('\n✅ HISTORIAS FINALES EN SPRINT TESTING 3:');
      finalSprint.issues.nodes.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    }

    // 9. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`📋 Sprint: ${finalSprint.name}`);
    console.log(`📊 Issues en el sprint: ${finalSprint.issues.nodes.length}`);
    console.log(`🎯 Objetivo: 4 historias`);
    
    if (finalSprint.issues.nodes.length === 4) {
      console.log('✅ ¡Sprint Testing 3 configurado correctamente!');
    } else {
      console.log(`⚠️  Sprint necesita ${4 - finalSprint.issues.nodes.length} historias más`);
    }

    // 10. Verificar distribución final de todos los sprints
    console.log('\n📊 DISTRIBUCIÓN FINAL DE TODOS LOS SPRINTS:');
    console.log('─'.repeat(60));
    
    const sprintGroups = {};
    allTSIssues.forEach(issue => {
      if (issue.cycle) {
        const sprintName = issue.cycle.name;
        if (!sprintGroups[sprintName]) {
          sprintGroups[sprintName] = [];
        }
        sprintGroups[sprintName].push(issue);
      }
    });

    Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
      console.log(`🚀 ${sprintName}: ${issues.length} historias`);
    });

  } catch (error) {
    console.error('❌ Error corrigiendo Sprint 3:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
fixSprint3Assignments();
