#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function checkCycles() {
  console.log('🔄 Verificando Cycles en Linear...\n');

  try {
    const { teamId, apiKey } = getLinearConfig();
    console.log(`🔍 Team ID: ${teamId}`);
    console.log(`🔑 API Key: ${apiKey.substring(0, 10)}...`);
    
    // Consulta simple para obtener información del team
    const teamQuery = `
      query {
        team(id: "${teamId}") {
          id
          name
          key
          description
        }
      }
    `;

    console.log('🔍 Consultando información del team...');
    const teamResponse = await makeLinearRequest(teamQuery);
    
    if (teamResponse.errors) {
      console.log('❌ Errores en la consulta:', teamResponse.errors);
      return;
    }

    if (!teamResponse.data || !teamResponse.data.team) {
      console.log('❌ No se pudo obtener información del team');
      console.log('📋 Respuesta completa:', JSON.stringify(teamResponse, null, 2));
      return;
    }

    const team = teamResponse.data.team;
    console.log(`✅ Team encontrado: ${team.name} (${team.key})`);
    console.log(`📝 Descripción: ${team.description || 'Sin descripción'}`);

    // Ahora intentar obtener cycles
    const cyclesQuery = `
      query {
        team(id: "${teamId}") {
          cycles(first: 10) {
            nodes {
              id
              number
              name
              state
              startsAt
              endsAt
            }
          }
        }
      }
    `;

    console.log('\n🔍 Consultando cycles...');
    const cyclesResponse = await makeLinearRequest(cyclesQuery);
    
    if (cyclesResponse.errors) {
      console.log('❌ Errores en la consulta de cycles:', cyclesResponse.errors);
      return;
    }

    const cycles = cyclesResponse.data.team.cycles.nodes;
    console.log(`🔄 Cycles encontrados: ${cycles.length}`);

    if (cycles.length === 0) {
      console.log('❌ No se encontraron cycles en este team');
      console.log('💡 Esto puede significar que:');
      console.log('   - No se han creado cycles/sprints aún');
      console.log('   - Los cycles están en otro team');
      console.log('   - La configuración de cycles está deshabilitada');
      return;
    }

    cycles.forEach(cycle => {
      const startDate = cycle.startsAt ? new Date(cycle.startsAt).toLocaleDateString() : 'Sin fecha';
      const endDate = cycle.endsAt ? new Date(cycle.endsAt).toLocaleDateString() : 'Sin fecha';
      
      console.log(`\n🔄 Cycle #${cycle.number}: ${cycle.name || 'Sin nombre'}`);
      console.log(`   📊 Estado: ${cycle.state}`);
      console.log(`   📅 Inicio: ${startDate}`);
      console.log(`   📅 Fin: ${endDate}`);
    });

    // Resumen
    const activeCycles = cycles.filter(cycle => cycle.state === 'active');
    const completedCycles = cycles.filter(cycle => cycle.state === 'completed');
    const plannedCycles = cycles.filter(cycle => cycle.state === 'planned');
    
    console.log('\n📊 RESUMEN:');
    console.log(`   🔄 Total cycles: ${cycles.length}`);
    console.log(`   🟢 Activos: ${activeCycles.length}`);
    console.log(`   ✅ Completados: ${completedCycles.length}`);
    console.log(`   📋 Planificados: ${plannedCycles.length}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('🔍 Detalles:', error);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  checkCycles();
}

module.exports = { checkCycles };
