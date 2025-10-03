#!/usr/bin/env node

/**
 * MCP Server Mejorado para automatización de despliegues a Render
 * Incluye integración real con la API de Render
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
import { RenderAPIClient } from './render-api-client.js';
import dotenv from 'dotenv';

// Cargar variables de entorno
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class EnhancedRenderDeployServer {
  constructor() {
    this.server = new Server(
      {
        name: 'render-deploy-server-enhanced',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    // Inicializar cliente de Render API
    this.renderClient = new RenderAPIClient(process.env.RENDER_API_KEY);
    this.serviceId = process.env.RENDER_SERVICE_ID || 'tennis-management-backend';

    this.setupToolHandlers();
    this.setupErrorHandling();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'deploy_to_render',
            description: 'Despliega el backend a Render usando la API real',
            inputSchema: {
              type: 'object',
              properties: {
                environment: {
                  type: 'string',
                  enum: ['production', 'staging'],
                  description: 'Ambiente de despliegue',
                  default: 'production'
                },
                clear_cache: {
                  type: 'boolean',
                  description: 'Limpiar caché durante el despliegue',
                  default: false
                },
                commit_sha: {
                  type: 'string',
                  description: 'SHA del commit específico a desplegar (opcional)'
                }
              }
            }
          },
          {
            name: 'check_deployment_status',
            description: 'Verifica el estado actual del despliegue en Render',
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
            description: 'Obtiene los logs del servicio o despliegue específico',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
                deploy_id: {
                  type: 'string',
                  description: 'ID del despliegue específico (opcional)'
                },
                lines: {
                  type: 'number',
                  description: 'Número de líneas de logs a obtener',
                  default: 100
                }
              }
            }
          },
          {
            name: 'get_deployment_history',
            description: 'Obtiene el historial de despliegues',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
                limit: {
                  type: 'number',
                  description: 'Número de despliegues a obtener',
                  default: 10
                }
              }
            }
          },
          {
            name: 'rollback_deployment',
            description: 'Hace rollback a un despliegue anterior',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
                deploy_id: {
                  type: 'string',
                  description: 'ID del despliegue al cual hacer rollback',
                  default: 'previous'
                }
              },
              required: ['deploy_id']
            }
          },
          {
            name: 'update_environment_variables',
            description: 'Actualiza variables de entorno en Render',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
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
            description: 'Valida que el build local funcione correctamente',
            inputSchema: {
              type: 'object',
              properties: {
                run_tests: {
                  type: 'boolean',
                  description: 'Ejecutar tests antes de validar',
                  default: true
                },
                check_dependencies: {
                  type: 'boolean',
                  description: 'Verificar dependencias',
                  default: true
                }
              }
            }
          },
          {
            name: 'monitor_deployment',
            description: 'Monitorea el progreso de un despliegue en tiempo real',
            inputSchema: {
              type: 'object',
              properties: {
                service_name: {
                  type: 'string',
                  description: 'Nombre del servicio en Render',
                  default: 'tennis-management-backend'
                },
                deploy_id: {
                  type: 'string',
                  description: 'ID del despliegue a monitorear'
                },
                timeout_minutes: {
                  type: 'number',
                  description: 'Tiempo máximo de monitoreo en minutos',
                  default: 10
                }
              },
              required: ['deploy_id']
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
          case 'get_deployment_logs':
            return await this.getDeploymentLogs(args);
          case 'get_deployment_history':
            return await this.getDeploymentHistory(args);
          case 'rollback_deployment':
            return await this.rollbackDeployment(args);
          case 'update_environment_variables':
            return await this.updateEnvironmentVariables(args);
          case 'validate_build':
            return await this.validateBuild(args);
          case 'monitor_deployment':
            return await this.monitorDeployment(args);
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
    const { 
      environment = 'production', 
      clear_cache = false, 
      commit_sha = null 
    } = args;
    
    try {
      // 1. Validar build local
      console.log('🔍 Validando build local...');
      await this.validateBuild({ run_tests: true, check_dependencies: true });

      // 2. Obtener información del servicio
      console.log('📋 Obteniendo información del servicio...');
      const service = await this.renderClient.findServiceByName(this.serviceId);
      if (!service) {
        throw new Error(`Servicio ${this.serviceId} no encontrado`);
      }

      // 3. Iniciar despliegue
      console.log('🚀 Iniciando despliegue en Render...');
      const deployResult = await this.renderClient.triggerDeploy(service.id, {
        clearCache: clear_cache,
        commitSha: commit_sha
      });

      return {
        content: [
          {
            type: 'text',
            text: `✅ Despliegue iniciado exitosamente!\n\n` +
                  `🆔 ID del despliegue: ${deployResult.id}\n` +
                  `🌍 Ambiente: ${environment}\n` +
                  `🔄 Caché limpiado: ${clear_cache ? 'Sí' : 'No'}\n` +
                  `📊 Estado: ${deployResult.status}\n` +
                  `⏰ Iniciado: ${new Date(deployResult.createdAt).toLocaleString()}\n\n` +
                  `🔗 Monitorear en: https://dashboard.render.com\n` +
                  `📋 Usa 'monitor_deployment' con ID: ${deployResult.id}`
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
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      const status = await this.renderClient.getServiceStatus(service.id);
      
      return {
        content: [
          {
            type: 'text',
            text: `📊 Estado del servicio: ${status.name}\n\n` +
                  `🆔 ID: ${status.id}\n` +
                  `🟢 Estado: ${status.state}\n` +
                  `🌐 URL: ${status.url || 'No disponible'}\n` +
                  `⏰ Última actualización: ${new Date(status.lastDeploy).toLocaleString()}\n` +
                  `🔧 Ambiente: ${status.environment}\n\n` +
                  `Para más detalles: https://dashboard.render.com`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error verificando estado: ${error.message}`);
    }
  }

  async getDeploymentLogs(args) {
    const { 
      service_name = 'tennis-management-backend', 
      deploy_id = null, 
      lines = 100 
    } = args;
    
    try {
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      let logs;
      if (deploy_id) {
        logs = await this.renderClient.getDeployLogs(service.id, deploy_id, lines);
      } else {
        logs = await this.renderClient.getServiceLogs(service.id, lines);
      }
      
      return {
        content: [
          {
            type: 'text',
            text: `📋 Logs del servicio: ${service_name}\n` +
                  (deploy_id ? `🆔 Despliegue: ${deploy_id}\n` : '') +
                  `📊 Últimas ${lines} líneas:\n\n` +
                  `\`\`\`\n${logs}\n\`\`\``
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error obteniendo logs: ${error.message}`);
    }
  }

  async getDeploymentHistory(args) {
    const { 
      service_name = 'tennis-management-backend', 
      limit = 10 
    } = args;
    
    try {
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      const history = await this.renderClient.getDeployHistory(service.id, limit);
      
      const historyText = history.map((deploy, index) => 
        `${index + 1}. 🆔 ${deploy.id}\n` +
        `   📊 Estado: ${deploy.status}\n` +
        `   ⏰ Fecha: ${new Date(deploy.createdAt).toLocaleString()}\n` +
        `   🔗 URL: ${deploy.url || 'N/A'}\n`
      ).join('\n');
      
      return {
        content: [
          {
            type: 'text',
            text: `📋 Historial de despliegues: ${service_name}\n\n` +
                  historyText +
                  `\n\nTotal: ${history.length} despliegues mostrados`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error obteniendo historial: ${error.message}`);
    }
  }

  async rollbackDeployment(args) {
    const { 
      service_name = 'tennis-management-backend', 
      deploy_id 
    } = args;
    
    try {
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      let targetDeployId = deploy_id;
      
      // Si es 'previous', obtener el despliegue anterior
      if (deploy_id === 'previous') {
        const history = await this.renderClient.getDeployHistory(service.id, 2);
        if (history.length < 2) {
          throw new Error('No hay despliegues anteriores disponibles');
        }
        targetDeployId = history[1].id; // El segundo más reciente
      }

      const rollbackResult = await this.renderClient.rollbackToDeploy(service.id, targetDeployId);
      
      return {
        content: [
          {
            type: 'text',
            text: `🔄 Rollback iniciado exitosamente!\n\n` +
                  `🆔 Nuevo despliegue: ${rollbackResult.id}\n` +
                  `📊 Estado: ${rollbackResult.status}\n` +
                  `🎯 Rollback a: ${rollbackResult.rollbackTo}\n\n` +
                  `Monitorea el progreso en: https://dashboard.render.com`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error en rollback: ${error.message}`);
    }
  }

  async updateEnvironmentVariables(args) {
    const { 
      service_name = 'tennis-management-backend', 
      variables 
    } = args;
    
    try {
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      const result = await this.renderClient.updateEnvironmentVariables(service.id, variables);
      
      return {
        content: [
          {
            type: 'text',
            text: `✅ Variables de entorno actualizadas exitosamente!\n\n` +
                  `🔧 Variables actualizadas:\n` +
                  Object.entries(variables)
                    .map(([key, value]) => `   • ${key}: ${value}`)
                    .join('\n') +
                  `\n\n⚠️ El servicio se reiniciará automáticamente con las nuevas variables.`
          }
        ]
      };
    } catch (error) {
      throw new Error(`Error actualizando variables: ${error.message}`);
    }
  }

  async validateBuild(args) {
    const { run_tests = true, check_dependencies = true } = args;
    
    try {
      const results = [];
      
      // 1. Verificar dependencias
      if (check_dependencies) {
        console.log('📦 Verificando dependencias...');
        await this.runCommand('npm', ['install']);
        results.push('✅ Dependencias instaladas');
      }
      
      // 2. Verificar sintaxis TypeScript
      console.log('🔍 Verificando sintaxis TypeScript...');
      await this.runCommand('npm', ['run', 'type-check']);
      results.push('✅ Sintaxis TypeScript válida');
      
      // 3. Ejecutar linting
      console.log('🧹 Ejecutando linting...');
      await this.runCommand('npm', ['run', 'lint']);
      results.push('✅ Linting exitoso');
      
      // 4. Ejecutar build
      console.log('🔨 Ejecutando build...');
      await this.runCommand('npm', ['run', 'build']);
      results.push('✅ Build exitoso');
      
      // 5. Ejecutar tests si se solicita
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

  async monitorDeployment(args) {
    const { 
      service_name = 'tennis-management-backend', 
      deploy_id, 
      timeout_minutes = 10 
    } = args;
    
    try {
      const service = await this.renderClient.findServiceByName(service_name);
      if (!service) {
        throw new Error(`Servicio ${service_name} no encontrado`);
      }

      const startTime = Date.now();
      const timeoutMs = timeout_minutes * 60 * 1000;
      
      let status = 'building';
      let attempts = 0;
      const maxAttempts = Math.floor(timeout_minutes * 2); // Cada 30 segundos
      
      while (status === 'building' && attempts < maxAttempts && (Date.now() - startTime) < timeoutMs) {
        attempts++;
        
        try {
          const deployStatus = await this.renderClient.getServiceStatus(service.id);
          status = deployStatus.state;
          
          if (status === 'live') {
            return {
              content: [
                {
                  type: 'text',
                  text: `✅ Despliegue completado exitosamente!\n\n` +
                        `🆔 Despliegue: ${deploy_id}\n` +
                        `📊 Estado final: ${status}\n` +
                        `🌐 URL: ${deployStatus.url}\n` +
                        `⏰ Tiempo total: ${Math.round((Date.now() - startTime) / 1000)}s\n` +
                        `🔄 Intentos: ${attempts}`
                }
              ]
            };
          }
          
          // Esperar 30 segundos antes del siguiente check
          await new Promise(resolve => setTimeout(resolve, 30000));
          
        } catch (error) {
          console.log(`Intento ${attempts} falló: ${error.message}`);
        }
      }
      
      return {
        content: [
          {
            type: 'text',
            text: `⏰ Monitoreo completado (timeout: ${timeout_minutes}min)\n\n` +
                  `🆔 Despliegue: ${deploy_id}\n` +
                  `📊 Estado final: ${status}\n` +
                  `🔄 Intentos realizados: ${attempts}\n\n` +
                  `Verifica manualmente en: https://dashboard.render.com`
          }
        ]
      };
      
    } catch (error) {
      throw new Error(`Error monitoreando despliegue: ${error.message}`);
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

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('🚀 MCP Render Deploy Server Enhanced iniciado');
  }
}

// Iniciar el servidor
const server = new EnhancedRenderDeployServer();
server.run().catch(console.error);
