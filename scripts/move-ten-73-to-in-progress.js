#!/usr/bin/env node

/**
 * Script para mover TEN-73 a estado In Progress
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function moveTEN73ToInProgress() {
  try {
    console.log('🚀 Moviendo TEN-73 a estado In Progress...\n');

    // 1. Buscar la historia TEN-73
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
              id
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
              id
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

    if (ten73Issues.length === 0) {
      console.log('❌ No se encontró la historia TEN-73');
      return;
    }

    const ten73Issue = ten73Issues[0];
    console.log(`✅ Historia encontrada: ${ten73Issue.title} (#${ten73Issue.number})`);
    console.log(`   Estado actual: ${ten73Issue.state.name}`);
    console.log(`   Sprint: ${ten73Issue.cycle?.name || 'Sin sprint'}`);
    console.log(`   Asignado a: ${ten73Issue.assignee?.name || 'Sin asignar'}`);

    // 2. Obtener el estado "In Progress"
    console.log('\n📋 Obteniendo estado "In Progress"...');
    
    const getStatesQuery = `
      query {
        workflowStates(first: 20) {
          nodes {
            id
            name
            type
          }
        }
      }
    `;

    const statesResponse = await makeLinearRequest(getStatesQuery);
    const inProgressState = statesResponse.data.workflowStates.nodes.find(
      state => state.name === 'In Progress'
    );

    if (!inProgressState) {
      console.log('❌ No se encontró el estado "In Progress"');
      return;
    }

    console.log(`✅ Estado "In Progress" encontrado: ${inProgressState.name}`);

    // 3. Obtener el usuario actual
    console.log('\n👤 Obteniendo usuario actual...');
    
    const getCurrentUserQuery = `
      query {
        viewer {
          id
          name
          email
        }
      }
    `;

    const userResponse = await makeLinearRequest(getCurrentUserQuery);
    const currentUser = userResponse.data.viewer;

    console.log(`👤 Usuario actual: ${currentUser.name}`);

    // 4. Mover la historia a "In Progress"
    console.log('\n📝 Moviendo TEN-73 a "In Progress"...');
    
    const updateIssueMutation = `
      mutation {
        issueUpdate(
          id: "${ten73Issue.id}"
          input: {
            stateId: "${inProgressState.id}"
            assigneeId: "${currentUser.id}"
          }
        ) {
          success
          issue {
            id
            title
            number
            state {
              name
            }
            cycle {
              name
            }
            assignee {
              name
            }
            project {
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
        console.log(`✅ Historia movida exitosamente!`);
        console.log(`   Título: ${updatedIssue.title} (#${updatedIssue.number})`);
        console.log(`   Estado: ${updatedIssue.state.name}`);
        console.log(`   Sprint: ${updatedIssue.cycle.name}`);
        console.log(`   Asignado a: ${updatedIssue.assignee.name}`);
        console.log(`   Proyecto: ${updatedIssue.project.name}`);
      } else {
        console.log(`❌ Error moviendo la historia`);
      }
    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
    }

    // 5. Verificar el estado final
    console.log('\n🔍 Verificando estado final...');
    
    const finalQuery = `
      query {
        issue(id: "${ten73Issue.id}") {
          id
          title
          number
          state {
            name
          }
          cycle {
            name
          }
          assignee {
            name
          }
          project {
            name
          }
        }
      }
    `;

    const finalResponse = await makeLinearRequest(finalQuery);
    const finalIssue = finalResponse.data.issue;

    console.log('\n📊 ESTADO FINAL:');
    console.log('─'.repeat(60));
    console.log(`📋 Historia: ${finalIssue.title} (#${finalIssue.number})`);
    console.log(`📊 Estado: ${finalIssue.state.name}`);
    console.log(`🚀 Sprint: ${finalIssue.cycle.name}`);
    console.log(`👤 Asignado a: ${finalIssue.assignee.name}`);
    console.log(`📁 Proyecto: ${finalIssue.project.name}`);

    // 6. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`✅ TEN-73 movida a "In Progress"`);
    console.log(`📋 Historia: ${finalIssue.title} (#${finalIssue.number})`);
    console.log(`🚀 Sprint: ${finalIssue.cycle.name}`);
    console.log(`👤 Asignado a: ${finalIssue.assignee.name}`);
    
    console.log('\n💡 PRÓXIMOS PASOS:');
    console.log('1. Refrescar la página en Linear');
    console.log('2. Ir al Sprint Testing 1');
    console.log('3. La historia TEN-73 debería ser visible en "In Progress"');
    console.log('4. Comenzar a trabajar en la historia');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
moveTEN73ToInProgress();
