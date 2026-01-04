import { Request, Response } from 'express';
import { SystemConfigModel } from '../../infrastructure/database/models/SystemConfigModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { Logger } from '../../infrastructure/services/Logger';

export class SystemConfigController {
  private logger = new Logger({ controller: 'SystemConfigController' });
  /**
   * GET /api/config/version
   * Obtener información de versión de la aplicación
   * Retorna la versión mínima requerida y la versión actual del sistema
   */
  getVersionInfo = async (req: Request, res: Response) => {
    try {
      const versionConfig = await SystemConfigModel.findOne({ key: 'app_version' });

      // Valores por defecto si no existe configuración
      const defaultVersion = {
        minVersion: '2.1.0',
        currentVersion: '2.1.0',
        forceUpdate: false,
      };

      if (!versionConfig) {
        return res.json(defaultVersion);
      }

      const versionInfo = versionConfig.value || defaultVersion;

      res.json({
        minVersion: versionInfo.minVersion || defaultVersion.minVersion,
        currentVersion: versionInfo.currentVersion || defaultVersion.currentVersion,
        forceUpdate: versionInfo.forceUpdate ?? defaultVersion.forceUpdate,
      });
    } catch (error) {
      res.status(500).json({ error: 'Error al obtener información de versión' });
    }
  };

  /**
   * GET /api/config/tenants/public
   * Obtener lista de tenants activos (endpoint público para registro)
   * Retorna solo información básica: id, name, slug
   */
  getPublicTenants = async (req: Request, res: Response) => {
    try {
      const tenants = await TenantModel.find({ isActive: true })
        .select('_id name slug')
        .lean();

      const items = tenants.map((tenant) => ({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug || null,
      }));

      res.json({ items });
    } catch (error) {
      this.logger.error('Error getting public tenants', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}

