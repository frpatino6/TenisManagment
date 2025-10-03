#!/usr/bin/env node

/**
 * Script para asignar todas las historias del Sprint 1
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function assignSprint1Stories() {
  try {
    console.log('👥 Asignando historias del Sprint 1...\n');

    const { teamId } = getLinearConfig();

    // Obtener usuarios del equipo
    const usersQuery = `
      query {
        team(id: "${teamId}") {
          members {
            nodes {
              id
              name
              email
              displayName
            }
          }
        }
      }
    `;

    const usersResponse = await makeLinearRequest(usersQuery);
    const teamMembers = usersResponse.data.team.members.nodes;

    console.log('👥 Miembros del equipo disponibles:');
    teamMembers.forEach((member, index) => {
      console.log(`  ${index + 1}. ${member.displayName || member.name} (${member.email})`);
    });

    // Por ahora, asignar al primer miembro del equipo (puedes cambiar esto)
    const assignee = teamMembers[0];
    if (!assignee) {
      console.log('❌ No hay miembros en el equipo');
      return;
    }

    console.log(`\n🎯 Asignando historias a: ${assignee.displayName || assignee.name}`);

    // Obtener historias del Sprint 1 (US-001 a US-004)
    const issuesQuery = `
      query {
        issues(first: 50) {
          nodes {
            id
            title
            number
            assignee {
              id
              name
            }
            estimate
            priority
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const allIssues = issuesResponse.data.issues.nodes;

    // Filtrar historias del Sprint 1 (US-001 a US-004)
    const sprint1Issues = allIssues.filter(issue => {
      const match = issue.title.match(/US-(\d{3}):/);
      if (match) {
        const number = parseInt(match[1]);
        return number >= 1 && number <= 4;
      }
      return false;
    });

    console.log(`📋 Encontradas ${sprint1Issues.length} historias del Sprint 1`);

    // Asignar historias
    let assignedCount = 0;
    for (const issue of sprint1Issues) {
      if (!issue.assignee || issue.assignee.id !== assignee.id) {
        console.log(`📝 Asignando: ${issue.title} (#${issue.number})`);
        
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              assigneeId: "${assignee.id}"
            }) {
              issue {
                id
                title
                assignee {
                  name
                }
              }
            }
          }
        `;
        
        try {
          const updateResponse = await makeLinearRequest(updateMutation);
          const updatedIssue = updateResponse.data.issueUpdate.issue;
          console.log(`  ✅ Asignado a: ${updatedIssue.assignee.name}`);
          assignedCount++;
        } catch (error) {
          console.log(`  ⚠️  Error: ${error.message}`);
        }
      } else {
        console.log(`ℹ️  ${issue.title} (#${issue.number}) ya está asignado a ${issue.assignee.name}`);
      }
    }

    console.log(`\n🎉 ¡Asignación completada!`);
    console.log(`📊 Historias asignadas: ${assignedCount}/${sprint1Issues.length}`);

    // Mostrar resumen del Sprint 1
    console.log('\n📋 RESUMEN DEL SPRINT 1 ASIGNADO:');
    console.log('─'.repeat(50));
    
    sprint1Issues.forEach(issue => {
      const priorityText = issue.priority === 1 ? '🔥 Urgent' : 
                          issue.priority === 2 ? '⚡ High' : 
                          issue.priority === 3 ? '💡 Medium' : '📝 Low';
      
      const assigneeName = issue.assignee ? issue.assignee.name : 'Sin asignar';
      
      console.log(`  ${issue.title} (#${issue.number})`);
      console.log(`    ${priorityText} | ${issue.estimate} pts | Asignado a: ${assigneeName}`);
      console.log('');
    });

    console.log('🚀 ¡Sprint 1 completamente configurado y asignado!');

  } catch (error) {
    console.error('❌ Error asignando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
assignSprint1Stories();
