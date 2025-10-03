#!/usr/bin/env node

/**
 * Script para analizar y mejorar proyectos existentes de Multi-Tenancy
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function analyzeAndImproveExistingProjects() {
  try {
    console.log('🔍 Analizando proyectos existentes de Multi-Tenancy...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los proyectos
    const projectsQuery = `
      query {
        projects(first: 20) {
          nodes {
            id
            name
            description
            state
            startDate
            targetDate
            url
            issues {
              nodes {
                id
                title
                number
                state {
                  name
                }
                estimate
                priority
                labels {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const allProjects = projectsResponse.data.projects.nodes;

    // Filtrar proyectos de Multi-Tenancy
    const multiTenancyProjects = allProjects.filter(project => 
      project.name.toLowerCase().includes('multi-tenancy') ||
      project.name.toLowerCase().includes('tenant') ||
      project.description?.toLowerCase().includes('multi-tenancy') ||
      project.description?.toLowerCase().includes('tenant')
    );

    console.log(`📋 Proyectos de Multi-Tenancy encontrados: ${multiTenancyProjects.length}`);

    if (multiTenancyProjects.length === 0) {
      console.log('ℹ️  No se encontraron proyectos de Multi-Tenancy');
      return;
    }

    // Mostrar proyectos existentes
    for (const project of multiTenancyProjects) {
      console.log(`\n📁 Proyecto: ${project.name}`);
      console.log(`   📅 Estado: ${project.state}`);
      console.log(`   📊 Issues: ${project.issues.nodes.length}`);
      console.log(`   🔗 URL: ${project.url}`);
      console.log(`   📝 Descripción actual: ${project.description || 'Sin descripción'}`);
      
      if (project.issues.nodes.length > 0) {
        console.log(`   📋 Issues:`);
        project.issues.nodes.forEach(issue => {
          const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
          const labels = issue.labels.nodes.map(label => label.name).join(', ') || 'Sin etiquetas';
          console.log(`     ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
          console.log(`       🏷️  Etiquetas: ${labels}`);
        });
      }
    }

    // Obtener todas las issues de Multi-Tenancy (US-MT-001 a US-MT-003, EPIC-1, etc.)
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            state {
              name
            }
            estimate
            priority
            labels {
              nodes {
                name
              }
            }
            project {
              id
              name
            }
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar issues de Multi-Tenancy
    const multiTenancyIssues = allIssues.filter(issue => {
      const titleMatch = issue.title.toLowerCase().includes('multi-tenancy') ||
                        issue.title.includes('MT-') ||
                        issue.title.includes('US-MT-') ||
                        issue.title.includes('Tenant');
      
      const labelMatch = issue.labels.nodes.some(label => 
        label.name.toLowerCase().includes('multi-tenancy') ||
        label.name.toLowerCase().includes('tenant')
      );
      
      return titleMatch || labelMatch;
    });

    console.log(`\n📋 Issues de Multi-Tenancy encontradas: ${multiTenancyIssues.length}`);

    // Definir etiquetas sugeridas para Multi-Tenancy
    const suggestedLabels = [
      'multi-tenancy',
      'backend',
      'data-model',
      'middleware',
      'tenant-service',
      'architecture',
      'foundation'
    ];

    // Crear etiquetas si no existen
    console.log('\n🏷️  Creando etiquetas para Multi-Tenancy...');
    const createdLabels = [];

    for (const labelName of suggestedLabels) {
      try {
        const createLabelMutation = `
          mutation {
            issueLabelCreate(input: {
              name: "${labelName}"
              teamId: "${teamId}"
              color: "#3B82F6"
            }) {
              issueLabel {
                id
                name
                color
              }
            }
          }
        `;

        const labelResponse = await makeLinearRequest(createLabelMutation);
        const label = labelResponse.data.issueLabelCreate.issueLabel;
        createdLabels.push(label);
        console.log(`  ✅ Etiqueta creada: ${label.name}`);
      } catch (error) {
        // La etiqueta ya existe, continuar
        console.log(`  ℹ️  Etiqueta ya existe: ${labelName}`);
      }
    }

    // Obtener todas las etiquetas disponibles
    const labelsQuery = `
      query {
        issueLabels(first: 50) {
          nodes {
            id
            name
            color
          }
        }
      }
    `;

    const labelsResponse = await makeLinearRequest(labelsQuery);
    const availableLabels = labelsResponse.data.issueLabels.nodes;

    // Asignar etiquetas a las issues de Multi-Tenancy
    console.log('\n🏷️  Asignando etiquetas a issues de Multi-Tenancy...');
    let labeledCount = 0;

    for (const issue of multiTenancyIssues) {
      console.log(`\n📝 Procesando: ${issue.title} (#${issue.number})`);
      
      // Determinar etiquetas apropiadas según el tipo de issue
      let labelsToAdd = [];
      
      if (issue.title.includes('Modelo') || issue.title.includes('Model')) {
        labelsToAdd = ['multi-tenancy', 'backend', 'data-model'];
      } else if (issue.title.includes('Service') || issue.title.includes('Servicio')) {
        labelsToAdd = ['multi-tenancy', 'backend', 'tenant-service'];
      } else if (issue.title.includes('Middleware')) {
        labelsToAdd = ['multi-tenancy', 'backend', 'middleware'];
      } else if (issue.title.includes('EPIC') || issue.title.includes('Foundation')) {
        labelsToAdd = ['multi-tenancy', 'architecture', 'foundation'];
      } else {
        labelsToAdd = ['multi-tenancy', 'backend'];
      }

      // Obtener IDs de las etiquetas
      const labelIds = labelsToAdd.map(labelName => {
        const label = availableLabels.find(l => l.name === labelName);
        return label ? label.id : null;
      }).filter(id => id !== null);

      if (labelIds.length > 0) {
        console.log(`  🏷️  Agregando etiquetas: ${labelsToAdd.join(', ')}`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              labelIds: ${JSON.stringify(labelIds)}
            }) {
              issue {
                id
                title
                labels {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          const currentLabels = updatedIssue.labels.nodes.map(label => label.name).join(', ');
          console.log(`  ✅ Etiquetas actualizadas: ${currentLabels}`);
          labeledCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      }
    }

    console.log(`\n🎉 ¡Análisis y mejora completados!`);
    console.log(`📊 Issues etiquetadas: ${labeledCount}/${multiTenancyIssues.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN DE MEJORAS:');
    console.log('─'.repeat(50));
    console.log(`📁 Proyectos analizados: ${multiTenancyProjects.length}`);
    console.log(`📋 Issues encontradas: ${multiTenancyIssues.length}`);
    console.log(`🏷️  Etiquetas creadas/verificadas: ${suggestedLabels.length}`);
    console.log(`✅ Issues mejoradas: ${labeledCount}`);

    console.log('\n🎯 BENEFICIOS DE LAS MEJORAS:');
    console.log('─'.repeat(50));
    console.log('✅ Etiquetas consistentes con el sistema de mensajería');
    console.log('✅ Mejor organización y filtrado de issues');
    console.log('✅ Identificación clara de componentes (backend, data-model, etc.)');
    console.log('✅ Facilita la asignación de responsables por especialidad');

  } catch (error) {
    console.error('❌ Error analizando proyectos existentes:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
analyzeAndImproveExistingProjects();
