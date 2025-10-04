const { getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function analyzeTestingOrder() {
  try {
    console.log('🔍 Analizando orden lógico de las historias de Testing 1...\n');

    const config = getLinearConfig();

    // Query para obtener detalles de las historias específicas
    const query = `
      query GetTestingStories($teamId: String!) {
        team(id: $teamId) {
          issues(
            filter: {
              identifier: { in: ["TEN-81", "TEN-78", "TEN-77", "TEN-76", "TEN-74"] }
            }
            first: 10
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

    const stories = data.data.team.issues.nodes;

    console.log('📋 ANÁLISIS DEL ORDEN LÓGICO DE TESTING:\n');

    // Orden lógico basado en dependencias arquitectónicas
    const logicalOrder = [
      {
        identifier: 'TEN-81',
        title: 'TS-025: Configuración de CI/CD',
        reason: 'FUNDAMENTAL - Necesario para automatizar todos los tests',
        priority: 'CRÍTICA',
        dependencies: [],
        blocks: ['TEN-78', 'TEN-77', 'TEN-76', 'TEN-74']
      },
      {
        identifier: 'TEN-76',
        title: 'TS-020: Testing E2E - Authentication APIs',
        reason: 'BASE - Auth es prerrequisito para todos los otros E2E tests',
        priority: 'ALTA',
        dependencies: ['TEN-81'],
        blocks: ['TEN-78', 'TEN-77']
      },
      {
        identifier: 'TEN-74',
        title: 'TS-018: Testing de Integración - Student Flow',
        reason: 'INTEGRACIÓN - Necesario para validar flujos completos antes de E2E',
        priority: 'ALTA',
        dependencies: ['TEN-81'],
        blocks: []
      },
      {
        identifier: 'TEN-78',
        title: 'TS-022: Testing E2E - Student APIs',
        reason: 'E2E - Depende de auth y puede ejecutarse en paralelo con Professor',
        priority: 'MEDIA',
        dependencies: ['TEN-81', 'TEN-76'],
        blocks: []
      },
      {
        identifier: 'TEN-77',
        title: 'TS-021: Testing E2E - Professor APIs',
        reason: 'E2E - Depende de auth y puede ejecutarse en paralelo con Student',
        priority: 'MEDIA',
        dependencies: ['TEN-81', 'TEN-76'],
        blocks: []
      }
    ];

    console.log('🎯 ORDEN RECOMENDADO DE EJECUCIÓN:\n');
    
    logicalOrder.forEach((story, index) => {
      const storyData = stories.find(s => s.identifier === story.identifier);
      console.log(`${index + 1}. ${story.identifier}: ${story.title}`);
      console.log(`   📊 Estado actual: ${storyData?.state.name || 'No encontrado'}`);
      console.log(`   🎯 Prioridad: ${story.priority}`);
      console.log(`   💡 Razón: ${story.reason}`);
      console.log(`   🔗 Dependencias: ${story.dependencies.length > 0 ? story.dependencies.join(', ') : 'Ninguna'}`);
      console.log(`   🚫 Bloquea: ${story.blocks.length > 0 ? story.blocks.join(', ') : 'Ninguna'}`);
      console.log(`   ⏱️  Estimación: ${storyData?.estimate || 'N/A'} story points`);
      console.log('');
    });

    console.log('📋 ANÁLISIS DE DEPENDENCIAS:\n');
    console.log('🔴 BLOQUEANTES CRÍTICOS:');
    console.log('   - TEN-81 (CI/CD) debe completarse PRIMERO');
    console.log('   - Sin CI/CD no se pueden automatizar los tests');
    console.log('');
    console.log('🟡 DEPENDENCIAS IMPORTANTES:');
    console.log('   - TEN-76 (Auth E2E) es base para TEN-78 y TEN-77');
    console.log('   - Auth debe funcionar antes de testear APIs específicas');
    console.log('');
    console.log('🟢 PARALELIZABLES:');
    console.log('   - TEN-78 (Student E2E) y TEN-77 (Professor E2E) pueden ejecutarse en paralelo');
    console.log('   - TEN-74 (Integration) puede ejecutarse independientemente');
    console.log('');

    console.log('⏰ CRONOGRAMA RECOMENDADO:\n');
    console.log('📅 FASE 1 (Días 1-2):');
    console.log('   ✅ TEN-81: Configuración de CI/CD (3 SP)');
    console.log('');
    console.log('📅 FASE 2 (Días 3-4):');
    console.log('   ✅ TEN-76: Auth E2E (5 SP)');
    console.log('   ✅ TEN-74: Student Integration (5 SP) - En paralelo');
    console.log('');
    console.log('📅 FASE 3 (Días 5-7):');
    console.log('   ✅ TEN-78: Student E2E (6 SP) - En paralelo');
    console.log('   ✅ TEN-77: Professor E2E (6 SP) - En paralelo');
    console.log('');
    console.log('📊 RESUMEN:');
    console.log(`   Total Story Points: ${stories.reduce((sum, s) => sum + (s.estimate || 0), 0)}`);
    console.log(`   Duración estimada: 5-7 días`);
    console.log(`   Paralelización: 60% (3 de 5 historias)`);

  } catch (error) {
    console.error('❌ Error analizando orden:', error.message);
  }
}

analyzeTestingOrder();
