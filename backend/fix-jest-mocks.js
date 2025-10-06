#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Función para arreglar los mocks de Jest en un archivo
function fixJestMocks(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;

  // Patrón para encontrar mocks que necesitan ser tipados
  const mockPatterns = [
    // mockResolvedValue con tipos específicos
    {
      pattern: /jest\.fn\(\)\.mockResolvedValue\(([^)]+)\)/g,
      replacement: 'jest.fn().mockResolvedValue($1 as any)'
    },
    // mockReturnValue con tipos específicos
    {
      pattern: /jest\.fn\(\)\.mockReturnValue\(([^)]+)\)/g,
      replacement: 'jest.fn().mockReturnValue($1 as any)'
    },
    // mockImplementation con tipos específicos
    {
      pattern: /jest\.fn\(\)\.mockImplementation\(([^)]+)\)/g,
      replacement: 'jest.fn().mockImplementation($1 as any)'
    }
  ];

  // Aplicar las correcciones
  mockPatterns.forEach(({ pattern, replacement }) => {
    const newContent = content.replace(pattern, replacement);
    if (newContent !== content) {
      content = newContent;
      modified = true;
    }
  });

  // Si se hicieron cambios, escribir el archivo
  if (modified) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`✅ Fixed Jest mocks in: ${filePath}`);
    return true;
  }

  return false;
}

// Función para procesar todos los archivos de test
function processTestFiles() {
  const testDir = path.join(__dirname, 'src', '__tests__');
  
  if (!fs.existsSync(testDir)) {
    console.log('❌ Test directory not found');
    return;
  }

  let totalFixed = 0;

  function processDirectory(dir) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory()) {
        processDirectory(filePath);
      } else if (file.endsWith('.test.ts')) {
        if (fixJestMocks(filePath)) {
          totalFixed++;
        }
      }
    });
  }

  processDirectory(testDir);
  
  console.log(`\n🎉 Fixed Jest mocks in ${totalFixed} test files`);
}

// Ejecutar el script
console.log('🔧 Fixing Jest mock types in test files...\n');
processTestFiles();
