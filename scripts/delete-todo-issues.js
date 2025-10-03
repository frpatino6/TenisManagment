#!/usr/bin/env node

/**
 * Script para eliminar historias en estado "Todo" (creadas por defecto por Linear)
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function deleteTodoIssues() {
  try {
    console.log('🗑️  Eliminando historias en estado "Todo"...\n');

    const { teamId } = getLinearConfig();

    // Obtener todas las issues
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
            labels {
              nodes {
                name
              }
            }
            estimate
            priority
            createdAt
            description
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    console.log('Debug - Response structure:', JSON.stringify(issuesResponse, null, 2));
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar historias en estado "Todo"
    const todoIssues = allIssues.filter(issue => 
      issue.state.name === 'Todo' || issue.state.name === 'todo'
    );

    console.log(`📋 Encontradas ${todoIssues.length} historias en estado "Todo"`);

    if (todoIssues.length === 0) {
      console.log('ℹ️  No se encontraron historias en estado "Todo"');
      return;
    }

    // Mostrar historias encontradas
    console.log('\n📝 Historias en estado "Todo" encontradas:');
    todoIssues.forEach(issue => {
      const labels = issue.labels.nodes.map(label => label.name).join(', ');
      const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                          issue.priority === 2 ? '⚡ High' : 
                          issue.priority === 3 ? '💡 Medium' : '📝 Low';
      
      console.log(`  - ${issue.title} (#${issue.number})`);
      console.log(`    ${priorityText} | ${issue.estimate || 'N/A'} pts | Labels: ${labels || 'Ninguno'}`);
      console.log(`    Creada: ${new Date(issue.createdAt).toLocaleDateString()}`);
      if (issue.description) {
        console.log(`    Descripción: ${issue.description.substring(0, 100)}...`);
      }
      console.log('');
    });

    // Confirmar eliminación
    console.log('⚠️  ADVERTENCIA: Estas historias serán eliminadas permanentemente.');
    console.log('¿Estás seguro de que quieres continuar? (Ctrl+C para cancelar)');
    
    // Esperar 3 segundos para que el usuario pueda cancelar
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Eliminar historias
    let deletedCount = 0;
    for (const issue of todoIssues) {
      console.log(`🗑️  Eliminando: ${issue.title} (#${issue.number})`);
      
      const deleteMutation = `
        mutation {
          issueDelete(id: "${issue.id}") {
            success
          }
        }
      `;
      
      try {
        const deleteResponse = await makeLinearRequest(deleteMutation);
        const result = deleteResponse.data.issueDelete;
        
        if (result.success) {
          console.log(`  ✅ Eliminada exitosamente`);
          deletedCount++;
        } else {
          console.log(`  ⚠️  Error al eliminar`);
        }
      } catch (error) {
        console.log(`  ❌ Error: ${error.message}`);
      }
    }

    console.log(`\n🎉 ¡Proceso completado!`);
    console.log(`📊 Historias eliminadas: ${deletedCount}/${todoIssues.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN FINAL:');
    console.log('─'.repeat(50));
    console.log(`Total historias en "Todo": ${todoIssues.length}`);
    console.log(`Eliminadas exitosamente: ${deletedCount}`);
    console.log(`Errores: ${todoIssues.length - deletedCount}`);

  } catch (error) {
    console.error('❌ Error eliminando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
deleteTodoIssues();
