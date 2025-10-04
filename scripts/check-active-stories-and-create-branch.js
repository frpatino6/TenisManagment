#!/usr/bin/env node

/**
 * Script para verificar historias activas y crear rama feature
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');
const { execSync } = require('child_process');

async function checkActiveStoriesAndCreateBranch() {
  try {
    console.log('🔍 Verificando historias activas y creando rama...\n');

    // 1. Obtener historias en "In Progress"
    console.log('📋 Obteniendo historias en "In Progress"...');
    
    const getActiveIssuesQuery = `
      query {
        issues(first: 20, filter: { 
          state: { name: { eq: "In Progress" } }
        }) {
          nodes {
            id
            title
            number
            state {
              name
            }
            cycle {
              name
            }
            assignee {
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

    const issuesResponse = await makeLinearRequest(getActiveIssuesQuery);
    const activeIssues = issuesResponse.data.issues.nodes;

    console.log(`📊 Historias en "In Progress": ${activeIssues.length}`);

    // Filtrar solo las historias de testing
    const testingIssues = activeIssues.filter(issue => 
      issue.labels.nodes.some(label => label.name === 'testing')
    );

    console.log(`📊 Historias de testing activas: ${testingIssues.length}`);

    if (testingIssues.length === 0) {
      console.log('❌ No hay historias de testing en "In Progress"');
      return;
    }

    // 2. Mostrar historias activas
    console.log('\n📋 HISTORIAS ACTIVAS:');
    console.log('─'.repeat(60));
    
    testingIssues.forEach((issue, index) => {
      console.log(`${index + 1}. ${issue.title} (#${issue.number})`);
      console.log(`   Sprint: ${issue.cycle?.name || 'Sin sprint'}`);
      console.log(`   Asignado a: ${issue.assignee?.name || 'Sin asignar'}`);
      console.log('');
    });

    // 3. Seleccionar la primera historia para crear rama
    const selectedIssue = testingIssues[0];
    console.log(`🎯 Seleccionando: ${selectedIssue.title} (#${selectedIssue.number})`);

    // 4. Crear nombre de rama
    const branchName = `feature/ts-${selectedIssue.number}-${selectedIssue.title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .substring(0, 50)}`;

    console.log(`🌿 Nombre de rama: ${branchName}`);

    // 5. Verificar si la rama ya existe
    console.log('\n🔍 Verificando si la rama ya existe...');
    
    try {
      const existingBranches = execSync('git branch -a', { encoding: 'utf8' });
      const branchExists = existingBranches.includes(branchName);
      
      if (branchExists) {
        console.log(`⚠️  La rama ${branchName} ya existe`);
        console.log('🔄 Cambiando a la rama existente...');
        execSync(`git checkout ${branchName}`, { stdio: 'inherit' });
        console.log(`✅ Cambiado a la rama: ${branchName}`);
        return;
      }
    } catch (error) {
      console.log('⚠️  Error verificando ramas existentes:', error.message);
    }

    // 6. Crear nueva rama
    console.log('\n🌿 Creando nueva rama...');
    
    try {
      // Asegurarse de estar en main
      console.log('📋 Cambiando a rama main...');
      execSync('git checkout main', { stdio: 'inherit' });
      
      // Pull latest changes
      console.log('📥 Obteniendo últimos cambios...');
      execSync('git pull origin main', { stdio: 'inherit' });
      
      // Crear nueva rama
      console.log(`🌿 Creando rama: ${branchName}`);
      execSync(`git checkout -b ${branchName}`, { stdio: 'inherit' });
      
      console.log(`✅ Rama creada exitosamente: ${branchName}`);
      
    } catch (error) {
      console.error('❌ Error creando rama:', error.message);
      return;
    }

    // 7. Verificar estado final
    console.log('\n🔍 Verificando estado final...');
    
    try {
      const currentBranch = execSync('git branch --show-current', { encoding: 'utf8' }).trim();
      console.log(`✅ Rama actual: ${currentBranch}`);
      
      const branchStatus = execSync('git status --porcelain', { encoding: 'utf8' });
      if (branchStatus.trim()) {
        console.log('📝 Archivos modificados:');
        console.log(branchStatus);
      } else {
        console.log('✅ Working directory limpio');
      }
      
    } catch (error) {
      console.log('⚠️  Error verificando estado:', error.message);
    }

    // 8. Resumen final
    console.log('\n🎉 RESUMEN FINAL:');
    console.log('─'.repeat(60));
    console.log(`📋 Historia: ${selectedIssue.title} (#${selectedIssue.number})`);
    console.log(`🌿 Rama: ${branchName}`);
    console.log(`👤 Asignado a: ${selectedIssue.assignee?.name || 'Sin asignar'}`);
    console.log(`🚀 Sprint: ${selectedIssue.cycle?.name || 'Sin sprint'}`);
    
    console.log('\n💡 PRÓXIMOS PASOS:');
    console.log('1. El agente puede continuar trabajando en esta rama');
    console.log('2. Hacer commits con mensajes descriptivos');
    console.log('3. Push de la rama cuando esté listo');
    console.log('4. Crear Pull Request hacia main');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
checkActiveStoriesAndCreateBranch();
