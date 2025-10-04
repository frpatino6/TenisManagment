#!/usr/bin/env node

/**
 * Script para corregir la visualización de issues en los sprints
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function fixSprintIssuesDisplay() {
  try {
    console.log('🔧 Corrigiendo visualización de issues en sprints...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener el sprint específico que está vacío
    console.log('📋 Obteniendo información del Sprint Testing 1...');
    
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
                state {
                  name
                }
                project {
                  name
                }
              }
            }
          }
        }
      }
    `;

    const sprintResponse = await makeLinearRequest(getSprintQuery);
    const sprints = sprintResponse.data.cycles.nodes;

    // Encontrar el sprint específico
    const sprintTesting1 = sprints.find(sprint => 
      sprint.name === 'Sprint Testing 1 - Configuración y Core'
    );

    if (!sprintTesting1) {
      console.log('❌ No se encontró el Sprint Testing 1');
      return;
    }

    console.log(`📋 Sprint encontrado: ${sprintTesting1.name} (#${sprintTesting1.number})`);
    console.log(`📊 Issues en el sprint: ${sprintTesting1.issues.nodes.length}`);

    if (sprintTesting1.issues.nodes.length > 0) {
      console.log('\n📋 Issues en el sprint:');
      sprintTesting1.issues.nodes.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    } else {
      console.log('⚠️  El sprint no tiene issues asignadas');
    }

    // 2. Obtener todas las historias TS-XXX que deberían estar en este sprint
    console.log('\n📋 Obteniendo historias TS-XXX que deberían estar en Sprint 1...');
    
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

    // Filtrar las que deberían estar en Sprint 1
    const sprint1Issues = [
      'TS-001', 'TS-002', 'TS-003', 'TS-004', 'TS-005',
      'TS-007', 'TS-008', 'TS-009', 'TS-012', 'TS-013',
      'TS-016', 'TS-017', 'TS-018', 'TS-020', 'TS-021',
      'TS-022', 'TS-025'
    ];

    const shouldBeInSprint1 = allTSIssues.filter(issue => 
      sprint1Issues.some(tsNumber => issue.title.includes(tsNumber))
    );

    console.log(`📊 Historias que deberían estar en Sprint 1: ${shouldBeInSprint1.length}`);

    // 3. Verificar cuáles están asignadas al sprint correcto
    const correctlyAssigned = shouldBeInSprint1.filter(issue => 
      issue.cycle?.id === sprintTesting1.id
    );

    const incorrectlyAssigned = shouldBeInSprint1.filter(issue => 
      issue.cycle?.id !== sprintTesting1.id
    );

    console.log(`✅ Correctamente asignadas: ${correctlyAssigned.length}`);
    console.log(`❌ Incorrectamente asignadas: ${incorrectlyAssigned.length}`);

    if (incorrectlyAssigned.length > 0) {
      console.log('\n❌ HISTORIAS INCORRECTAMENTE ASIGNADAS:');
      incorrectlyAssigned.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
        console.log(`   🚀 Sprint actual: ${issue.cycle?.name || 'Sin sprint'}`);
        console.log(`   🎯 Debería estar en: Sprint Testing 1 - Configuración y Core`);
      });

      // 4. Reasignar las historias al sprint correcto
      console.log('\n🔄 Reasignando historias al sprint correcto...');
      
      let reassignedCount = 0;
      for (const issue of incorrectlyAssigned) {
        console.log(`📝 Reasignando: ${issue.title} (#${issue.number})`);
        
        const updateIssueMutation = `
          mutation {
            issueUpdate(
              id: "${issue.id}"
              input: {
                cycleId: "${sprintTesting1.id}"
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

    // 5. Verificar el estado final
    console.log('\n🔍 Verificando estado final del sprint...');
    
    const finalSprintQuery = `
      query {
        cycle(id: "${sprintTesting1.id}") {
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

    console.log(`📊 Issues finales en Sprint 1: ${finalSprint.issues.nodes.length}`);
    
    if (finalSprint.issues.nodes.length > 0) {
      console.log('\n✅ HISTORIAS FINALES EN SPRINT 1:');
      finalSprint.issues.nodes.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    }

    // 6. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`📋 Sprint: ${finalSprint.name}`);
    console.log(`📊 Issues en el sprint: ${finalSprint.issues.nodes.length}`);
    console.log(`🎯 Objetivo: 17 historias`);
    
    if (finalSprint.issues.nodes.length === 17) {
      console.log('✅ ¡Sprint configurado correctamente!');
    } else {
      console.log(`⚠️  Sprint necesita ${17 - finalSprint.issues.nodes.length} historias más`);
    }

  } catch (error) {
    console.error('❌ Error corrigiendo sprint:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
fixSprintIssuesDisplay();
