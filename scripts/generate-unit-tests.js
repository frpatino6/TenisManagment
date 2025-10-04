#!/usr/bin/env node

/**
 * Generador de Tests Unitarios para Tennis Management System
 * Crea tests unitarios automáticamente basado en archivos TypeScript
 */

const fs = require('fs');
const path = require('path');

// Configuración del generador
const CONFIG = {
  sourceDir: '/home/fernando/Documentos/TenisManagment/backend/src',
  testDir: '/home/fernando/Documentos/TenisManagment/backend/src/__tests__/unit',
  templates: {
    controller: 'controller.test.template',
    service: 'service.test.template',
    repository: 'repository.test.template',
    usecase: 'usecase.test.template',
    entity: 'entity.test.template',
    middleware: 'middleware.test.template'
  }
};

// Templates de tests
const TEST_TEMPLATES = {
  controller: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('{{className}}', () => {
  let controller: {{className}};
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new {{className}}();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', async () => {
      // Arrange
      const testData = TestDataFactory.create{{testDataType}}();
      mockRequest.body = testData;

      // Act
      await controller.{{methodName}}(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.{{methodName}}(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});`,

  service: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';

describe('{{className}}', () => {
  let service: {{className}};

  beforeEach(() => {
    service = new {{className}}();
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', async () => {
      // Arrange
      const input = {};

      // Act
      const result = await service.{{methodName}}(input);

      // Assert
      expect(result).toBeDefined();
    });

    it('should handle invalid input', async () => {
      // Arrange
      const invalidInput = null;

      // Act & Assert
      await expect(service.{{methodName}}(invalidInput)).rejects.toThrow();
    });
  });
});`,

  repository: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';
import { TestDataFactory } from '../utils/test-helpers';

describe('{{className}}', () => {
  let repository: {{className}};

  beforeEach(() => {
    repository = new {{className}}();
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', async () => {
      // Arrange
      const testData = TestDataFactory.create{{testDataType}}();

      // Act
      const result = await repository.{{methodName}}(testData);

      // Assert
      expect(result).toBeDefined();
    });

    it('should handle database errors', async () => {
      // Arrange
      const invalidData = {};

      // Act & Assert
      await expect(repository.{{methodName}}(invalidData)).rejects.toThrow();
    });
  });
});`,

  usecase: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';
import { TestDataFactory } from '../utils/test-helpers';

describe('{{className}}', () => {
  let useCase: {{className}};

  beforeEach(() => {
    useCase = new {{className}}();
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', async () => {
      // Arrange
      const input = TestDataFactory.create{{testDataType}}();

      // Act
      const result = await useCase.{{methodName}}(input);

      // Assert
      expect(result).toBeDefined();
    });

    it('should validate business rules', async () => {
      // Arrange
      const invalidInput = {};

      // Act & Assert
      await expect(useCase.{{methodName}}(invalidInput)).rejects.toThrow();
    });
  });
});`,

  entity: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';

describe('{{className}}', () => {
  describe('constructor', () => {
    it('should create instance with valid data', () => {
      // Arrange
      const data = {};

      // Act
      const entity = new {{className}}(data);

      // Assert
      expect(entity).toBeDefined();
    });

    it('should validate required fields', () => {
      // Arrange
      const invalidData = {};

      // Act & Assert
      expect(() => new {{className}}(invalidData)).toThrow();
    });
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', () => {
      // Arrange
      const entity = new {{className}}({});

      // Act
      const result = entity.{{methodName}}();

      // Assert
      expect(result).toBeDefined();
    });
  });
});`,

  middleware: `/**
 * Tests unitarios para {{className}}
 * Generado automáticamente el {{date}}
 */

import { {{className}} } from '{{importPath}}';
import { MockHelper } from '../utils/test-helpers';

