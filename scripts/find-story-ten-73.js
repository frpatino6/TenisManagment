#!/usr/bin/env node

/**
 * Script para buscar la historia TEN-73
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function findStoryTEN73() {
  try {
    console.log('🔍 Buscando historia TEN-73...\n');

    // 1. Buscar la historia TEN-73 específicamente
    console.log('📋 Buscando historia TEN-73...');
    
    const getTEN73Query = `
      query {
        issues(first: 50, filter: { 
          number: { eq: 73 }
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
            labels {
              nodes {
                name
              }
            }
          }
        }
      }
    `;

    const ten73Response = await makeLinearRequest(getTEN73Query);
    const ten73Issues = ten73Response.data.issues.nodes;

    console.log(`📊 Historias encontradas con número 73: ${ten73Issues.length}`);

    if (ten73Issues.length === 0) {
      console.log('❌ No se encontró ninguna historia con número 73');
      
      // Buscar por título que contenga TEN-73
      console.log('\n🔍 Buscando por título que contenga TEN-73...');
      
      const searchByTitleQuery = `
        query {
          issues(first: 50, filter: { 
            title: { contains: "TEN-73" }
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
              labels {
                nodes {
                  name
                }
              }
            }
          }
        }
      `;

      const searchResponse = await makeLinearRequest(searchByTitleQuery);
      const searchIssues = searchResponse.data.issues.nodes;

      console.log(`📊 Historias encontradas con TEN-73 en título: ${searchIssues.length}`);

      if (searchIssues.length === 0) {
        console.log('❌ No se encontró ninguna historia con TEN-73 en el título');
        
        // Buscar todas las historias que contengan "73" en el título
        console.log('\n🔍 Buscando todas las historias que contengan "73"...');
        
        const searchAll73Query = `
          query {
            issues(first: 50, filter: { 
              title: { contains: "73" }
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
                labels {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        `;

        const all73Response = await makeLinearRequest(searchAll73Query);
        const all73Issues = all73Response.data.issues.nodes;

        console.log(`📊 Historias encontradas con "73" en título: ${all73Issues.length}`);

        if (all73Issues.length > 0) {
          console.log('\n📋 HISTORIAS CON "73" EN TÍTULO:');
          all73Issues.forEach(issue => {
            console.log(`   - ${issue.title} (#${issue.number})`);
            console.log(`     Estado: ${issue.state.name}`);
            console.log(`     Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
            console.log(`     Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
            console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
            console.log('');
          });
        } else {
          console.log('❌ No se encontró ninguna historia con "73" en el título');
        }
      } else {
        console.log('\n📋 HISTORIAS CON TEN-73 EN TÍTULO:');
        searchIssues.forEach(issue => {
          console.log(`   - ${issue.title} (#${issue.number})`);
          console.log(`     Estado: ${issue.state.name}`);
          console.log(`     Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
          console.log(`     Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
          console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
          console.log('');
        });
      }
    } else {
      console.log('\n📋 HISTORIA TEN-73 ENCONTRADA:');
      ten73Issues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number})`);
        console.log(`     Estado: ${issue.state.name}`);
        console.log(`     Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
        console.log(`     Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
        console.log(`     Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
        console.log(`     Labels: ${issue.labels.nodes.map(label => label.name).join(', ')}`);
        console.log('');
      });
    }

    // 2. Buscar en todos los sprints para verificar
    console.log('\n🔍 Verificando en todos los sprints...');
    
    const getAllSprintsQuery = `
      query {
        cycles(first: 20) {
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
              }
            }
          }
        }
      }
    `;

    const sprintsResponse = await makeLinearRequest(getAllSprintsQuery);
    const allSprints = sprintsResponse.data.cycles.nodes;

    console.log(`📊 Total sprints encontrados: ${allSprints.length}`);

    let foundInSprint = false;
    allSprints.forEach(sprint => {
      const hasIssue73 = sprint.issues.nodes.some(issue => 
        issue.number === 73 || issue.title.includes('TEN-73') || issue.title.includes('73')
      );
      
      if (hasIssue73) {
        console.log(`\n✅ ENCONTRADO EN SPRINT: ${sprint.name}`);
        console.log(`   Sprint ID: ${sprint.id}`);
        console.log(`   Sprint Number: ${sprint.number}`);
        console.log(`   Sprint State: ${sprint.state}`);
        
        const issue73 = sprint.issues.nodes.find(issue => 
          issue.number === 73 || issue.title.includes('TEN-73') || issue.title.includes('73')
        );
        
        if (issue73) {
          console.log(`   Historia: ${issue73.title} (#${issue73.number})`);
          console.log(`   Estado: ${issue73.state.name}`);
        }
        
        foundInSprint = true;
      }
    });

    if (!foundInSprint) {
      console.log('❌ La historia TEN-73 no se encontró en ningún sprint');
    }

    // 3. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    
    if (ten73Issues.length > 0) {
      const issue = ten73Issues[0];
      console.log(`📋 Historia: ${issue.title} (#${issue.number})`);
      console.log(`📊 Estado: ${issue.state.name}`);
      console.log(`🚀 Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
      console.log(`📁 Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
      console.log(`👤 Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
    } else {
      console.log('❌ Historia TEN-73 no encontrada');
      console.log('💡 Posibles causas:');
      console.log('   - La historia no existe');
      console.log('   - El número de historia es diferente');
      console.log('   - La historia está en un proyecto diferente');
      console.log('   - La historia fue eliminada');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
findStoryTEN73();
