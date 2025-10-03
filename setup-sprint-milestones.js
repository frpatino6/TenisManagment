#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function setupSprintMilestones() {
  console.log('🎯 Configurando milestones y organizando sprints...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Definir milestones
    const milestones = [
      {
        name: 'Sprint 1 - Multi-Tenancy Foundation',
        description: 'Base de multi-tenancy para el sistema',
        targetDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 2 semanas
        issues: ['US-MT-001', 'US-MT-002', 'US-MT-003']
      },
      {
        name: 'Sprint 2 - Authentication & Authorization',
        description: 'Sistema de autenticación y autorización',
        targetDate: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000), // 4 semanas
        issues: ['US-AUTH-001', 'US-AUTH-002', 'US-AUTH-003']
      },
      {
        name: 'Sprint 3 - Onboarding & Signup',
        description: 'Flujo de registro y onboarding',
        targetDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000), // 6 semanas
        issues: ['US-ONB-001', 'US-ONB-002']
      },
      {
        name: 'Sprint 6 - Subscription & Billing',
        description: 'Sistema de suscripciones y facturación',
        targetDate: new Date(Date.now() + 84 * 24 * 60 * 60 * 1000), // 12 semanas
        issues: ['US-BILL-001', 'US-BILL-003', 'US-BILL-004']
      },
      {
        name: 'Sprint 8 - Admin Dashboard',
        description: 'Dashboard administrativo',
        targetDate: new Date(Date.now() + 112 * 24 * 60 * 60 * 1000), // 16 semanas
        issues: ['US-ADMIN-001']
      },
      {
        name: 'Sprint 9 - Analytics & Reporting',
        description: 'Sistema de analytics y reportes',
        targetDate: new Date(Date.now() + 126 * 24 * 60 * 60 * 1000), // 18 semanas
        issues: ['US-ANALYTICS-001']
      },
      {
        name: 'Sprint 10 - Mobile Features',
        description: 'Funcionalidades móviles',
        targetDate: new Date(Date.now() + 140 * 24 * 60 * 60 * 1000), // 20 semanas
        issues: ['US-MOBILE-001']
      },
      {
        name: 'Sprint 11 - Go-to-Market',
        description: 'Preparación para lanzamiento',
        targetDate: new Date(Date.now() + 154 * 24 * 60 * 60 * 1000), // 22 semanas
        issues: ['US-GTM-001', 'US-GTM-002']
      }
    ];

    // Obtener todos los issues
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            url
            assignee {
              name
            }
            estimate
            priority
            state {
              name
            }
            team {
              name
            }
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    console.log('📋 Issues encontrados:', allIssues.length);

    // Crear milestones y organizar issues
    for (const milestone of milestones) {
      console.log(`\n🎯 Configurando milestone: ${milestone.name}`);
      
      // Crear milestone
      const createMilestoneQuery = `
        mutation CreateMilestone($input: MilestoneCreateInput!) {
          milestoneCreate(input: $input) {
            success
            milestone {
              id
              name
              description
              targetDate
            }
          }
        }
      `;

      const createMilestoneVariables = {
        input: {
          name: milestone.name,
          description: milestone.description,
          targetDate: milestone.targetDate.toISOString(),
          teamId: teamId
        }
      };

      const milestoneResponse = await makeLinearRequest(createMilestoneQuery, createMilestoneVariables);
      
      if (milestoneResponse.data.milestoneCreate.success) {
        const createdMilestone = milestoneResponse.data.milestoneCreate.milestone;
        console.log(`✅ Milestone creado: ${createdMilestone.name}`);
        console.log(`📅 Fecha objetivo: ${new Date(createdMilestone.targetDate).toLocaleDateString()}`);
        
        // Asignar issues al milestone
        for (const issuePattern of milestone.issues) {
          const matchingIssues = allIssues.filter(issue => 
            issue.title.includes(issuePattern)
          );
          
          for (const issue of matchingIssues) {
            console.log(`   📝 Asignando: ${issue.title}`);
            
            const updateIssueQuery = `
              mutation UpdateIssue($id: String!, $input: IssueUpdateInput!) {
                issueUpdate(id: $id, input: $input) {
                  success
                  issue {
                    id
                    title
                    milestone {
                      name
                    }
                  }
                }
              }
            `;

            const updateIssueVariables = {
              id: issue.id,
              input: {
                milestoneId: createdMilestone.id
              }
            };

            const updateResponse = await makeLinearRequest(updateIssueQuery, updateIssueVariables);
            
            if (updateResponse.data.issueUpdate.success) {
              console.log(`     ✅ Asignado a milestone`);
            } else {
              console.log(`     ❌ Error asignando a milestone`);
            }
          }
        }
      } else {
        console.log(`❌ Error creando milestone: ${milestone.name}`);
      }
    }

    // Mostrar resumen final
    console.log('\n📊 RESUMEN DE MILESTONES CREADOS');
    console.log('═'.repeat(80));
    
    const finalMilestonesQuery = `
      query {
        milestones(filter: { team: { id: { eq: "${teamId}" } } }) {
          nodes {
            id
            name
            description
            targetDate
            issues {
              nodes {
                id
                title
                estimate
              }
            }
          }
        }
      }
    `;

    const finalResponse = await makeLinearRequest(finalMilestonesQuery);
    const milestones = finalResponse.data.milestones.nodes;

    milestones.forEach(milestone => {
      const totalPoints = milestone.issues.nodes.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
      const issueCount = milestone.issues.nodes.length;
      
      console.log(`\n🎯 ${milestone.name}`);
      console.log(`📅 Fecha: ${new Date(milestone.targetDate).toLocaleDateString()}`);
      console.log(`📊 Issues: ${issueCount} | Story Points: ${totalPoints}`);
      console.log(`📝 Descripción: ${milestone.description}`);
      
      if (milestone.issues.nodes.length > 0) {
        console.log('📋 Issues:');
        milestone.issues.nodes.forEach(issue => {
          console.log(`   - ${issue.title} (${issue.estimate || 0} pts)`);
        });
      }
    });

    console.log('\n🎉 ¡Milestones configurados exitosamente!');
    console.log('\n💡 Próximos pasos:');
    console.log('1. Revisar fechas de milestones en Linear');
    console.log('2. Ajustar fechas según capacidad del equipo');
    console.log('3. Configurar notificaciones de milestones');
    console.log('4. Iniciar Sprint 1 con Multi-Tenancy Foundation');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('\n💡 Asegúrate de tener configurado linear-config.env con:');
    console.log('   LINEAR_API_KEY=tu_api_key_aqui');
    console.log('   LINEAR_TEAM_ID=tu_team_id_aqui');
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  setupSprintMilestones();
}

module.exports = { setupSprintMilestones };
