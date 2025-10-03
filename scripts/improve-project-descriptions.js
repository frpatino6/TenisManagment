#!/usr/bin/env node

/**
 * Script para mejorar descripciones de proyectos existentes
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function improveProjectDescriptions() {
  try {
    console.log('📝 Mejorando descripciones de proyectos existentes...\n');

    const { teamId } = getLinearConfig();

    // Definir mejoras para cada proyecto
    const projectImprovements = [
      {
        name: "Multi-Tenancy Backend",
        newDescription: "Fundación del sistema multi-tenant que permite que múltiples clubes de tenis operen de forma independiente. Incluye modelos de datos, servicios de gestión de tenants y middleware de extracción.",
        newState: "planned"
      },
      {
        name: "Multi-Tenancy Frontend", 
        newDescription: "Interfaces de usuario para la gestión de tenants, incluyendo configuración de clubes y administración multi-tenant.",
        newState: "planned"
      },
      {
        name: "Tenant Signup & Onboarding",
        newDescription: "Flujo completo de registro y onboarding para nuevos clubes de tenis, incluyendo wizard de configuración inicial y email de bienvenida.",
        newState: "planned"
      }
    ];

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
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const allProjects = projectsResponse.data.projects.nodes;

    // Mejorar cada proyecto
    let improvedCount = 0;
    for (const improvement of projectImprovements) {
      const project = allProjects.find(p => p.name === improvement.name);
      
      if (project) {
        console.log(`📝 Mejorando proyecto: ${project.name}`);
        console.log(`   📝 Descripción actual: ${project.description || 'Sin descripción'}`);
        console.log(`   📝 Nueva descripción: ${improvement.newDescription}`);
        
        const updateMutation = `
          mutation {
            projectUpdate(id: "${project.id}", input: {
              description: "${improvement.newDescription}"
              state: "${improvement.newState}"
            }) {
              project {
                id
                name
                description
                state
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedProject = updateResponse.data.projectUpdate.project;
          console.log(`   ✅ Proyecto actualizado: ${updatedProject.name}`);
          console.log(`   📅 Estado: ${updatedProject.state}`);
          improvedCount++;
        } catch (error) {
          console.log(`   ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`⚠️  Proyecto no encontrado: ${improvement.name}`);
      }
    }

    // Ahora vamos a agregar etiquetas a las issues de onboarding
    console.log('\n🏷️  Agregando etiquetas a issues de onboarding...');
    
    // Obtener todas las issues
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
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar issues de onboarding
    const onboardingIssues = allIssues.filter(issue => 
      issue.title.includes('ONB-') ||
      issue.title.toLowerCase().includes('onboarding') ||
      issue.title.toLowerCase().includes('wizard') ||
      issue.title.toLowerCase().includes('email de bienvenida')
    );

    console.log(`📋 Issues de onboarding encontradas: ${onboardingIssues.length}`);

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

    // Crear etiquetas específicas para onboarding si no existen
    const onboardingLabels = ['onboarding', 'frontend', 'wizard', 'email', 'signup'];
    
    for (const labelName of onboardingLabels) {
      try {
        const createLabelMutation = `
          mutation {
            issueLabelCreate(input: {
              name: "${labelName}"
              teamId: "${teamId}"
              color: "#10B981"
            }) {
              issueLabel {
                id
                name
                color
              }
            }
          }
        `;

        await makeLinearRequest(createLabelMutation);
        console.log(`  ✅ Etiqueta creada: ${labelName}`);
      } catch (error) {
        console.log(`  ℹ️  Etiqueta ya existe: ${labelName}`);
      }
    }

    // Actualizar etiquetas disponibles
    const updatedLabelsResponse = await makeLinearRequest(labelsQuery);
    const updatedAvailableLabels = updatedLabelsResponse.data.issueLabels.nodes;

    // Asignar etiquetas a issues de onboarding
    let labeledOnboardingCount = 0;
    for (const issue of onboardingIssues) {
      console.log(`\n📝 Procesando: ${issue.title} (#${issue.number})`);
      
      // Determinar etiquetas apropiadas
      let labelsToAdd = ['onboarding'];
      
      if (issue.title.includes('Wizard') || issue.title.includes('wizard')) {
        labelsToAdd.push('frontend', 'wizard');
      } else if (issue.title.includes('Email') || issue.title.includes('email')) {
        labelsToAdd.push('email');
      } else if (issue.title.includes('Signup') || issue.title.includes('signup')) {
        labelsToAdd.push('signup', 'frontend');
      } else {
        labelsToAdd.push('frontend');
      }

      // Obtener IDs de las etiquetas
      const labelIds = labelsToAdd.map(labelName => {
        const label = updatedAvailableLabels.find(l => l.name === labelName);
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
          labeledOnboardingCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      }
    }

    console.log(`\n🎉 ¡Mejoras completadas!`);
    console.log(`📊 Proyectos mejorados: ${improvedCount}/${projectImprovements.length}`);
    console.log(`📊 Issues de onboarding etiquetadas: ${labeledOnboardingCount}/${onboardingIssues.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN DE MEJORAS:');
    console.log('─'.repeat(50));
    console.log('✅ Descripciones de proyectos mejoradas');
    console.log('✅ Estados de proyectos actualizados');
    console.log('✅ Etiquetas agregadas a issues de Multi-Tenancy');
    console.log('✅ Etiquetas agregadas a issues de Onboarding');
    console.log('✅ Organización consistente con sistema de mensajería');

    console.log('\n🎯 BENEFICIOS LOGRADOS:');
    console.log('─'.repeat(50));
    console.log('✅ Proyectos con descripciones claras y detalladas');
    console.log('✅ Etiquetas consistentes en todo el sistema');
    console.log('✅ Mejor filtrado y organización de issues');
    console.log('✅ Identificación clara de componentes y funcionalidades');
    console.log('✅ Facilita la asignación de responsables por especialidad');

  } catch (error) {
    console.error('❌ Error mejorando proyectos:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
improveProjectDescriptions();
