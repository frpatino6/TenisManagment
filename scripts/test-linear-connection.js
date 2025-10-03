#!/usr/bin/env node

/**
 * Script de prueba para verificar conexión con Linear
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function testLinearConnection() {
  try {
    console.log('🔍 Probando conexión con Linear...\n');

    const config = getLinearConfig();
    console.log('📋 Configuración:');
    console.log(`   Team ID: ${config.teamId}`);
    console.log(`   API Key: ${config.apiKey ? 'Configurada' : 'No configurada'}\n`);

    // Probar query simple
    const testQuery = `
      query {
        viewer {
          id
          name
          email
        }
      }
    `;

    console.log('🔍 Probando query de usuario...');
    const userResponse = await makeLinearRequest(testQuery);
    console.log('✅ Usuario:', userResponse.data.viewer.name);

    // Probar query de proyectos
    const projectsQuery = `
      query {
        projects(first: 5) {
          nodes {
            id
            name
            description
            state
          }
        }
      }
    `;

    console.log('\n🔍 Probando query de proyectos...');
    const projectsResponse = await makeLinearRequest(projectsQuery);
    console.log(`✅ Proyectos encontrados: ${projectsResponse.data.projects.nodes.length}`);

    // Mostrar un proyecto como ejemplo
    if (projectsResponse.data.projects.nodes.length > 0) {
      const firstProject = projectsResponse.data.projects.nodes[0];
      console.log('\n📋 Ejemplo de proyecto:');
      console.log(`   ID: ${firstProject.id}`);
      console.log(`   Nombre: ${firstProject.name}`);
      console.log(`   Estado: ${firstProject.state}`);
      console.log(`   Descripción: ${firstProject.description ? 'Tiene descripción' : 'Sin descripción'}`);
    }

    // Probar mutación simple
    console.log('\n🔍 Probando mutación de actualización...');
    if (projectsResponse.data.projects.nodes.length > 0) {
      const testProject = projectsResponse.data.projects.nodes[0];
      
      const updateMutation = `
        mutation {
          projectUpdate(
            id: "${testProject.id}"
            input: {
              description: "Test description update"
            }
          ) {
            success
            project {
              id
              name
              description
            }
          }
        }
      `;

      try {
        const updateResponse = await makeLinearRequest(updateMutation);
        console.log('✅ Mutación exitosa:', updateResponse.data.projectUpdate?.success);
        
        if (updateResponse.data.projectUpdate?.project) {
          console.log('✅ Proyecto actualizado:', updateResponse.data.projectUpdate.project.name);
        }
      } catch (error) {
        console.log('❌ Error en mutación:', error.message);
      }
    }

    console.log('\n🎉 ¡Conexión con Linear funcionando correctamente!');

  } catch (error) {
    console.error('❌ Error en conexión con Linear:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
testLinearConnection();
