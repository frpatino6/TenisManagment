#!/usr/bin/env node

/**
 * Script para organizar historias de testing en sprints y asignarlas
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function organizeTestingSprints() {
  try {
    console.log('🚀 Organizando historias de testing en sprints...\n');

    const { teamId } = getLinearConfig();

    // 1. Crear sprints para testing
    console.log('📋 Creando sprints para testing...');
    
    const sprints = [
      {
        name: 'Sprint Testing 1 - Configuración y Core',
        description: 'Sprint 1: Configuración base, testing de domain y application core',
        startDate: new Date(),
        endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // 2 semanas
      },
      {
        name: 'Sprint Testing 2 - Infrastructure y Integration',
        description: 'Sprint 2: Testing de infrastructure, integración y E2E',
        startDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000) // 4 semanas
      },
      {
        name: 'Sprint Testing 3 - E2E y Documentación',
        description: 'Sprint 3: Testing E2E completo, performance y documentación',
        startDate: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000),
        endDate: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000) // 6 semanas
      }
    ];

    const createdSprints = {};
    
    for (const sprint of sprints) {
      console.log(`📝 Creando sprint: ${sprint.name}`);
      
      const createCycleMutation = `
        mutation {
          cycleCreate(
            input: {
              name: "${sprint.name}"
              description: "${sprint.description}"
              teamId: "${teamId}"
              startsAt: "${sprint.startDate.toISOString()}"
              endsAt: "${sprint.endDate.toISOString()}"
            }
          ) {
            success
            cycle {
              id
              name
              number
            }
          }
        }
      `;

      const cycleResponse = await makeLinearRequest(createCycleMutation);
      
      if (cycleResponse.data.cycleCreate?.success) {
        const cycle = cycleResponse.data.cycleCreate.cycle;
        createdSprints[sprint.name] = cycle.id;
        console.log(`   ✅ Sprint creado: ${cycle.name} (#${cycle.number})`);
      } else {
        console.log(`   ❌ Error creando sprint: ${sprint.name}`);
      }
    }

    // 2. Obtener historias de testing
    console.log('\n📋 Obteniendo historias de testing...');
    
    const getIssuesQuery = `
      query {
        issues(first: 50, filter: { 
          labels: { name: { eq: "testing" } }
        }) {
          nodes {
            id
            title
            number
            priority
            estimate
            state {
              name
            }
            project {
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

    const issuesResponse = await makeLinearRequest(getIssuesQuery);
    const testingIssues = issuesResponse.data.issues.nodes;

    console.log(`📋 Historias de testing encontradas: ${testingIssues.length}`);

    // 3. Organizar historias por sprints según prioridad
    const sprint1Issues = []; // P0 - Configuración y Core
    const sprint2Issues = []; // P0 - Infrastructure y Integration  
    const sprint3Issues = []; // P1 - E2E y Documentación

    testingIssues.forEach(issue => {
      const priority = issue.priority;
      const title = issue.title;
      
      // Sprint 1: Configuración base, domain core, application core
      if (title.includes('TS-001') || title.includes('TS-002') || // Configuración
          title.includes('TS-003') || title.includes('TS-004') || title.includes('TS-005') || // Domain core
          title.includes('TS-007') || title.includes('TS-008') || title.includes('TS-009') || // Application core
          title.includes('TS-012') || title.includes('TS-013') || // Infrastructure core
          title.includes('TS-016') || title.includes('TS-017') || title.includes('TS-018') || // Integration core
          title.includes('TS-020') || title.includes('TS-021') || title.includes('TS-022') || // E2E core
          title.includes('TS-025')) { // CI/CD
        sprint1Issues.push(issue);
      }
      // Sprint 2: Infrastructure avanzado, Integration avanzado
      else if (title.includes('TS-010') || title.includes('TS-011') || // Application avanzado
               title.includes('TS-014') || title.includes('TS-015') || // Infrastructure avanzado
               title.includes('TS-019')) { // Integration avanzado
        sprint2Issues.push(issue);
      }
      // Sprint 3: E2E avanzado, Documentación
      else if (title.includes('TS-006') || // Domain avanzado
               title.includes('TS-023') || title.includes('TS-024') || // E2E avanzado
               title.includes('TS-026')) { // Documentación
        sprint3Issues.push(issue);
      }
    });

    console.log(`📊 Sprint 1: ${sprint1Issues.length} historias`);
    console.log(`📊 Sprint 2: ${sprint2Issues.length} historias`);
    console.log(`📊 Sprint 3: ${sprint3Issues.length} historias`);

    // 4. Asignar historias a sprints
    console.log('\n🔄 Asignando historias a sprints...');
    
    const sprintAssignments = [
      { sprintName: 'Sprint Testing 1 - Configuración y Core', issues: sprint1Issues, sprintId: createdSprints['Sprint Testing 1 - Configuración y Core'] },
      { sprintName: 'Sprint Testing 2 - Infrastructure y Integration', issues: sprint2Issues, sprintId: createdSprints['Sprint Testing 2 - Infrastructure y Integration'] },
      { sprintName: 'Sprint Testing 3 - E2E y Documentación', issues: sprint3Issues, sprintId: createdSprints['Sprint Testing 3 - E2E y Documentación'] }
    ];

    let totalAssigned = 0;

    for (const assignment of sprintAssignments) {
      if (!assignment.sprintId) {
        console.log(`❌ No se encontró ID para sprint: ${assignment.sprintName}`);
        continue;
      }

      console.log(`\n📝 Asignando historias a: ${assignment.sprintName}`);
      
      for (const issue of assignment.issues) {
        console.log(`   📋 Asignando: ${issue.title} (#${issue.number})`);
        
        const updateIssueMutation = `
          mutation {
            issueUpdate(
              id: "${issue.id}"
              input: {
                cycleId: "${assignment.sprintId}"
              }
            ) {
              success
              issue {
                id
                title
                number
                cycle {
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
            console.log(`      ✅ Asignado a: ${updatedIssue.cycle.name}`);
            totalAssigned++;
          } else {
            console.log(`      ❌ Error asignando: ${issue.title}`);
          }
        } catch (error) {
          console.log(`      ❌ Error: ${error.message}`);
        }
      }
    }

    // 5. Obtener información del equipo para asignar historias
    console.log('\n👥 Obteniendo información del equipo...');
    
    const getTeamQuery = `
      query {
        team(id: "${teamId}") {
          id
          name
          members {
            nodes {
              id
              name
              email
            }
          }
        }
      }
    `;

    const teamResponse = await makeLinearRequest(getTeamQuery);
    const teamMembers = teamResponse.data.team.members.nodes;

    console.log(`👥 Miembros del equipo: ${teamMembers.length}`);
    teamMembers.forEach(member => {
      console.log(`   - ${member.name} (${member.email})`);
    });

    // 6. Asignar historias a miembros del equipo
    console.log('\n👤 Asignando historias a miembros del equipo...');
    
    // Distribuir historias entre miembros del equipo
    const sprint1Assigned = 0;
    const sprint2Assigned = 0;
    const sprint3Assigned = 0;

    // Asignar Sprint 1 (Configuración y Core)
    if (sprint1Issues.length > 0 && teamMembers.length > 0) {
      console.log('\n📝 Asignando Sprint 1 a miembros del equipo...');
      
      for (let i = 0; i < sprint1Issues.length; i++) {
        const issue = sprint1Issues[i];
        const member = teamMembers[i % teamMembers.length]; // Rotar entre miembros
        
        console.log(`   📋 Asignando: ${issue.title} → ${member.name}`);
        
        const assignIssueMutation = `
          mutation {
            issueUpdate(
              id: "${issue.id}"
              input: {
                assigneeId: "${member.id}"
              }
            ) {
              success
              issue {
                id
                title
                number
                assignee {
                  name
                }
              }
            }
          }
        `;

        try {
          const assignResponse = await makeLinearRequest(assignIssueMutation);
          
          if (assignResponse.data.issueUpdate?.success) {
            const assignedIssue = assignResponse.data.issueUpdate.issue;
            console.log(`      ✅ Asignado a: ${assignedIssue.assignee.name}`);
          } else {
            console.log(`      ❌ Error asignando: ${issue.title}`);
          }
        } catch (error) {
          console.log(`      ❌ Error: ${error.message}`);
        }
      }
    }

    // 7. Resumen final
    console.log('\n🎉 ¡Organización de sprints completada!');
    console.log('─'.repeat(60));
    console.log(`📋 Sprints creados: ${Object.keys(createdSprints).length}/3`);
    console.log(`📋 Historias asignadas a sprints: ${totalAssigned}`);
    console.log(`👥 Miembros del equipo: ${teamMembers.length}`);

    console.log('\n📊 RESUMEN DE SPRINTS:');
    console.log('─'.repeat(60));
    console.log('🚀 Sprint Testing 1 - Configuración y Core:');
    console.log(`   📋 Historias: ${sprint1Issues.length}`);
    console.log(`   📊 Story Points: ${sprint1Issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0)}`);
    console.log(`   ⏱️  Duración: 2 semanas`);
    
    console.log('\n🚀 Sprint Testing 2 - Infrastructure y Integration:');
    console.log(`   📋 Historias: ${sprint2Issues.length}`);
    console.log(`   📊 Story Points: ${sprint2Issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0)}`);
    console.log(`   ⏱️  Duración: 2 semanas`);
    
    console.log('\n🚀 Sprint Testing 3 - E2E y Documentación:');
    console.log(`   📋 Historias: ${sprint3Issues.length}`);
    console.log(`   📊 Story Points: ${sprint3Issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0)}`);
    console.log(`   ⏱️  Duración: 2 semanas`);

    const totalPoints = testingIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
    console.log(`\n📊 TOTAL: ${totalPoints} story points en ${testingIssues.length} historias`);

  } catch (error) {
    console.error('❌ Error organizando sprints:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
organizeTestingSprints();
