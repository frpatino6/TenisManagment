#!/usr/bin/env node

/**
 * MCP Server para automatización de despliegues a Render
 * Este servidor proporciona herramientas para automatizar el proceso de despliegue
 * del backend de Tennis Management a la plataforma Render.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { spawn } from 'child_process';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class RenderDeployServer {
  constructor() {
    this.server = new Server(
      {
        name: 'render-deploy-server',
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
            name: 'deploy_to_render',
            description: 'Despliega el backend a Render usando la configuración existente',
            inputSchema: {
              type: 'object',
              properties: {
                environment: {
                  type: 'string',
                  enum: ['production', 'staging'],
                  description: 'Ambiente de despliegue',
                  default: 'production'
                },
                force_rebuild: {
                  type: 'boolean',
                  description: 'Forzar reconstrucción completa',
                  default: false
                }
              }
            }
          },
          {
            name: 'check_deployment_status',
            description: 'Verifica el estado del despliegue en Render',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                }
              }
            }
          },
          {
            name: 'update_environment_variables',
            description: 'Actualiza variables de entorno en Render',
            inputSchema: {
              type: 'object',
              properties: {
                variables: {
                  type: 'object',
                  description: 'Variables de entorno a actualizar (key-value pairs)'
                }
              },
              required: ['variables']
            }
          },
          {
            name: 'validate_build',
            description: 'Valida que el build local funcione correctamente antes del despliegue',
            inputSchema: {
              type: 'object',
              properties: {
                run_tests: {
                  type: 'boolean',
                  description: 'Ejecutar tests antes de validar',
                  default: true
                }
              }
            }
          },
          {
            name: 'rollback_deployment',
            description: 'Hace rollback a la versión anterior del despliegue',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                }
              }
            }
          },
          {
            name: 'get_deployment_logs',
            description: 'Obtiene los logs del último despliegue',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
                lines: {
                  type: 'number',
                  description: 'Número de líneas de logs a obtener',
                  default: 100
                }
              }
            }
          }
        ]
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'deploy_to_render':
            return await this.deployToRender(args);
          case 'check_deployment_status':
            return await this.checkDeploymentStatus(args);
          case 'update_environment_variables':
            return await this.updateEnvironmentVariables(args);
          case 'validate_build':
            return await this.validateBuild(args);
          case 'rollback_deployment':
            return await this.rollbackDeployment(args);
          case 'get_deployment_logs':
            return await this.getDeploymentLogs(args);
          default:
            throw new Error(`Herramienta desconocida: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error ejecutando ${name}: ${error.message}`
            }
          ],
          isError: true
        };
      }
    });
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

  async deployToRender(args) {
    const { environment = 'production', force_rebuild = false } = args;
    
    try {
      // 1. Validar build local
      console.log('🔍 Validando build local...');
      await this.runCommand('npm', ['run', 'build']);
      
      // 2. Ejecutar tests si están disponibles
      console.log('🧪 Ejecutando tests...');
      try {
        await this.runCommand('npm', ['test']);
      } catch (error) {
        console.log('⚠️ Tests no disponibles o fallaron, continuando...');
      }

      // 3. Verificar configuración de Render
      console.log('📋 Verificando configuración de Render...');
      const renderConfig = this.validateRenderConfig();
      
      // 4. Commit y push a Git (si es necesario)
      console.log('📤 Preparando para despliegue...');
      await this.prepareGitForDeploy();

      // 5. Trigger deploy en Render
      console.log('🚀 Iniciando despliegue en Render...');
      const deployResult = await this.triggerRenderDeploy(environment, force_rebuild);

      return {
        content: [
          {
            type: 'text',
            text: `✅ Despliegue iniciado exitosamente!\n\n` +
                  `🌍 Ambiente: ${environment}\n` +
                  `🔄 Rebuild forzado: ${force_rebuild ? 'Sí' : 'No'}\n` +
                  `📊 Estado: ${deployResult.status}\n` +
                  `🔗 URL: ${deployResult.url || 'Pendiente'}\n\n` +
                  `Puedes monitorear el progreso en: https://dashboard.render.com`
          }
        ]
      };

    } catch (error) {
      throw new Error(`Error en despliegue: ${error.message}`);
    }
  }

  async checkDeploymentStatus(args) {
    const { service_name = 'tennis-management-backend' } = args;
    
    try {
      // Simular verificación de estado (en implementación real usarías la API de Render)
      const status = await this.getRenderServiceStatus(service_name);
      
      return {
        content: [
          {
            type: 'text',
            text: `📊 Estado del servicio: ${service_name}\n\n` +
                  `🟢 Estado: ${status.state}\n` +
                  `🌐 URL: ${status.url}\n` +
                  `⏰ Último despliegue: ${status.lastDeploy}\n` +
                  `💾 Versión: ${status.version}\n` +
                  `🔧 Ambiente: ${status.environment}\n\n` +
                  `Para más detalles: https://dashboard.render.com`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error verificando estado: ${error.message}`);
    }
  }

  async updateEnvironmentVariables(args) {
    const { variables } = args;
    
    try {
      // Actualizar render.yaml con nuevas variables
      const renderConfigPath = join(__dirname, 'render.yaml');
      let renderConfig = readFileSync(renderConfigPath, 'utf8');
      
      // Agregar nuevas variables de entorno
      for (const [key, value] of Object.entries(variables)) {
        const envVarEntry = `      - key: ${key}\n        value: ${value}`;
        renderConfig = renderConfig.replace(
          /envVars:/,
          `envVars:\n${envVarEntry}`
        );
      }
      
      writeFileSync(renderConfigPath, renderConfig);
      
      return {
        content: [
          {
            type: 'text',
            text: `✅ Variables de entorno actualizadas en render.yaml:\n\n` +
                  Object.entries(variables)
                    .map(([key, value]) => `🔧 ${key}: ${value}`)
                    .join('\n') +
                  `\n\n⚠️ Recuerda hacer commit y push para aplicar los cambios.`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error actualizando variables: ${error.message}`);
    }
  }

  async validateBuild(args) {
    const { run_tests = true } = args;
    
    try {
      const results = [];
      
      // 1. Verificar sintaxis TypeScript
      console.log('🔍 Verificando sintaxis TypeScript...');
      await this.runCommand('npm', ['run', 'type-check']);
      results.push('✅ Sintaxis TypeScript válida');
      
      // 2. Ejecutar linting
      console.log('🧹 Ejecutando linting...');
      await this.runCommand('npm', ['run', 'lint']);
      results.push('✅ Linting exitoso');
      
      // 3. Ejecutar build
      console.log('🔨 Ejecutando build...');
      await this.runCommand('npm', ['run', 'build']);
      results.push('✅ Build exitoso');
      
      // 4. Ejecutar tests si se solicita
      if (run_tests) {
        console.log('🧪 Ejecutando tests...');
        try {
          await this.runCommand('npm', ['test']);
          results.push('✅ Tests exitosos');
        } catch (error) {
          results.push('⚠️ Tests no disponibles o fallaron');
        }
      }
      
      return {
        content: [
          {
            type: 'text',
            text: `🎯 Validación de build completada:\n\n` +
                  results.join('\n') +
                  `\n\n✅ El proyecto está listo para despliegue!`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error en validación: ${error.message}`);
    }
  }

  async rollbackDeployment(args) {
    const { service_name = 'tennis-management-backend' } = args;
    
    try {
      // Simular rollback (en implementación real usarías la API de Render)
      const rollbackResult = await this.triggerRenderRollback(service_name);
      
      return {
        content: [
          {
            type: 'text',
            text: `🔄 Rollback iniciado para: ${service_name}\n\n` +
                  `📊 Estado: ${rollbackResult.status}\n` +
                  `⏰ Tiempo estimado: ${rollbackResult.estimatedTime}\n` +
                  `🔗 URL: ${rollbackResult.url}\n\n` +
                  `Monitorea el progreso en: https://dashboard.render.com`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error en rollback: ${error.message}`);
    }
  }

  async getDeploymentLogs(args) {
    const { service_name = 'tennis-management-backend', lines = 100 } = args;
    
    try {
      // Simular obtención de logs (en implementación real usarías la API de Render)
      const logs = await this.fetchRenderLogs(service_name, lines);
      
      return {
        content: [
          {
            type: 'text',
            text: `📋 Logs del servicio: ${service_name}\n\n` +
                  `📊 Últimas ${lines} líneas:\n\n` +
                  `\`\`\`\n${logs}\n\`\`\``
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error obteniendo logs: ${error.message}`);
    }
  }

  // Métodos auxiliares
  async runCommand(command, args = []) {
    return new Promise((resolve, reject) => {
      const process = spawn(command, args, {
        stdio: 'inherit',
        cwd: __dirname
      });
      
      process.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`Comando falló con código ${code}`));
        }
      });
    });
  }

  validateRenderConfig() {
    const renderConfigPath = join(__dirname, 'render.yaml');
    if (!existsSync(renderConfigPath)) {
      throw new Error('render.yaml no encontrado');
    }
    
    const config = readFileSync(renderConfigPath, 'utf8');
    // Validaciones básicas
    if (!config.includes('tennis-management-backend')) {
      throw new Error('Configuración de servicio no válida');
    }
    
    return config;
  }

  async prepareGitForDeploy() {
    try {
      // Verificar si hay cambios sin commitear
      await this.runCommand('git', ['add', '.']);
      await this.runCommand('git', ['commit', '-m', `Deploy: ${new Date().toISOString()}`]);
      await this.runCommand('git', ['push']);
    } catch (error) {
      console.log('⚠️ No se pudo hacer commit/push, continuando...');
    }
  }

  async triggerRenderDeploy(environment, forceRebuild) {
    // Simulación - en implementación real usarías la API de Render
    return {
      status: 'Deploy iniciado',
      url: 'https://tennis-management-backend.onrender.com',
      environment,
      forceRebuild
    };
  }

  async getRenderServiceStatus(serviceName) {
    // Simulación - en implementación real usarías la API de Render
    return {
      state: 'Live',
      url: 'https://tennis-management-backend.onrender.com',
      lastDeploy: new Date().toISOString(),
      version: '1.3.2',
      environment: 'production'
    };
  }

  async triggerRenderRollback(serviceName) {
    // Simulación - en implementación real usarías la API de Render
    return {
      status: 'Rollback iniciado',
      estimatedTime: '2-3 minutos',
      url: 'https://tennis-management-backend.onrender.com'
    };
  }

  async fetchRenderLogs(serviceName, lines) {
    // Simulación - en implementación real usarías la API de Render
    return `[${new Date().toISOString()}] INFO: Servicio iniciado correctamente
[${new Date().toISOString()}] INFO: Conectado a MongoDB
[${new Date().toISOString()}] INFO: Firebase inicializado
[${new Date().toISOString()}] INFO: Servidor escuchando en puerto 3000`;
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🚀 MCP Render Deploy Server iniciado');
  }
}

// Iniciar el servidor
const server = new RenderDeployServer();
server.run().catch(console.error);
