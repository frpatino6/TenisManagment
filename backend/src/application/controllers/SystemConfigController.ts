import { Request, Response } from 'express';
import { SystemConfigModel } from '../../infrastructure/database/models/SystemConfigModel';

export class SystemConfigController {
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
}

