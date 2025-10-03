/**
 * Cliente para la API de Render
 * Proporciona métodos para interactuar con la API de Render para automatizar despliegues
 */

import fetch from 'node-fetch';

export class RenderAPIClient {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseURL = 'https://api.render.com/v1';
    this.headers = {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
  }

  /**
   * Obtiene información de un servicio
   */
  async getService(serviceId) {
    try {
      const response = await fetch(`${this.baseURL}/services/${serviceId}`, {
        headers: this.headers
      });

      if (!response.ok) {
        throw new Error(`Error obteniendo servicio: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      throw new Error(`Error en API de Render: ${error.message}`);
    }
  }

  /**
   * Obtiene el estado de un servicio
   */
  async getServiceStatus(serviceId) {
    try {
      const service = await this.getService(serviceId);
      return {
        id: service.service.id,
        name: service.service.name,
        state: service.service.serviceDetails?.buildStatus || 'unknown',
        url: service.service.serviceDetails?.url,
        lastDeploy: service.service.updatedAt,
        environment: service.service.serviceDetails?.env || 'production'
      };
    } catch (error) {
      throw new Error(`Error obteniendo estado del servicio: ${error.message}`);
    }
  }

  /**
   * Inicia un nuevo despliegue
   */
  async triggerDeploy(serviceId, options = {}) {
    try {
      const deployData = {
        clearCache: options.clearCache || false,
        commitSha: options.commitSha || null
      };

      const response = await fetch(`${this.baseURL}/services/${serviceId}/deploys`, {
        method: 'POST',
        headers: this.headers,
        body: JSON.stringify(deployData)
      });

      if (!response.ok) {
        throw new Error(`Error iniciando despliegue: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return {
        id: result.deploy.id,
        status: result.deploy.status,
        url: result.deploy.url,
        createdAt: result.deploy.createdAt
      };
    } catch (error) {
      throw new Error(`Error iniciando despliegue: ${error.message}`);
    }
  }

  /**
   * Obtiene los logs de un despliegue
   */
  async getDeployLogs(serviceId, deployId, lines = 100) {
    try {
      const response = await fetch(
        `${this.baseURL}/services/${serviceId}/deploys/${deployId}/logs?lines=${lines}`,
        {
          headers: this.headers
        }
      );

      if (!response.ok) {
        throw new Error(`Error obteniendo logs: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return result.logs || 'No hay logs disponibles';
    } catch (error) {
      throw new Error(`Error obteniendo logs: ${error.message}`);
    }
  }

  /**
   * Obtiene los logs del servicio en tiempo real
   */
  async getServiceLogs(serviceId, lines = 100) {
    try {
      const response = await fetch(
        `${this.baseURL}/services/${serviceId}/logs?lines=${lines}`,
        {
          headers: this.headers
        }
      );

      if (!response.ok) {
        throw new Error(`Error obteniendo logs del servicio: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return result.logs || 'No hay logs disponibles';
    } catch (error) {
      throw new Error(`Error obteniendo logs del servicio: ${error.message}`);
    }
  }

  /**
   * Actualiza variables de entorno
   */
  async updateEnvironmentVariables(serviceId, variables) {
    try {
      const envVars = Object.entries(variables).map(([key, value]) => ({
        key,
        value: String(value)
      }));

      const response = await fetch(`${this.baseURL}/services/${serviceId}/env-vars`, {
        method: 'PATCH',
        headers: this.headers,
        body: JSON.stringify({ envVars })
      });

      if (!response.ok) {
        throw new Error(`Error actualizando variables de entorno: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      throw new Error(`Error actualizando variables de entorno: ${error.message}`);
    }
  }

  /**
   * Obtiene el historial de despliegues
   */
  async getDeployHistory(serviceId, limit = 10) {
    try {
      const response = await fetch(
        `${this.baseURL}/services/${serviceId}/deploys?limit=${limit}`,
        {
          headers: this.headers
        }
      );

      if (!response.ok) {
        throw new Error(`Error obteniendo historial: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return result.deploys || [];
    } catch (error) {
      throw new Error(`Error obteniendo historial de despliegues: ${error.message}`);
    }
  }

  /**
   * Hace rollback a un despliegue anterior
   */
  async rollbackToDeploy(serviceId, deployId) {
    try {
      const response = await fetch(`${this.baseURL}/services/${serviceId}/deploys/${deployId}/rollback`, {
        method: 'POST',
        headers: this.headers
      });

      if (!response.ok) {
        throw new Error(`Error haciendo rollback: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return {
        id: result.deploy.id,
        status: result.deploy.status,
        rollbackTo: deployId
      };
    } catch (error) {
      throw new Error(`Error haciendo rollback: ${error.message}`);
    }
  }

  /**
   * Lista todos los servicios
   */
  async listServices() {
    try {
      const response = await fetch(`${this.baseURL}/services`, {
        headers: this.headers
      });

      if (!response.ok) {
        throw new Error(`Error listando servicios: ${response.status} ${response.statusText}`);
      }

      const result = await response.json();
      return result.services || [];
    } catch (error) {
      throw new Error(`Error listando servicios: ${error.message}`);
    }
  }

  /**
   * Busca un servicio por nombre
   */
  async findServiceByName(serviceName) {
    try {
      const services = await this.listServices();
      return services.find(service => 
        service.name === serviceName || 
        service.name.includes(serviceName)
      );
    } catch (error) {
      throw new Error(`Error buscando servicio: ${error.message}`);
    }
  }
}

export default RenderAPIClient;
