#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function getIssueDetails(issueNumber) {
  console.log(`🔍 Obteniendo detalles de la issue #${issueNumber}...\n`);

  try {
    const { teamId } = getLinearConfig();
    
    // Buscar la issue por número
    const issueQuery = `
      query {
        issue(number: ${issueNumber}) {
          id
          title
          number
          description
          state {
            name
            type
          }
          assignee {
            name
            email
          }
          estimate
          priority
          labels {
            nodes {
              name
            }
          }
          createdAt
          updatedAt
          url
        }
      }
    `;

    const issueResponse = await makeLinearRequest(issueQuery);
    const issue = issueResponse.data.issue;

    if (!issue) {
      console.log(`❌ No se encontró la issue #${issueNumber}`);
      return;
    }

    console.log(`📋 Issue #${issue.number}: ${issue.title}`);
    console.log(`👤 Asignado: ${issue.assignee?.name || 'Sin asignar'}`);
    console.log(`📊 Story Points: ${issue.estimate || 'Sin estimar'}`);
    console.log(`⚡ Prioridad: ${issue.priority || 'Sin prioridad'}`);
    console.log(`📊 Estado: ${issue.state.name}`);
    console.log(`🏷️  Labels: ${issue.labels?.nodes?.map(l => l.name).join(', ') || 'Sin labels'}`);
    console.log(`🔗 URL: ${issue.url}`);
    console.log(`📅 Creado: ${new Date(issue.createdAt).toLocaleDateString()}`);
    console.log(`📅 Actualizado: ${new Date(issue.updatedAt).toLocaleDateString()}`);

    if (issue.description) {
      console.log('\n📄 DESCRIPCIÓN COMPLETA:');
      console.log('═'.repeat(80));
      console.log(issue.description);
      console.log('═'.repeat(80));
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('🔍 Detalles:', error);
  }
}

// Obtener el número de issue del argumento de línea de comandos
const issueNumber = process.argv[2];
if (!issueNumber) {
  console.log('❌ Por favor proporciona el número de issue');
  console.log('💡 Uso: node get-issue-details.js <número>');
  process.exit(1);
}

getIssueDetails(issueNumber);


