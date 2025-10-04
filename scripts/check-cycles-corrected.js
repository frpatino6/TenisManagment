#!/usr/bin/env node

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function checkCycles() {
  console.log('🔄 Verificando Cycles en Linear...\n');

  try {
    const { teamId } = getLinearConfig();
    
    // Consulta corregida para cycles
    const cyclesQuery = `
      query {
        team(id: "${teamId}") {
          cycles(first: 10) {
            nodes {
              id
              number
              name
              description
              startsAt
              endsAt
              completedAt
              createdAt
              updatedAt
            }
          }
        }
      }
    `;

    console.log('🔍 Consultando cycles...');
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
      const completedDate = cycle.completedAt ? new Date(cycle.completedAt).toLocaleDateString() : 'No completado';
      const createdDate = cycle.createdAt ? new Date(cycle.createdAt).toLocaleDateString() : 'Sin fecha';
      
      console.log(`\n🔄 Cycle #${cycle.number}: ${cycle.name || 'Sin nombre'}`);
      console.log(`   📝 Descripción: ${cycle.description || 'Sin descripción'}`);
      console.log(`   📅 Creado: ${createdDate}`);
      console.log(`   📅 Inicio: ${startDate}`);
      console.log(`   📅 Fin: ${endDate}`);
      console.log(`   ✅ Completado: ${completedDate}`);
      
      // Determinar estado basado en fechas
      let status = '📋 Planificado';
      const now = new Date();
      if (cycle.completedAt) {
        status = '✅ Completado';
      } else if (cycle.startsAt && new Date(cycle.startsAt) <= now && (!cycle.endsAt || new Date(cycle.endsAt) >= now)) {
        status = '🟢 Activo';
      } else if (cycle.endsAt && new Date(cycle.endsAt) < now) {
        status = '⏰ Vencido';
      }
      console.log(`   📊 Estado: ${status}`);
    });

    // Resumen
    const now = new Date();
    const activeCycles = cycles.filter(cycle => {
      if (cycle.completedAt) return false;
      return cycle.startsAt && new Date(cycle.startsAt) <= now && (!cycle.endsAt || new Date(cycle.endsAt) >= now);
    });
    const completedCycles = cycles.filter(cycle => cycle.completedAt);
    const plannedCycles = cycles.filter(cycle => {
      if (cycle.completedAt) return false;
      return !cycle.startsAt || new Date(cycle.startsAt) > now;
    });
    const overdueCycles = cycles.filter(cycle => {
      if (cycle.completedAt) return false;
      return cycle.endsAt && new Date(cycle.endsAt) < now;
    });
    
    console.log('\n📊 RESUMEN DE CYCLES:');
    console.log(`   🔄 Total cycles: ${cycles.length}`);
    console.log(`   🟢 Activos: ${activeCycles.length}`);
    console.log(`   ✅ Completados: ${completedCycles.length}`);
    console.log(`   📋 Planificados: ${plannedCycles.length}`);
    console.log(`   ⏰ Vencidos: ${overdueCycles.length}`);

    // Mostrar detalles de cycles activos
    if (activeCycles.length > 0) {
      console.log('\n🟢 CYCLES ACTIVOS:');
      activeCycles.forEach(cycle => {
        const startDate = cycle.startsAt ? new Date(cycle.startsAt).toLocaleDateString() : 'Sin fecha';
        const endDate = cycle.endsAt ? new Date(cycle.endsAt).toLocaleDateString() : 'Sin fecha';
        console.log(`   🔄 #${cycle.number}: ${cycle.name || 'Sin nombre'} (${startDate} - ${endDate})`);
      });
    }

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
