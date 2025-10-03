#!/usr/bin/env node

/**
 * Script para actualizar un solo proyecto como prueba
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function updateSingleProject() {
  try {
    console.log('🔍 Actualizando un solo proyecto como prueba...\n');

    const { teamId } = getLinearConfig();

    // Obtener un proyecto específico
    const projectsQuery = `
      query {
        projects(first: 1, filter: { name: { eq: "Testing y Optimización" } }) {
          nodes {
            id
            name
            description
            state
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const project = projectsResponse.data.projects.nodes[0];

    if (!project) {
      console.log('❌ No se encontró el proyecto');
      return;
    }

    console.log(`📋 Proyecto encontrado: ${project.name}`);
    console.log(`   ID: ${project.id}`);
    console.log(`   Estado: ${project.state}`);
    console.log(`   Descripción actual: ${project.description ? 'Tiene descripción' : 'Sin descripción'}`);

    // Nueva descripción
    const newDescription = `## Objetivo

Establecer testing y optimización del sistema de mensajería para asegurar la calidad, rendimiento y mantenibilidad.

## Alcance

- Testing unitario e integración
- Testing E2E automatizado
- Optimización de performance
- Documentación técnica
- CI/CD pipeline
- Monitoreo y alertas
- Code quality tools

## Criterios de Éxito

- Coverage de tests >80%
- Performance <200ms response time
- CI/CD pipeline funcionando
- Documentación actualizada
- Monitoreo configurado
- Code quality metrics cumplidas
- Deploy automatizado funcionando

## Timeline

Estimado: 1-2 semanas
Estado actual: planned

## Recursos

- 1-2 QA Engineers
- 1 DevOps Engineer
- 1 Technical Writer (part-time)
- Herramientas: Jest, Cypress, GitHub Actions`;

    console.log('\n🔍 Actualizando descripción...');

    // Mutación de actualización
    const updateMutation = `
      mutation {
        projectUpdate(
          id: "${project.id}"
          input: {
            description: ${JSON.stringify(newDescription)}
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

    console.log('📝 Mutación a ejecutar:');
    console.log(updateMutation);

    const updateResponse = await makeLinearRequest(updateMutation);
    
    console.log('\n📋 Respuesta completa:');
    console.log(JSON.stringify(updateResponse, null, 2));

    if (updateResponse.data?.projectUpdate?.success) {
      console.log('\n✅ ¡Proyecto actualizado exitosamente!');
      console.log(`📝 Nueva descripción: ${updateResponse.data.projectUpdate.project.description.length} caracteres`);
    } else {
      console.log('\n❌ Error en la actualización');
      console.log('Respuesta:', updateResponse);
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
updateSingleProject();
