#!/usr/bin/env node

/**
 * Script para crear automáticamente feature branches para historias de Linear
 * Tennis Management System
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Mapeo de issues de Linear a nombres de branch
const issueBranchMap = {
  'TEN-001': 'feature/TEN-001-modelo-datos-mensajes',
  'TEN-002': 'feature/TEN-002-api-mensajeria', 
  'TEN-003': 'feature/TEN-003-middleware-autenticacion',
  'TEN-004': 'feature/TEN-004-endpoints-chat',
  'TEN-005': 'feature/TEN-005-pantalla-lista-conversaciones',
  'TEN-006': 'feature/TEN-006-pantalla-chat-individual',
  'TEN-007': 'feature/TEN-007-integracion-perfil-estudiante',
  'TEN-008': 'feature/TEN-008-estados-carga-error',
  'TEN-009': 'feature/TEN-009-notificaciones-tiempo-real',
  'TEN-010': 'feature/TEN-010-api-historial-clases',
  'TEN-011': 'feature/TEN-011-pantalla-historial-clases',
  'TEN-012': 'feature/TEN-012-optimizaciones-testing'
};

function createFeatureBranch(issueNumber) {
  try {
    console.log(`🚀 Creando feature branch para ${issueNumber}...\n`);

    // Verificar que el issue existe en el mapeo
    if (!issueBranchMap[issueNumber]) {
      console.log(`❌ Error: No se encontró mapeo para ${issueNumber}`);
      console.log(`📋 Issues disponibles:`);
      Object.keys(issueBranchMap).forEach(issue => {
        console.log(`   - ${issue}: ${issueBranchMap[issue]}`);
      });
      return false;
    }

    const branchName = issueBranchMap[issueNumber];
    
    console.log(`📋 Issue: ${issueNumber}`);
    console.log(`🌿 Branch: ${branchName}\n`);

    // 1. Verificar estado actual
    console.log('1️⃣ Verificando estado actual...');
    const currentBranch = execSync('git branch --show-current', { encoding: 'utf8' }).trim();
    console.log(`   📍 Branch actual: ${currentBranch}`);

    // 2. Cambiar a main
    console.log('\n2️⃣ Cambiando a main branch...');
    execSync('git checkout main', { stdio: 'inherit' });
    console.log('   ✅ Cambiado a main');

    // 3. Pull latest changes
    console.log('\n3️⃣ Actualizando main branch...');
    execSync('git pull origin main', { stdio: 'inherit' });
    console.log('   ✅ Main actualizado');

    // 4. Verificar si el branch ya existe
    console.log('\n4️⃣ Verificando si el branch ya existe...');
    try {
      execSync(`git show-ref --verify --quiet refs/heads/${branchName}`);
      console.log(`   ⚠️  El branch ${branchName} ya existe`);
      
      // Preguntar si quiere cambiar a ese branch
      console.log(`   🔄 Cambiando al branch existente...`);
      execSync(`git checkout ${branchName}`, { stdio: 'inherit' });
      console.log(`   ✅ Cambiado al branch existente: ${branchName}`);
    } catch (error) {
      // El branch no existe, crearlo
      console.log(`   📝 El branch no existe, creándolo...`);
      execSync(`git checkout -b ${branchName}`, { stdio: 'inherit' });
      console.log(`   ✅ Branch creado: ${branchName}`);
    }

    // 5. Verificar branch actual
    console.log('\n5️⃣ Verificando branch actual...');
    const newBranch = execSync('git branch --show-current', { encoding: 'utf8' }).trim();
    console.log(`   📍 Branch actual: ${newBranch}`);

    // 6. Mostrar resumen
    console.log('\n🎉 ¡Feature branch creado exitosamente!');
    console.log('─'.repeat(50));
    console.log(`📋 Issue: ${issueNumber}`);
    console.log(`🌿 Branch: ${newBranch}`);
    console.log(`📍 Estado: Listo para desarrollo`);
    console.log('─'.repeat(50));

    console.log('\n📝 Próximos pasos:');
    console.log('1. Actualizar estado en Linear a "In Progress"');
    console.log('2. Comenzar desarrollo según criterios de aceptación');
    console.log('3. Commit con referencia al issue: "feat(TEN-XXX): implement feature"');
    console.log('4. Crear pull request cuando esté listo');

    return true;

  } catch (error) {
    console.error('❌ Error creando feature branch:', error.message);
    return false;
  }
}

// Función para mostrar ayuda
function showHelp() {
  console.log('🚀 Script para crear feature branches automáticamente\n');
  console.log('📋 Uso:');
  console.log('   node scripts/create-feature-branch.js TEN-001');
  console.log('   node scripts/create-feature-branch.js TEN-002');
  console.log('   node scripts/create-feature-branch.js TEN-003\n');
  
  console.log('📋 Issues disponibles:');
  Object.keys(issueBranchMap).forEach(issue => {
    console.log(`   - ${issue}: ${issueBranchMap[issue]}`);
  });
  
  console.log('\n💡 Ejemplo:');
  console.log('   node scripts/create-feature-branch.js TEN-001');
  console.log('   # Esto creará: feature/TEN-001-modelo-datos-mensajes');
}

// Función principal
function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    showHelp();
    return;
  }

  const issueNumber = args[0].toUpperCase();
  
  if (!issueNumber.startsWith('TEN-')) {
    console.log('❌ Error: El issue debe comenzar con "TEN-"');
    console.log('💡 Ejemplo: TEN-001, TEN-002, etc.');
    return;
  }

  const success = createFeatureBranch(issueNumber);
  
  if (!success) {
    process.exit(1);
  }
}

// Ejecutar si es llamado directamente
if (require.main === module) {
  main();
}

module.exports = { createFeatureBranch, issueBranchMap };
