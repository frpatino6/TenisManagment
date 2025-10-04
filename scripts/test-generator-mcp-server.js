#!/usr/bin/env node

/**
 * MCP Server para el Generador de Tests Unitarios
 * Tennis Management System
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

class TestGeneratorMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'test-generator-mcp-server',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupToolHandlers();
    this.setupErrorHandling();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'generate_unit_tests',
            description: 'Genera tests unitarios automáticamente para archivos TypeScript del proyecto Tennis Management',
            inputSchema: {
              type: 'object',
              properties: {
                target: {
                  type: 'string',
                  description: 'Tipo de archivos a procesar: all, controllers, services, repositories, usecases, entities, middleware, o ruta específica',
                  enum: ['all', 'controllers', 'services', 'repositories', 'usecases', 'entities', 'middleware']
                },
                specific_file: {
                  type: 'string',
                  description: 'Ruta específica de archivo o directorio (opcional, solo si target no es uno de los valores predefinidos)'
                }
              },
              required: ['target']
            }
          },
          {
            name: 'list_testable_files',
            description: 'Lista todos los archivos TypeScript que pueden tener tests generados',
            inputSchema: {
              type: 'object',
              properties: {
                category: {
                  type: 'string',
                  description: 'Categoría de archivos a listar',
                  enum: ['all', 'controllers', 'services', 'repositories', 'usecases', 'entities', 'middleware']
                }
              },
              required: ['category']
            }
          },
          {
            name: 'run_generated_tests',
            description: 'Ejecuta los tests unitarios generados',
            inputSchema: {
              type: 'object',
              properties: {
                test_type: {
                  type: 'string',
                  description: 'Tipo de tests a ejecutar',
                  enum: ['unit', 'integration', 'e2e', 'all']
                }
              },
              required: ['test_type']
            }
          },
          {
            name: 'get_test_coverage',
            description: 'Obtiene el reporte de cobertura de tests',
            inputSchema: {
              type: 'object',
              properties: {}
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'generate_unit_tests':
            return await this.generateUnitTests(args);
          case 'list_testable_files':
            return await this.listTestableFiles(args);
          case 'run_generated_tests':
            return await this.runGeneratedTests(args);
          case 'get_test_coverage':
            return await this.getTestCoverage(args);
          default:
            throw new Error(`Herramienta desconocida: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `❌ Error ejecutando ${name}: ${error.message}`
            }
          ]
        };
      }
    });
  }

  async generateUnitTests(args) {
    const { target, specific_file } = args;
    const scriptPath = '/home/fernando/Documentos/TenisManagment/scripts/generate-unit-tests.js';
    
    let command;
    if (specific_file) {
      command = `node ${scriptPath} ${specific_file}`;
    } else {
      command = `node ${scriptPath} --${target}`;
    }

    try {
      const { stdout, stderr } = await execAsync(command, {
        cwd: '/home/fernando/Documentos/TenisManagment/scripts'
      });

      return {
        content: [
          {
            type: 'text',
            text: `🧪 **Generación de Tests Unitarios Completada**\n\n${stdout}${stderr ? `\n⚠️ Advertencias:\n${stderr}` : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ **Error generando tests**:\n\n${error.message}\n\n**Comando ejecutado**:\n\`\`\`bash\n${command}\n\`\`\``
          }
        ]
      };
    }
  }

  async listTestableFiles(args) {
    const { category } = args;
    const sourceDir = '/home/fernando/Documentos/TenisManagment/backend/src';
    
    try {
      let files = [];
      
      if (category === 'all') {
        files = await this.getAllTypeScriptFiles(sourceDir);
      } else {
        const categoryDir = this.getCategoryDirectory(category);
        if (categoryDir) {
          files = await this.getTypeScriptFilesInDirectory(categoryDir);
        }
      }

      const fileList = files.map(file => {
        const relativePath = path.relative(sourceDir, file);
        return `- \`${relativePath}\``;
      }).join('\n');

      return {
        content: [
          {
            type: 'text',
            text: `📁 **Archivos TypeScript para ${category}**\n\n${fileList}\n\n**Total**: ${files.length} archivos`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ **Error listando archivos**: ${error.message}`
          }
        ]
      };
    }
  }

  async runGeneratedTests(args) {
    const { test_type } = args;
    const backendDir = '/home/fernando/Documentos/TenisManagment/backend';
    
    let command;
    switch (test_type) {
      case 'unit':
        command = 'npm run test:unit';
        break;
      case 'integration':
        command = 'npm run test:integration';
        break;
      case 'e2e':
        command = 'npm run test:e2e';
        break;
      case 'all':
        command = 'npm test';
        break;
      default:
        throw new Error(`Tipo de test no válido: ${test_type}`);
    }

    try {
      const { stdout, stderr } = await execAsync(command, {
        cwd: backendDir,
        timeout: 30000 // 30 segundos timeout
      });

      return {
        content: [
          {
            type: 'text',
            text: `🧪 **Ejecutando Tests ${test_type.toUpperCase()}**\n\n\`\`\`\n${stdout}\`\`\`${stderr ? `\n\n⚠️ **Advertencias**:\n\`\`\`\n${stderr}\n\`\`\`` : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ **Error ejecutando tests**:\n\n${error.message}\n\n**Comando ejecutado**:\n\`\`\`bash\n${command}\n\`\`\``
          }
        ]
      };
    }
  }

  async getTestCoverage(args) {
    const backendDir = '/home/fernando/Documentos/TenisManagment/backend';
    
    try {
      const { stdout, stderr } = await execAsync('npm run test:coverage', {
        cwd: backendDir,
        timeout: 60000 // 60 segundos timeout
      });

      return {
        content: [
          {
            type: 'text',
            text: `📊 **Reporte de Cobertura de Tests**\n\n\`\`\`\n${stdout}\`\`\`${stderr ? `\n\n⚠️ **Advertencias**:\n\`\`\`\n${stderr}\n\`\`\`` : ''}`
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `❌ **Error obteniendo cobertura**:\n\n${error.message}\n\n**Comando ejecutado**:\n\`\`\`bash\nnpm run test:coverage\n\`\`\``
          }
        ]
      };
    }
  }

  async getAllTypeScriptFiles(dir) {
    const files = [];
    
    const readDir = async (currentDir) => {
      const items = await fs.promises.readdir(currentDir, { withFileTypes: true });
      
      for (const item of items) {
        const fullPath = path.join(currentDir, item.name);
        
        if (item.isDirectory() && !item.name.startsWith('.') && item.name !== 'node_modules') {
          await readDir(fullPath);
        } else if (item.isFile() && item.name.endsWith('.ts') && !item.name.endsWith('.test.ts') && !item.name.endsWith('.d.ts')) {
          files.push(fullPath);
        }
      }
    };
    
    await readDir(dir);
    return files;
  }

  async getTypeScriptFilesInDirectory(dir) {
    if (!fs.existsSync(dir)) {
      return [];
    }
    
    return this.getAllTypeScriptFiles(dir);
  }

  getCategoryDirectory(category) {
    const baseDir = '/home/fernando/Documentos/TenisManagment/backend/src';
    const categoryMap = {
      'controllers': path.join(baseDir, 'application/controllers'),
      'services': path.join(baseDir, 'infrastructure/services'),
      'repositories': path.join(baseDir, 'infrastructure/repositories'),
      'usecases': path.join(baseDir, 'domain/use-cases'),
      'entities': path.join(baseDir, 'domain/entities'),
      'middleware': path.join(baseDir, 'application/middleware')
    };
    
    return categoryMap[category];
  }

  setupErrorHandling() {
    this.server.onerror = (error) => {
      console.error('[MCP Error]', error);
    };

    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🧪 Test Generator MCP Server running on stdio');
  }
}

const server = new TestGeneratorMCPServer();
server.run().catch(console.error);


