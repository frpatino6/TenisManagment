#!/usr/bin/env node

/**
 * Script simple para corregir Sprint Testing 3
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function simpleFixSprint3() {
  try {
    console.log('🔧 Corrigiendo Sprint Testing 3...\n');

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

    // 2. Agrupar por sprint
    const sprintGroups = {};
    const unassignedIssues = [];

    allTSIssues.forEach(issue => {
      if (issue.cycle) {
        const sprintName = issue.cycle.name;
        if (!sprintGroups[sprintName]) {
          sprintGroups[sprintName] = [];
        }
        sprintGroups[sprintName].push(issue);
      } else {
        unassignedIssues.push(issue);
      }
    });

    console.log('\n📊 DISTRIBUCIÓN ACTUAL POR SPRINTS:');
    console.log('─'.repeat(60));
    
    Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
      console.log(`🚀 ${sprintName}: ${issues.length} historias`);
      issues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
      });
      console.log('');
    });

    if (unassignedIssues.length > 0) {
      console.log('❌ ISSUES SIN SPRINT:');
      unassignedIssues.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
      });
      console.log('');
    }

    // 3. Verificar específicamente el Sprint Testing 3
    const sprintTesting3Issues = sprintGroups['Sprint Testing 3 - E2E y Documentación'] || [];
    
    console.log('🎯 ANÁLISIS DEL SPRINT TESTING 3:');
    console.log('─'.repeat(60));
    console.log(`📊 Issues en Sprint Testing 3: ${sprintTesting3Issues.length}`);
    
    // 4. Definir las historias que deberían estar en Sprint 3
    const sprint3ExpectedIssues = [
      'TS-006', 'TS-023', 'TS-024', 'TS-026'
    ];

    console.log('\n📋 Historias que deberían estar en Sprint 3:');
    sprint3ExpectedIssues.forEach(tsNumber => {
      console.log(`   - ${tsNumber}`);
    });

    // 5. Encontrar las historias que deberían estar en Sprint 3
    const shouldBeInSprint3 = allTSIssues.filter(issue => 
      sprint3ExpectedIssues.some(tsNumber => issue.title.includes(tsNumber))
    );

    console.log(`\n📊 Historias encontradas para Sprint 3: ${shouldBeInSprint3.length}`);

    // 6. Verificar cuáles están correctamente asignadas
    const correctlyAssigned = shouldBeInSprint3.filter(issue => 
      issue.cycle?.name === 'Sprint Testing 3 - E2E y Documentación'
    );

    const incorrectlyAssigned = shouldBeInSprint3.filter(issue => 
      issue.cycle?.name !== 'Sprint Testing 3 - E2E y Documentación'
    );

    console.log(`✅ Correctamente asignadas: ${correctlyAssigned.length}`);
    console.log(`❌ Incorrectamente asignadas: ${incorrectlyAssigned.length}`);

    // 7. Mostrar el estado actual
    if (correctlyAssigned.length > 0) {
      console.log('\n✅ HISTORIAS CORRECTAMENTE ASIGNADAS:');
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

    // 8. Si hay historias incorrectamente asignadas, reasignarlas
    if (incorrectlyAssigned.length > 0) {
      console.log('\n🔄 Reasignando historias al Sprint Testing 3...');
      
      // Obtener el ID del Sprint Testing 3
      const sprintTesting3 = Object.keys(sprintGroups).find(sprintName => 
        sprintName === 'Sprint Testing 3 - E2E y Documentación'
      );

      if (sprintTesting3) {
        const sprint3Id = sprintGroups[sprintTesting3][0].cycle.id;
        
        let reassignedCount = 0;
        for (const issue of incorrectlyAssigned) {
          console.log(`📝 Reasignando: ${issue.title} (#${issue.number})`);
          
          const updateIssueMutation = `
            mutation {
              issueUpdate(
                id: "${issue.id}"
                input: {
                  cycleId: "${sprint3Id}"
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
      } else {
        console.log('❌ No se pudo encontrar el Sprint Testing 3');
      }
    } else {
      console.log('\n✅ Todas las historias están correctamente asignadas al Sprint Testing 3');
    }

    // 9. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`📋 Sprint Testing 3: ${sprintTesting3Issues.length} historias`);
    console.log(`🎯 Objetivo: 4 historias`);
    
    if (sprintTesting3Issues.length === 4) {
      console.log('✅ ¡Sprint Testing 3 configurado correctamente!');
    } else {
      console.log(`⚠️  Sprint necesita ${4 - sprintTesting3Issues.length} historias más`);
    }

    // 10. Mostrar distribución final
    console.log('\n📊 DISTRIBUCIÓN FINAL:');
    console.log('─'.repeat(60));
    Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
      console.log(`🚀 ${sprintName}: ${issues.length} historias`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
simpleFixSprint3();