describe('{{className}}', () => {
  let middleware: {{className}};
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    middleware = new {{className}}();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('{{methodName}}', () => {
    it('should {{testDescription}}', async () => {
      // Arrange
      mockRequest.headers = {};

      // Act
      await middleware.{{methodName}}(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });

    it('should handle errors', async () => {
      // Arrange
      mockRequest.headers = {};

      // Act
      await middleware.{{methodName}}(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});`
};

class TestGenerator {
  constructor() {
    this.sourceDir = CONFIG.sourceDir;
    this.testDir = CONFIG.testDir;
  }

  /**
   * Genera tests para un archivo específico
   */
  generateTestsForFile(filePath) {
    try {
      const fileContent = fs.readFileSync(filePath, 'utf8');
      const fileName = path.basename(filePath, '.ts');
      const className = this.extractClassName(fileContent);
      const methods = this.extractMethods(fileContent);
      const fileType = this.determineFileType(filePath);
      
      if (!className || !methods.length) {
        console.log(`⚠️  No se pudo generar tests para ${fileName}: clase o métodos no encontrados`);
        return;
      }

      const testContent = this.generateTestContent(className, methods, fileType, filePath);
      const testFilePath = path.join(this.testDir, `${fileName}.test.ts`);
      
      // Crear directorio si no existe
      if (!fs.existsSync(this.testDir)) {
        fs.mkdirSync(this.testDir, { recursive: true });
      }

      fs.writeFileSync(testFilePath, testContent);
      console.log(`✅ Tests generados para ${fileName}: ${testFilePath}`);
      
    } catch (error) {
      console.error(`❌ Error generando tests para ${filePath}:`, error.message);
    }
  }

  /**
   * Extrae el nombre de la clase del archivo
   */
  extractClassName(content) {
    const classMatch = content.match(/export class (\w+)/);
    return classMatch ? classMatch[1] : null;
  }

  /**
   * Extrae los métodos públicos de la clase
   */
  extractMethods(content) {
    const methodMatches = content.match(/async (\w+)\(/g) || content.match(/(\w+)\(/g);
    if (!methodMatches) return [];
    
    return methodMatches.map(match => {
      const methodName = match.replace(/async |\(/g, '');
      return {
        name: methodName,
        description: this.generateTestDescription(methodName)
      };
    });
  }

  /**
   * Determina el tipo de archivo basado en la ruta
   */
  determineFileType(filePath) {
    if (filePath.includes('/controllers/')) return 'controller';
    if (filePath.includes('/services/')) return 'service';
    if (filePath.includes('/repositories/')) return 'repository';
    if (filePath.includes('/use-cases/')) return 'usecase';
    if (filePath.includes('/entities/')) return 'entity';
    if (filePath.includes('/middleware/')) return 'middleware';
    return 'service'; // default
  }

  /**
   * Genera descripción de test basada en el nombre del método
   */
  generateTestDescription(methodName) {
    const descriptions = {
      'create': 'create new record successfully',
      'find': 'find record by criteria',
      'update': 'update record successfully',
      'delete': 'delete record successfully',
      'get': 'get record data',
      'set': 'set record data',
      'validate': 'validate input data',
      'process': 'process data correctly',
      'handle': 'handle request properly',
      'execute': 'execute operation successfully'
    };

    for (const [key, description] of Object.entries(descriptions)) {
      if (methodName.toLowerCase().includes(key)) {
        return description;
      }
    }

    return 'execute method successfully';
  }

  /**
   * Genera el contenido del test
   */
  generateTestContent(className, methods, fileType, filePath) {
    const template = TEST_TEMPLATES[fileType] || TEST_TEMPLATES.service;
    const importPath = this.generateImportPath(filePath);
    const testDataType = this.getTestDataType(className);
    const methodName = methods[0]?.name || 'execute';
    const testDescription = methods[0]?.description || 'execute method successfully';
    
    return template
      .replace(/\{\{className\}\}/g, className)
      .replace(/\{\{importPath\}\}/g, importPath)
      .replace(/\{\{testDataType\}\}/g, testDataType)
      .replace(/\{\{methodName\}\}/g, methodName)
      .replace(/\{\{testDescription\}\}/g, testDescription)
      .replace(/\{\{date\}\}/g, new Date().toISOString().split('T')[0]);
  }

  /**
   * Genera la ruta de importación
   */
  generateImportPath(filePath) {
    const relativePath = path.relative(this.testDir, filePath).replace('.ts', '');
    return relativePath.startsWith('.') ? relativePath : `./${relativePath}`;
  }

  /**
   * Obtiene el tipo de datos de prueba
   */
  getTestDataType(className) {
    if (className.includes('Professor')) return 'Professor';
    if (className.includes('Student')) return 'Student';
    if (className.includes('Schedule')) return 'Schedule';
    if (className.includes('Booking')) return 'Booking';
    if (className.includes('Payment')) return 'Payment';
    if (className.includes('Service')) return 'Service';
    if (className.includes('Message')) return 'Message';
    return 'User';
  }

  /**
   * Genera tests para todos los archivos en un directorio
   */
  generateTestsForDirectory(dirPath) {
    try {
      const files = fs.readdirSync(dirPath);
      
      for (const file of files) {
        const filePath = path.join(dirPath, file);
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory()) {
          this.generateTestsForDirectory(filePath);
        } else if (file.endsWith('.ts') && !file.endsWith('.test.ts') && !file.endsWith('.d.ts')) {
          this.generateTestsForFile(filePath);
        }
      }
    } catch (error) {
      console.error(`❌ Error procesando directorio ${dirPath}:`, error.message);
    }
  }

  /**
   * Genera tests para archivos específicos
   */
  generateTestsForSpecificFiles(filePatterns) {
    const patterns = Array.isArray(filePatterns) ? filePatterns : [filePatterns];
    
    for (const pattern of patterns) {
      const filePath = path.join(this.sourceDir, pattern);
      
      if (fs.existsSync(filePath)) {
        const stat = fs.statSync(filePath);
        
        if (stat.isDirectory()) {
          this.generateTestsForDirectory(filePath);
        } else {
          this.generateTestsForFile(filePath);
        }
      } else {
        console.log(`⚠️  Archivo no encontrado: ${filePath}`);
      }
    }
  }
}

// CLI Interface
function main() {
  const args = process.argv.slice(2);
  const generator = new TestGenerator();

  if (args.length === 0) {
    console.log(`
🧪 Generador de Tests Unitarios - Tennis Management System

Uso:
  node generate-unit-tests.js [opciones] [archivos/directorios]

Opciones:
  --all                    Generar tests para todos los archivos
  --controllers           Generar tests para controladores
  --services              Generar tests para servicios
  --repositories          Generar tests para repositorios
  --usecases              Generar tests para casos de uso
  --entities              Generar tests para entidades
  --middleware            Generar tests para middleware

Ejemplos:
  node generate-unit-tests.js --all
  node generate-unit-tests.js --controllers
  node generate-unit-tests.js application/controllers/AuthController.ts
  node generate-unit-tests.js application/controllers/
    `);
    return;
  }

  console.log('🚀 Iniciando generación de tests unitarios...\n');

  if (args.includes('--all')) {
    console.log('📁 Generando tests para todos los archivos...');
    generator.generateTestsForDirectory(generator.sourceDir);
  } else if (args.includes('--controllers')) {
    console.log('🎮 Generando tests para controladores...');
    generator.generateTestsForSpecificFiles('application/controllers/');
  } else if (args.includes('--services')) {
    console.log('⚙️  Generando tests para servicios...');
    generator.generateTestsForSpecificFiles('infrastructure/services/');
  } else if (args.includes('--repositories')) {
    console.log('🗄️  Generando tests para repositorios...');
    generator.generateTestsForSpecificFiles('infrastructure/repositories/');
  } else if (args.includes('--usecases')) {
    console.log('💼 Generando tests para casos de uso...');
    generator.generateTestsForSpecificFiles('domain/use-cases/');
  } else if (args.includes('--entities')) {
    console.log('📦 Generando tests para entidades...');
    generator.generateTestsForSpecificFiles('domain/entities/');
  } else if (args.includes('--middleware')) {
    console.log('🔧 Generando tests para middleware...');
    generator.generateTestsForSpecificFiles('application/middleware/');
  } else {
    // Generar tests para archivos específicos
    generator.generateTestsForSpecificFiles(args);
  }

  console.log('\n✅ Generación de tests completada!');
  console.log('📁 Tests guardados en:', generator.testDir);
  console.log('🧪 Ejecutar tests con: npm run test:unit');
}

// Ejecutar si es llamado directamente
if (require.main === module) {
  main();
}

module.exports = TestGenerator;
