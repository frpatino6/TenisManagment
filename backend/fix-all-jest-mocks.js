#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Función para arreglar todos los tipos de mocks de Jest en un archivo
function fixAllJestMocks(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;

  // Patrones para diferentes tipos de errores de Jest
  const patterns = [
    // Arreglar mockImplementation con parámetros mal formateados
    {
      pattern: /jest\.fn\(\)\.mockImplementation\(\s*\(\s*as\s+any\s*\)\s*=>/g,
      replacement: 'jest.fn().mockImplementation(() =>'
    },
    // Arreglar mockReturnThis() que necesita as any
    {
      pattern: /jest\.fn\(\)\.mockReturnThis\(\)(?!\s*as\s+any)/g,
      replacement: 'jest.fn().mockReturnThis() as any'
    },
    // Arreglar mockResolvedValue que necesita as any
    {
      pattern: /jest\.fn\(\)\.mockResolvedValue\(([^)]+)\)(?!\s*as\s+any)/g,
      replacement: 'jest.fn().mockResolvedValue($1 as any)'
    },
    // Arreglar mockRejectedValue que necesita as any
    {
      pattern: /jest\.fn\(\)\.mockRejectedValue\(([^)]+)\)(?!\s*as\s+any)/g,
      replacement: 'jest.fn().mockRejectedValue($1 as any)'
    },
    // Arreglar mockReturnValue que necesita as any
    {
      pattern: /jest\.fn\(\)\.mockReturnValue\(([^)]+)\)(?!\s*as\s+any)/g,
      replacement: 'jest.fn().mockReturnValue($1 as any)'
    },
    // Arreglar global.testUtils
    {
      pattern: /global\.testUtils/g,
      replacement: '(global as any).testUtils'
    }
  ];

  // Aplicar las correcciones
  patterns.forEach(({ pattern, replacement }) => {
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
function processAllTestFiles() {
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
        if (fixAllJestMocks(filePath)) {
          totalFixed++;
        }
      }
    });
  }

  processDirectory(testDir);
  
  console.log(`\n🎉 Fixed Jest mocks in ${totalFixed} test files`);
}

// Ejecutar el script
console.log('🔧 Fixing all Jest mock types in test files...\n');
processAllTestFiles();
