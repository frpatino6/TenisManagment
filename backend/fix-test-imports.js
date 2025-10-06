#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Lista de archivos de testing que necesitan las importaciones de Jest
const testFiles = [
  'src/__tests__/unit/AnalyticsController.test.ts',
  'src/__tests__/unit/AuthController.test.ts',
  'src/__tests__/unit/FirebaseAuthController.test.ts',
  'src/__tests__/unit/MongoConversationRepository.test.ts',
  'src/__tests__/unit/PricingController.test.ts',
  'src/__tests__/unit/ProfessorController.test.ts',
  'src/__tests__/unit/ProfessorDashboardController.test.ts',
  'src/__tests__/unit/StudentController.test.ts',
  'src/__tests__/unit/StudentDashboardController.test.ts',
  'src/__tests__/unit/firebase.test.ts',
  'src/__tests__/unit/firebaseAuthMiddleware.test.ts',
  'src/__tests__/unit/setup.test.ts',
  'src/__tests__/integration/auth-integration.test.ts',
  'src/__tests__/integration/messaging-flow.test.ts',
  'src/__tests__/integration/professor-flow.test.ts',
  'src/__tests__/integration/student-flow-basic.test.ts',
  'src/__tests__/integration/student-flow-simple.test.ts',
  'src/__tests__/e2e/auth-simple.test.ts',
  'src/__tests__/e2e/professor.test.ts',
  'src/__tests__/e2e/professor-dashboard.test.ts',
  'src/__tests__/e2e/student.test.ts',
  'src/__tests__/e2e/student-dashboard.test.ts'
];

function fixTestFile(filePath) {
  try {
    const fullPath = path.join(__dirname, filePath);
    
    if (!fs.existsSync(fullPath)) {
      console.log(`⚠️  Archivo no encontrado: ${filePath}`);
      return;
    }
    
    let content = fs.readFileSync(fullPath, 'utf8');
    
    // Verificar si ya tiene las importaciones de Jest
    if (content.includes("import { describe, it, beforeEach, expect, jest } from '@jest/globals'")) {
      console.log(`✅ Ya tiene importaciones: ${filePath}`);
      return;
    }
    
    // Buscar la primera línea de importación
    const lines = content.split('\n');
    let insertIndex = 0;
    
    // Encontrar dónde insertar las importaciones
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ') || lines[i].startsWith("import ")) {
        insertIndex = i;
        break;
      }
    }
    
    // Si no hay importaciones, insertar después de los comentarios
    if (insertIndex === 0) {
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim() === '' || lines[i].startsWith('//') || lines[i].startsWith('/**') || lines[i].startsWith(' *')) {
          insertIndex = i + 1;
        } else {
          break;
        }
      }
    }
    
    // Insertar las importaciones de Jest
    lines.splice(insertIndex, 0, "import { describe, it, beforeEach, expect, jest } from '@jest/globals';");
    
    // Escribir el archivo actualizado
    fs.writeFileSync(fullPath, lines.join('\n'));
    console.log(`✅ Arreglado: ${filePath}`);
    
  } catch (error) {
    console.error(`❌ Error procesando ${filePath}:`, error.message);
  }
}

console.log('🔧 Arreglando importaciones de Jest en archivos de testing...\n');

testFiles.forEach(fixTestFile);

console.log('\n✅ Proceso completado!');
