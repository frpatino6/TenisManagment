const { getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function getTestingSprint1Stories() {
  try {
    console.log('🔍 Obteniendo historias del Sprint Testing 1...\n');

    const config = getLinearConfig();
    console.log('📋 Configuración Linear:');
    console.log(`   Team ID: ${config.teamId}`);
    console.log(`   API Key: ${config.apiKey ? 'Configurada' : 'No configurada'}\n`);

    // Query para obtener historias del sprint Testing 1
    const query = `
      query GetSprintStories($teamId: String!) {
        team(id: $teamId) {
          issues(
            filter: {
              state: { name: { eq: "In Progress" } }
            }
            first: 50
          ) {
            nodes {
              id
              identifier
              title
              description
              state {
                name
              }
              priority
              estimate
              labels {
                nodes {
                  name
                }
              }
              project {
                name
              }
              assignee {
                name
              }
              createdAt
              updatedAt
            }
          }
          projects(
            filter: {
              name: { contains: "Testing" }
            }
            first: 10
          ) {
            nodes {
              id
              name
              state
              description
              issues {
                nodes {
                  id
                  identifier
                  title
                  state {
                    name
                  }
                  priority
                  estimate
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
      }
    `;

    const data = await makeLinearRequest(query, { teamId: config.teamId });

    if (data.errors) {
      console.error('❌ Errores en la query:', data.errors);
      return;
    }

    const team = data.data.team;
    
    console.log('📋 PROYECTOS DE TESTING ENCONTRADOS:');
    console.log('────────────────────────────────────────────────────────────');
    
    team.projects.nodes.forEach(project => {
      if (project.name.includes('Testing')) {
        console.log(`\n🏗️  Proyecto: ${project.name}`);
        console.log(`   Estado: ${project.state}`);
        console.log(`   Issues: ${project.issues.nodes.length}`);
        
        if (project.issues.nodes.length > 0) {
          console.log(`   \n   📋 Historias:`);
          project.issues.nodes.forEach(issue => {
            console.log(`      - ${issue.identifier}: ${issue.title}`);
            console.log(`        Estado: ${issue.state.name}`);
            console.log(`        Estimación: ${issue.estimate || 'No estimado'}`);
            console.log(`        Labels: ${issue.labels.nodes.map(l => l.name).join(', ') || 'Ninguno'}`);
            console.log('');
          });
        }
      }
    });

    console.log('\n📋 TODAS LAS HISTORIAS EN PROGRESO:');
    console.log('────────────────────────────────────────────────────────────');
    
    team.issues.nodes.forEach(issue => {
      if (issue.title.includes('Testing') || issue.project?.name.includes('Testing')) {
        console.log(`\n🎯 ${issue.identifier}: ${issue.title}`);
        console.log(`   Estado: ${issue.state.name}`);
        console.log(`   Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
        console.log(`   Estimación: ${issue.estimate || 'No estimado'}`);
        console.log(`   Prioridad: ${issue.priority}`);
        console.log(`   Labels: ${issue.labels.nodes.map(l => l.name).join(', ') || 'Ninguno'}`);
        console.log(`   Asignado: ${issue.assignee?.name || 'Sin asignar'}`);
        console.log(`   Creado: ${new Date(issue.createdAt).toLocaleDateString()}`);
        console.log(`   Actualizado: ${new Date(issue.updatedAt).toLocaleDateString()}`);
      }
    });

  } catch (error) {
    console.error('❌ Error obteniendo historias:', error.message);
  }
}

getTestingSprint1Stories();
