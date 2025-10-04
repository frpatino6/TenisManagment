#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function getIssue71Details() {
  console.log('🔍 Obteniendo detalles de la issue #71 (TS-015: Testing de Autenticación Firebase)...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Buscar la issue por número usando el team
    const issueQuery = `
      query {
        team(id: "${teamId}") {
          issues(first: 50) {
            nodes {
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
        }
      }
    `;

    const issueResponse = await makeLinearRequest(issueQuery);
    const issues = issueResponse.data.team.issues.nodes;
    const issue = issues.find(i => i.number === 71);

    if (!issue) {
      console.log('❌ No se encontró la issue #71');
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

getIssue71Details();


