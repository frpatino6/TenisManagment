#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function listLinearIssues() {
  console.log('📋 Listando issues de Linear...\n');

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
              id
              name
              email
            }
            estimate
            priority
            state {
              id
              name
              type
            }
            team {
              id
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
    
    console.log(`📊 Total de issues: ${allIssues.length}`);
    
    // Mostrar resumen
    let assignedIssues = 0;
    let issuesWithPoints = 0;
    let totalPoints = 0;

    allIssues.forEach(issue => {
      if (issue.assignee) assignedIssues++;
      if (issue.estimate) {
        issuesWithPoints++;
        totalPoints += issue.estimate;
      }
    });

    console.log('\n📊 Resumen:');
    console.log(`- Issues Asignados: ${assignedIssues}/${allIssues.length} (${Math.round(assignedIssues/allIssues.length*100)}%)`);
    console.log(`- Issues con Story Points: ${issuesWithPoints}/${allIssues.length} (${Math.round(issuesWithPoints/allIssues.length*100)}%)`);
    console.log(`- Total Story Points: ${totalPoints}`);

    // Mostrar issues por categoría
    console.log('\n📋 Issues por categoría:');
    
    const issuesByCategory = {
      'Multi-Tenancy': allIssues.filter(issue => issue.title.includes('MT-')),
      'Authentication': allIssues.filter(issue => issue.title.includes('AUTH-')),
      'Onboarding': allIssues.filter(issue => issue.title.includes('ONB-')),
      'Billing': allIssues.filter(issue => issue.title.includes('BILL-')),
      'Admin': allIssues.filter(issue => issue.title.includes('ADMIN-')),
      'Analytics': allIssues.filter(issue => issue.title.includes('ANALYTICS-')),
      'Mobile': allIssues.filter(issue => issue.title.includes('MOBILE-')),
      'GTM': allIssues.filter(issue => issue.title.includes('GTM-')),
      'Epics': allIssues.filter(issue => issue.title.includes('EPIC') || issue.title.includes('Epic'))
    };

    Object.entries(issuesByCategory).forEach(([category, issues]) => {
      if (issues.length > 0) {
        const categoryPoints = issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        console.log(`\n🔸 ${category}: ${issues.length} issues, ${categoryPoints} pts`);
        issues.forEach(issue => {
          const assignee = issue.assignee ? '✅' : '❌';
          const points = issue.estimate ? issue.estimate : 'N/A';
          console.log(`   ${issue.number.toString().padStart(3)} | ${issue.title.substring(0, 40).padEnd(40)} | ${assignee} | ${points} pts`);
        });
      }
    });

    console.log('\n🎉 ¡Listado completado!');
    console.log('💡 Para configurar la API key, crea un archivo linear-config.env con:');
    console.log('   LINEAR_API_KEY=tu_api_key_aqui');
    console.log('   LINEAR_TEAM_ID=tu_team_id_aqui');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('\n💡 Asegúrate de tener configurado linear-config.env con:');
    console.log('   LINEAR_API_KEY=tu_api_key_aqui');
    console.log('   LINEAR_TEAM_ID=tu_team_id_aqui');
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  listLinearIssues();
}

module.exports = { listLinearIssues };
