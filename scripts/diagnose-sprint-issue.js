#!/usr/bin/env node

/**
 * Script para diagnosticar el problema del sprint vacío
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function diagnoseSprintIssue() {
  try {
    console.log('🔍 Diagnosticando problema del sprint vacío...\n');

    const { teamId } = getLinearConfig();

    // 1. Obtener todas las historias TS-XXX
    console.log('📋 Obteniendo historias TS-XXX...');
    
    const getTSIssuesQuery = `
      query {
        issues(first: 50, filter: { 
          labels: { name: { eq: "testing" } }
        }) {
          nodes {
            id
            title
            number
            state {
              name
            }
            cycle {
              id
              name
              number
            }
            project {
              name
            }
          }
        }
      }
    `;

    const tsIssuesResponse = await makeLinearRequest(getTSIssuesQuery);
    const allTSIssues = tsIssuesResponse.data.issues.nodes.filter(issue => 
      issue.title.startsWith('TS-')
    );

    console.log(`📊 Total historias TS-XXX: ${allTSIssues.length}`);

    // 2. Agrupar por sprint
    const sprintGroups = {};
    const unassignedIssues = [];

    allTSIssues.forEach(issue => {
      if (issue.cycle) {
        const sprintName = issue.cycle.name;
        if (!sprintGroups[sprintName]) {
          sprintGroups[sprintName] = [];
        }
        sprintGroups[sprintName].push(issue);
      } else {
        unassignedIssues.push(issue);
      }
    });

    console.log('\n📊 DISTRIBUCIÓN POR SPRINTS:');
    console.log('─'.repeat(60));
    
    Object.entries(sprintGroups).forEach(([sprintName, issues]) => {
      console.log(`🚀 ${sprintName}:`);
      console.log(`   📊 Issues: ${issues.length}`);
      issues.forEach(issue => {
        console.log(`      - ${issue.title} (#${issue.number})`);
      });
      console.log('');
    });

    if (unassignedIssues.length > 0) {
      console.log('❌ ISSUES SIN SPRINT:');
      console.log('─'.repeat(60));
      unassignedIssues.forEach(issue => {
        console.log(`📋 ${issue.title} (#${issue.number})`);
      });
      console.log('');
    }

    // 3. Verificar específicamente el Sprint Testing 1
    const sprintTesting1Issues = sprintGroups['Sprint Testing 1 - Configuración y Core'] || [];
    
    console.log('🎯 ANÁLISIS DEL SPRINT TESTING 1:');
    console.log('─'.repeat(60));
    console.log(`📊 Issues en Sprint Testing 1: ${sprintTesting1Issues.length}`);
    
    if (sprintTesting1Issues.length === 0) {
      console.log('❌ PROBLEMA: Sprint Testing 1 está vacío');
      console.log('');
      console.log('💡 POSIBLES CAUSAS:');
      console.log('1. Las historias no están asignadas al sprint correcto');
      console.log('2. El sprint no existe o tiene un nombre diferente');
      console.log('3. Problema de sincronización en Linear');
      console.log('');
      console.log('🔧 SOLUCIÓN:');
      console.log('Necesitamos reasignar las historias al sprint correcto');
      
      // Buscar historias que deberían estar en Sprint 1
      const sprint1ExpectedIssues = [
        'TS-001', 'TS-002', 'TS-003', 'TS-004', 'TS-005',
        'TS-007', 'TS-008', 'TS-009', 'TS-012', 'TS-013',
        'TS-016', 'TS-017', 'TS-018', 'TS-020', 'TS-021',
        'TS-022', 'TS-025'
      ];

      const shouldBeInSprint1 = allTSIssues.filter(issue => 
        sprint1ExpectedIssues.some(tsNumber => issue.title.includes(tsNumber))
      );

      console.log(`\n📋 Historias que deberían estar en Sprint 1: ${shouldBeInSprint1.length}`);
      
      if (shouldBeInSprint1.length > 0) {
        console.log('\n📋 LISTA DE HISTORIAS A REASIGNAR:');
        shouldBeInSprint1.forEach(issue => {
          console.log(`   - ${issue.title} (#${issue.number})`);
          console.log(`     Sprint actual: ${issue.cycle?.name || 'Sin sprint'}`);
        });
      }
      
    } else {
      console.log('✅ Sprint Testing 1 tiene issues asignadas');
      console.log('\n📋 ISSUES EN SPRINT TESTING 1:');
      sprintTesting1Issues.forEach(issue => {
        console.log(`   - ${issue.title} (#${issue.number}) - ${issue.state.name}`);
      });
    }

    // 4. Verificar si el problema es de visualización
    console.log('\n🔍 DIAGNÓSTICO DE VISUALIZACIÓN:');
    console.log('─'.repeat(60));
    
    if (sprintTesting1Issues.length > 0) {
      console.log('✅ Las historias SÍ están asignadas al sprint');
      console.log('❌ El problema es de visualización en la interfaz de Linear');
      console.log('');
      console.log('💡 SOLUCIONES POSIBLES:');
      console.log('1. Refrescar la página en Linear');
      console.log('2. Verificar filtros activos en Linear');
      console.log('3. Cambiar la vista (Lista vs Board vs Timeline)');
      console.log('4. Verificar que estás en el sprint correcto');
    } else {
      console.log('❌ Las historias NO están asignadas al sprint');
      console.log('🔧 Necesitamos reasignar las historias');
    }

  } catch (error) {
    console.error('❌ Error en diagnóstico:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
diagnoseSprintIssue();
