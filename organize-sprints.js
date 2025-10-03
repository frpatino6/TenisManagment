#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function organizeSprints() {
  console.log('📅 Organizando backlog por sprints...\n');

  try {
    const { teamId } = getLinearConfig();
    
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
            createdAt
            updatedAt
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;
    
    console.log(`📋 Total de issues: ${allIssues.length}`);

    // Organizar por sprints
    const sprintOrganization = {
      'Sprint 1 - Multi-Tenancy Foundation': {
        description: 'Base de multi-tenancy para el sistema',
        duration: '2 semanas',
        goal: 'Implementar la base de multi-tenancy para permitir múltiples clubes',
        issues: [],
        totalPoints: 0,
        dependencies: []
      },
      'Sprint 2 - Authentication & Authorization': {
        description: 'Sistema de autenticación y autorización',
        duration: '2 semanas',
        goal: 'Implementar login seguro y sistema de roles',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 1']
      },
      'Sprint 3 - Onboarding & Signup': {
        description: 'Flujo de registro y onboarding',
        duration: '2 semanas',
        goal: 'Crear experiencia de onboarding fluida para nuevos clubes',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 1', 'Sprint 2']
      },
      'Sprint 4 - Core Features': {
        description: 'Funcionalidades core del sistema',
        duration: '2 semanas',
        goal: 'Implementar funcionalidades básicas de gestión',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 1', 'Sprint 2', 'Sprint 3']
      },
      'Sprint 5 - Advanced Features': {
        description: 'Funcionalidades avanzadas',
        duration: '2 semanas',
        goal: 'Agregar funcionalidades avanzadas y optimizaciones',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 4']
      },
      'Sprint 6 - Subscription & Billing': {
        description: 'Sistema de suscripciones y facturación',
        duration: '2 semanas',
        goal: 'Implementar monetización con Stripe',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 1', 'Sprint 2', 'Sprint 3']
      },
      'Sprint 7 - Testing & Polish': {
        description: 'Testing y pulimiento',
        duration: '2 semanas',
        goal: 'Testing completo y pulimiento de funcionalidades',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 4', 'Sprint 5', 'Sprint 6']
      },
      'Sprint 8 - Admin Dashboard': {
        description: 'Dashboard administrativo',
        duration: '2 semanas',
        goal: 'Dashboard para super administradores',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 6']
      },
      'Sprint 9 - Analytics & Reporting': {
        description: 'Analytics y reportes',
        duration: '2 semanas',
        goal: 'Sistema completo de analytics y reportes',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 8']
      },
      'Sprint 10 - Mobile Features': {
        description: 'Funcionalidades móviles',
        duration: '2 semanas',
        goal: 'Optimizaciones y funcionalidades específicas para móvil',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 7']
      },
      'Sprint 11 - Go-to-Market': {
        description: 'Preparación para lanzamiento',
        duration: '2 semanas',
        goal: 'Preparar todo para el lanzamiento público',
        issues: [],
        totalPoints: 0,
        dependencies: ['Sprint 9', 'Sprint 10']
      }
    };

    // Clasificar issues por sprint
    allIssues.forEach(issue => {
      if (issue.title.includes('MT-')) {
        sprintOrganization['Sprint 1 - Multi-Tenancy Foundation'].issues.push(issue);
        sprintOrganization['Sprint 1 - Multi-Tenancy Foundation'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('AUTH-')) {
        sprintOrganization['Sprint 2 - Authentication & Authorization'].issues.push(issue);
        sprintOrganization['Sprint 2 - Authentication & Authorization'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('ONB-')) {
        sprintOrganization['Sprint 3 - Onboarding & Signup'].issues.push(issue);
        sprintOrganization['Sprint 3 - Onboarding & Signup'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('BILL-')) {
        sprintOrganization['Sprint 6 - Subscription & Billing'].issues.push(issue);
        sprintOrganization['Sprint 6 - Subscription & Billing'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('ADMIN-')) {
        sprintOrganization['Sprint 8 - Admin Dashboard'].issues.push(issue);
        sprintOrganization['Sprint 8 - Admin Dashboard'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('ANALYTICS-')) {
        sprintOrganization['Sprint 9 - Analytics & Reporting'].issues.push(issue);
        sprintOrganization['Sprint 9 - Analytics & Reporting'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('MOBILE-')) {
        sprintOrganization['Sprint 10 - Mobile Features'].issues.push(issue);
        sprintOrganization['Sprint 10 - Mobile Features'].totalPoints += issue.estimate || 0;
      } else if (issue.title.includes('GTM-')) {
        sprintOrganization['Sprint 11 - Go-to-Market'].issues.push(issue);
        sprintOrganization['Sprint 11 - Go-to-Market'].totalPoints += issue.estimate || 0;
      }
    });

    // Mostrar organización por sprints
    console.log('📅 ORGANIZACIÓN POR SPRINTS\n');
    console.log('═'.repeat(80));

    Object.entries(sprintOrganization).forEach(([sprintName, sprintData]) => {
      if (sprintData.issues.length > 0) {
        console.log(`\n🎯 ${sprintName}`);
        console.log(`📝 ${sprintData.description}`);
        console.log(`⏱️  Duración: ${sprintData.duration}`);
        console.log(`🎯 Objetivo: ${sprintData.goal}`);
        console.log(`📊 Story Points: ${sprintData.totalPoints}`);
        console.log(`🔗 Dependencias: ${sprintData.dependencies.join(', ') || 'Ninguna'}`);
        
        console.log('\n📋 Issues:');
        sprintData.issues.forEach(issue => {
          const assignee = issue.assignee ? `👤 ${issue.assignee.name}` : '❌ Sin asignar';
          const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
          const state = issue.state.name;
          
          console.log(`   ${issue.number.toString().padStart(3)} | ${issue.title.substring(0, 50).padEnd(50)} | ${points.padStart(8)} | ${state.padStart(12)} | ${assignee}`);
        });
        
        console.log('\n' + '─'.repeat(80));
      }
    });

    // Resumen general
    console.log('\n📊 RESUMEN GENERAL');
    console.log('═'.repeat(80));
    
    let totalIssues = 0;
    let totalPoints = 0;
    let sprintsWithIssues = 0;

    Object.entries(sprintOrganization).forEach(([sprintName, sprintData]) => {
      if (sprintData.issues.length > 0) {
        totalIssues += sprintData.issues.length;
        totalPoints += sprintData.totalPoints;
        sprintsWithIssues++;
        
        console.log(`${sprintName.padEnd(35)} | ${sprintData.issues.length.toString().padStart(2)} issues | ${sprintData.totalPoints.toString().padStart(3)} pts`);
      }
    });

    console.log('─'.repeat(80));
    console.log(`Total: ${sprintsWithIssues} sprints | ${totalIssues} issues | ${totalPoints} story points`);
    console.log(`Duración estimada: ${sprintsWithIssues * 2} semanas (${Math.round(sprintsWithIssues * 2 / 4)} meses)`);

    // Roadmap visual
    console.log('\n🗺️  ROADMAP VISUAL');
    console.log('═'.repeat(80));
    
    const roadmap = [
      { sprint: 1, name: 'Multi-Tenancy', weeks: '1-2' },
      { sprint: 2, name: 'Authentication', weeks: '3-4' },
      { sprint: 3, name: 'Onboarding', weeks: '5-6' },
      { sprint: 4, name: 'Core Features', weeks: '7-8' },
      { sprint: 5, name: 'Advanced Features', weeks: '9-10' },
      { sprint: 6, name: 'Billing', weeks: '11-12' },
      { sprint: 7, name: 'Testing', weeks: '13-14' },
      { sprint: 8, name: 'Admin Dashboard', weeks: '15-16' },
      { sprint: 9, name: 'Analytics', weeks: '17-18' },
      { sprint: 10, name: 'Mobile', weeks: '19-20' },
      { sprint: 11, name: 'Go-to-Market', weeks: '21-22' }
    ];

    roadmap.forEach(item => {
      const sprintData = sprintOrganization[`Sprint ${item.sprint} - ${item.name}`];
      const hasIssues = sprintData && sprintData.issues.length > 0;
      const status = hasIssues ? '✅' : '⏳';
      const points = hasIssues ? `${sprintData.totalPoints} pts` : 'TBD';
      
      console.log(`Sprint ${item.sprint.toString().padStart(2)} | ${item.name.padEnd(15)} | Semanas ${item.weeks.padEnd(5)} | ${status} | ${points}`);
    });

    console.log('\n🎉 ¡Organización por sprints completada!');
    console.log('\n💡 Próximos pasos:');
    console.log('1. Revisar dependencias entre sprints');
    console.log('2. Ajustar fechas según capacidad del equipo');
    console.log('3. Configurar milestones en Linear');
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
  organizeSprints();
}

module.exports = { organizeSprints };
