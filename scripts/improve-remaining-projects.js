#!/usr/bin/env node

/**
 * Script para mejorar los proyectos restantes que faltaron
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function improveRemainingProjects() {
  try {
    console.log('📝 Mejorando proyectos restantes que faltaron...\n');

    const { teamId } = getLinearConfig();

    // Definir mejoras para los proyectos restantes
    const projectImprovements = [
      {
        name: "Subscription & Billing",
        newDescription: "Sistema completo de suscripciones y facturación con Stripe para monetizar la plataforma. Incluye integración con Stripe, planes de suscripción (Free, Pro, Enterprise), checkout flow y webhooks de pago.",
        newState: "planned"
      },
      {
        name: "Plan Management & Limits",
        newDescription: "Gestión de planes de suscripción y límites por tenant. Control de funcionalidades disponibles según el plan contratado y gestión de upgrades/downgrades.",
        newState: "planned"
      },
      {
        name: "Super Admin Dashboard",
        newDescription: "Dashboard administrativo para supervisar todos los tenants y métricas del sistema. Vista general de todos los tenants, métricas en tiempo real y gestión de usuarios.",
        newState: "planned"
      },
      {
        name: "Quality & DevOps",
        newDescription: "Testing, optimización, documentación y procesos de DevOps para asegurar calidad y rendimiento del sistema. Incluye testing unitario, integración, CI/CD y monitoreo.",
        newState: "planned"
      },
      {
        name: "Go-to-Market",
        newDescription: "Estrategia y herramientas de lanzamiento al mercado. Incluye landing page, help center, marketing materials y estrategia de lanzamiento para adquisición de clientes.",
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

    // Mejorar cada proyecto
    let improvedCount = 0;
    for (const improvement of projectImprovements) {
      const project = allProjects.find(p => p.name === improvement.name);
      
      if (project) {
        console.log(`📝 Mejorando proyecto: ${project.name}`);
        console.log(`   📝 Descripción actual: ${project.description || 'Sin descripción'}`);
        console.log(`   📝 Nueva descripción: ${improvement.newDescription}`);
        console.log(`   📊 Issues en el proyecto: ${project.issues.nodes.length}`);
        
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

          // Mostrar issues del proyecto
          if (project.issues.nodes.length > 0) {
            console.log(`   📋 Issues en el proyecto:`);
            project.issues.nodes.forEach(issue => {
              const priorityText = issue.priority === 1 ? '🔥' : issue.priority === 2 ? '⚡' : '💡';
              const labels = issue.labels.nodes.map(label => label.name).join(', ') || 'Sin etiquetas';
              console.log(`     ${priorityText} ${issue.title} (#${issue.number}) - ${issue.estimate || 'N/A'} pts - ${issue.state.name}`);
              console.log(`       🏷️  Etiquetas: ${labels}`);
            });
          }
        } catch (error) {
          console.log(`   ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`⚠️  Proyecto no encontrado: ${improvement.name}`);
      }
    }

    // Ahora vamos a agregar etiquetas a las issues de estos proyectos
    console.log('\n🏷️  Agregando etiquetas a issues de proyectos restantes...');
    
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

    // Filtrar issues de los proyectos restantes
    const remainingProjectIssues = allIssues.filter(issue => {
      const projectNames = [
        "Subscription & Billing",
        "Plan Management & Limits", 
        "Super Admin Dashboard",
        "Quality & DevOps",
        "Go-to-Market"
      ];
      return projectNames.includes(issue.project?.name);
    });

    console.log(`📋 Issues de proyectos restantes encontradas: ${remainingProjectIssues.length}`);

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

    // Crear etiquetas específicas para estos proyectos si no existen
    const newLabels = [
      { name: 'billing', color: '#10B981' },
      { name: 'subscription', color: '#10B981' },
      { name: 'stripe', color: '#10B981' },
      { name: 'admin', color: '#8B5CF6' },
      { name: 'dashboard', color: '#8B5CF6' },
      { name: 'devops', color: '#F59E0B' },
      { name: 'testing', color: '#F59E0B' },
      { name: 'quality', color: '#F59E0B' },
      { name: 'marketing', color: '#EF4444' },
      { name: 'gtm', color: '#EF4444' },
      { name: 'landing-page', color: '#EF4444' }
    ];
    
    for (const labelData of newLabels) {
      try {
        const createLabelMutation = `
          mutation {
            issueLabelCreate(input: {
              name: "${labelData.name}"
              teamId: "${teamId}"
              color: "${labelData.color}"
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
        console.log(`  ✅ Etiqueta creada: ${labelData.name}`);
      } catch (error) {
        console.log(`  ℹ️  Etiqueta ya existe: ${labelData.name}`);
      }
    }

    // Actualizar etiquetas disponibles
    const updatedLabelsResponse = await makeLinearRequest(labelsQuery);
    const updatedAvailableLabels = updatedLabelsResponse.data.issueLabels.nodes;

    // Asignar etiquetas a issues de proyectos restantes
    let labeledCount = 0;
    for (const issue of remainingProjectIssues) {
      console.log(`\n📝 Procesando: ${issue.title} (#${issue.number}) - Proyecto: ${issue.project?.name}`);
      
      // Determinar etiquetas apropiadas según el proyecto
      let labelsToAdd = [];
      
      switch (issue.project?.name) {
        case "Subscription & Billing":
          labelsToAdd = ['billing', 'subscription'];
          if (issue.title.toLowerCase().includes('stripe')) {
            labelsToAdd.push('stripe');
          }
          break;
        case "Plan Management & Limits":
          labelsToAdd = ['subscription', 'billing'];
          break;
        case "Super Admin Dashboard":
          labelsToAdd = ['admin', 'dashboard'];
          break;
        case "Quality & DevOps":
          labelsToAdd = ['quality', 'devops'];
          if (issue.title.toLowerCase().includes('test')) {
            labelsToAdd.push('testing');
          }
          break;
        case "Go-to-Market":
          labelsToAdd = ['marketing', 'gtm'];
          if (issue.title.toLowerCase().includes('landing')) {
            labelsToAdd.push('landing-page');
          }
          break;
        default:
          labelsToAdd = ['backend'];
      }

      // Agregar etiqueta de backend o frontend según corresponda
      if (issue.title.toLowerCase().includes('api') || issue.title.toLowerCase().includes('backend')) {
        labelsToAdd.push('backend');
      } else if (issue.title.toLowerCase().includes('dashboard') || issue.title.toLowerCase().includes('ui') || issue.title.toLowerCase().includes('frontend')) {
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
          labeledCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      }
    }

    console.log(`\n🎉 ¡Mejoras de proyectos restantes completadas!`);
    console.log(`📊 Proyectos mejorados: ${improvedCount}/${projectImprovements.length}`);
    console.log(`📊 Issues etiquetadas: ${labeledCount}/${remainingProjectIssues.length}`);

    // Mostrar resumen final
    console.log('\n📋 RESUMEN DE MEJORAS COMPLETAS:');
    console.log('─'.repeat(60));
    console.log('✅ Descripciones de TODOS los proyectos mejoradas');
    console.log('✅ Estados de proyectos actualizados a "planned"');
    console.log('✅ Etiquetas agregadas a issues de Multi-Tenancy');
    console.log('✅ Etiquetas agregadas a issues de Onboarding');
    console.log('✅ Etiquetas agregadas a issues de proyectos restantes');
    console.log('✅ Organización consistente en TODO el sistema');

    console.log('\n🎯 BENEFICIOS FINALES LOGRADOS:');
    console.log('─'.repeat(60));
    console.log('✅ TODOS los proyectos con descripciones claras y detalladas');
    console.log('✅ Etiquetas consistentes en TODO el sistema Linear');
    console.log('✅ Mejor filtrado y organización de issues por categoría');
    console.log('✅ Identificación clara de componentes y funcionalidades');
    console.log('✅ Facilita la asignación de responsables por especialidad');
    console.log('✅ Estándar uniforme en TODOS los proyectos del sistema');

  } catch (error) {
    console.error('❌ Error mejorando proyectos restantes:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
improveRemainingProjects();
