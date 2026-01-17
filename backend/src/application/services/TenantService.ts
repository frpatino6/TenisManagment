/**
 * TenantService - Gestión de Tenants
 * TEN-84: MT-BACK-002
 * 
 * Servicio para gestionar tenants, relaciones usuario-tenant y validaciones de acceso
 */

import { Types } from 'mongoose';
import { TenantModel, TenantDocument, TenantConfig } from '../../infrastructure/database/models/TenantModel';
import { TenantAdminModel, TenantAdminDocument } from '../../infrastructure/database/models/TenantAdminModel';
import { ProfessorTenantModel, ProfessorTenantDocument, ProfessorTenantPricing } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentTenantModel, StudentTenantDocument } from '../../infrastructure/database/models/StudentTenantModel';
import { AuthUserModel, UserRole } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'TenantService' });

export interface CreateTenantInput {
  name: string;
  slug?: string;
  domain?: string;
  adminEmail: string;
  adminName: string;
  config?: TenantConfig;
}

export interface UpdateTenantInput {
  name?: string;
  slug?: string;
  domain?: string;
  config?: TenantConfig;
  isActive?: boolean;
}

export interface UserTenantInfo {
  tenantId: string;
  tenantName: string;
  tenantSlug: string;
  isActive: boolean;
  joinedAt: Date;
  role?: 'tenant_admin' | 'professor' | 'student';
  config?: TenantConfig;
}

export interface TenantAccessResult {
  hasAccess: boolean;
  reason?: string;
}

export class TenantService {
  /**
   * Crear un nuevo tenant (solo Super Admin)
   * Crea el tenant, AuthUser para el admin, y la relación TenantAdmin
   */
  async createTenant(input: CreateTenantInput, superAdminId: string): Promise<TenantDocument> {
    try {
      // Verificar que el usuario es Super Admin
      const superAdmin = await AuthUserModel.findById(superAdminId);
      if (!superAdmin || superAdmin.role !== 'super_admin') {
        throw new Error('Solo Super Admin puede crear tenants');
      }

      // Verificar que el email del admin no existe
      const existingAdmin = await AuthUserModel.findOne({ email: input.adminEmail });
      if (existingAdmin) {
        throw new Error('El email del admin ya está registrado');
      }

      // Verificar que el slug no existe
      const slug = input.slug || this.generateSlug(input.name);
      const existingTenant = await TenantModel.findOne({ slug });
      if (existingTenant) {
        throw new Error('El slug ya está en uso');
      }

      // Crear AuthUser para el Tenant Admin
      const adminUser = await AuthUserModel.create({
        email: input.adminEmail,
        name: input.adminName,
        role: 'tenant_admin',
      });

      // Crear Tenant
      const tenant = await TenantModel.create({
        name: input.name,
        slug,
        domain: input.domain,
        adminUserId: adminUser._id,
        config: input.config,
        isActive: true,
      });

      // Crear relación TenantAdmin
      await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: adminUser._id,
        isActive: true,
      });

      logger.info('Tenant creado exitosamente', { tenantId: tenant._id.toString(), slug });

      // TODO: Enviar email de activación al admin
      // await this.sendActivationEmail(adminUser.email, tenant.name);

      return tenant;
    } catch (error) {
      logger.error('Error creando tenant', { error: (error as Error).message });
      throw error;
    }
  }

  /**
   * Obtener tenant por ID
   */
  async getTenantById(tenantId: string): Promise<TenantDocument | null> {
    try {
      const tenant = await TenantModel.findById(tenantId);
      return tenant;
    } catch (error) {
      logger.error('Error obteniendo tenant', { tenantId, error: (error as Error).message });
      throw error;
    }
  }

  /**
   * Actualizar tenant (Tenant Admin o Super Admin)
   */
  async updateTenant(
    tenantId: string,
    input: UpdateTenantInput,
    userId: string,
    userRole: UserRole,
  ): Promise<TenantDocument | null> {
    try {
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        throw new Error('Tenant no encontrado');
      }

      // Validar acceso: Super Admin o Tenant Admin del tenant
      if (userRole === 'super_admin') {
        // Super Admin puede actualizar cualquier tenant
      } else if (userRole === 'tenant_admin') {
        const tenantAdmin = await TenantAdminModel.findOne({
          tenantId: tenant._id,
          adminUserId: userId,
          isActive: true,
        });
        if (!tenantAdmin) {
          throw new Error('No tienes permisos para actualizar este tenant');
        }
      } else {
        throw new Error('Solo Super Admin o Tenant Admin pueden actualizar tenants');
      }

      // Validar slug único si se está actualizando
      if (input.slug && input.slug !== tenant.slug) {
        const existingTenant = await TenantModel.findOne({ slug: input.slug });
        if (existingTenant) {
          throw new Error('El slug ya está en uso');
        }
      }

      // Actualizar tenant
      const updated = await TenantModel.findByIdAndUpdate(
        tenantId,
        { $set: input },
        { new: true, runValidators: true },
      );

      logger.info('Tenant actualizado', { tenantId, updatedBy: userId });
      return updated;
    } catch (error) {
      logger.error('Error actualizando tenant', { tenantId, error: (error as Error).message });
      throw error;
    }
  }

  /**
   * Obtener tenants de un usuario (profesor o estudiante)
   */
  async getUserTenants(userId: string, userRole: UserRole): Promise<UserTenantInfo[]> {
    try {
      const tenants: UserTenantInfo[] = [];

      if (userRole === 'tenant_admin') {
        // Obtener tenants donde el usuario es admin
        const tenantAdmins = await TenantAdminModel.find({
          adminUserId: userId,
          isActive: true,
        }).populate('tenantId');

        for (const ta of tenantAdmins) {
          const tenant = ta.tenantId as any;
          if (tenant && tenant.isActive) {
            tenants.push({
              tenantId: tenant._id.toString(),
              tenantName: tenant.name,
              tenantSlug: tenant.slug,
              isActive: ta.isActive,
              joinedAt: ta.joinedAt,
              role: 'tenant_admin',
              config: tenant.config,
            });
          }
        }
      } else if (userRole === 'professor') {
        // Obtener tenants donde el profesor trabaja
        const professor = await ProfessorModel.findOne({ authUserId: userId });
        if (professor) {
          const professorTenants = await ProfessorTenantModel.find({
            professorId: professor._id,
            isActive: true,
          }).populate('tenantId');

          for (const pt of professorTenants) {
            const tenant = pt.tenantId as any;
            if (tenant && tenant.isActive) {
              tenants.push({
                tenantId: tenant._id.toString(),
                tenantName: tenant.name,
                tenantSlug: tenant.slug,
                isActive: pt.isActive,
                joinedAt: pt.joinedAt,
                role: 'professor',
                config: tenant.config,
              });
            }
          }
        }
      } else if (userRole === 'student') {
        // Obtener tenants donde el estudiante tiene relación
        const student = await StudentModel.findOne({ authUserId: userId });
        if (student) {
          const studentTenants = await StudentTenantModel.find({
            studentId: student._id,
            isActive: true,
          }).populate('tenantId');

          for (const st of studentTenants) {
            const tenant = st.tenantId as any;
            if (tenant && tenant.isActive) {
              tenants.push({
                tenantId: tenant._id.toString(),
                tenantName: tenant.name,
                tenantSlug: tenant.slug,
                isActive: st.isActive,
                joinedAt: st.joinedAt,
                role: 'student',
                config: tenant.config,
              });
            }
          }
        }
      }

      return tenants;
    } catch (error) {
      logger.error('Error obteniendo tenants del usuario', { userId, error: (error as Error).message });
      throw error;
    }
  }

  /**
   * Validar acceso de un usuario a un tenant
   */
  async validateTenantAccess(
    userId: string,
    userRole: UserRole,
    tenantId: string,
  ): Promise<TenantAccessResult> {
    try {
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        return { hasAccess: false, reason: 'Tenant no encontrado' };
      }

      if (!tenant.isActive) {
        return { hasAccess: false, reason: 'Tenant inactivo' };
      }

      // Super Admin tiene acceso a todos los tenants
      if (userRole === 'super_admin') {
        return { hasAccess: true };
      }

      // Tenant Admin tiene acceso a su propio tenant
      if (userRole === 'tenant_admin') {
        const tenantAdmin = await TenantAdminModel.findOne({
          tenantId: tenant._id,
          adminUserId: userId,
          isActive: true,
        });
        if (tenantAdmin) {
          return { hasAccess: true };
        }
        return { hasAccess: false, reason: 'No eres admin de este tenant' };
      }

      // Professor tiene acceso si está activo en el tenant
      if (userRole === 'professor') {
        const professor = await ProfessorModel.findOne({ authUserId: userId });
        if (professor) {
          const professorTenant = await ProfessorTenantModel.findOne({
            professorId: professor._id,
            tenantId: tenant._id,
            isActive: true,
          });
          if (professorTenant) {
            return { hasAccess: true };
          }
        }
        return { hasAccess: false, reason: 'No estás registrado en este tenant' };
      }

      // Student tiene acceso si tiene relación con el tenant
      if (userRole === 'student') {
        const student = await StudentModel.findOne({ authUserId: userId });
        if (student) {
          const studentTenant = await StudentTenantModel.findOne({
            studentId: student._id,
            tenantId: tenant._id,
            isActive: true,
          });
          if (studentTenant) {
            return { hasAccess: true };
          }
        }
        return { hasAccess: false, reason: 'No tienes relación con este tenant' };
      }

      return { hasAccess: false, reason: 'Rol no válido' };
    } catch (error) {
      logger.error('Error validando acceso a tenant', { userId, tenantId, error: (error as Error).message });
      return { hasAccess: false, reason: 'Error validando acceso' };
    }
  }

  /**
   * Obtener configuración de tenant
   */
  async getTenantConfig(tenantId: string): Promise<TenantConfig | null> {
    try {
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        throw new Error('Tenant no encontrado');
      }

      return tenant.config || null;
    } catch (error) {
      logger.error('Error obteniendo configuración de tenant', { tenantId, error: (error as Error).message });
      throw error;
    }
  }

  /**
   * Agregar profesor a tenant
   */
  async addProfessorToTenant(
    professorId: string,
    tenantId: string,
    pricing?: ProfessorTenantPricing,
  ): Promise<ProfessorTenantDocument> {
    try {
      // Verificar que el profesor existe
      const professor = await ProfessorModel.findById(professorId);
      if (!professor) {
        throw new Error('Profesor no encontrado');
      }

      // Verificar que el tenant existe
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        throw new Error('Tenant no encontrado');
      }

      // Verificar que no existe la relación
      const existing = await ProfessorTenantModel.findOne({
        professorId: professor._id,
        tenantId: tenant._id,
      });

      if (existing) {
        if (existing.isActive) {
          throw new Error('El profesor ya está activo en este tenant');
        }
        // Reactivar la relación
        existing.isActive = true;
        if (pricing) {
          existing.pricing = pricing;
        }
        await existing.save();
        return existing;
      }

      // Crear nueva relación
      const professorTenant = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        pricing,
        isActive: true,
      });

      logger.info('Profesor agregado a tenant', { professorId, tenantId });
      return professorTenant;
    } catch (error) {
      logger.error('Error agregando profesor a tenant', {
        professorId,
        tenantId,
        error: (error as Error).message,
      });
      throw error;
    }
  }

  /**
   * Agregar estudiante a tenant (se llama automáticamente en primera reserva)
   */
  async addStudentToTenant(
    studentId: string,
    tenantId: string,
  ): Promise<StudentTenantDocument> {
    try {
      // Verificar que el estudiante existe
      const student = await StudentModel.findById(studentId);
      if (!student) {
        throw new Error('Estudiante no encontrado');
      }

      // Verificar que el tenant existe
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        throw new Error('Tenant no encontrado');
      }

      // Verificar que no existe la relación
      const existing = await StudentTenantModel.findOne({
        studentId: student._id,
        tenantId: tenant._id,
      });

      if (existing) {
        if (existing.isActive) {
          // Ya existe y está activo, retornar existente
          return existing;
        }
        // Reactivar la relación
        existing.isActive = true;
        existing.balance = existing.balance || 0; // Mantener balance existente
        await existing.save();
        return existing;
      }

      // Crear nueva relación con balance inicial en 0
      const studentTenant = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        balance: 0,
        isActive: true,
      });

      logger.info('Estudiante agregado a tenant', { studentId, tenantId });
      return studentTenant;
    } catch (error) {
      logger.error('Error agregando estudiante a tenant', {
        studentId,
        tenantId,
        error: (error as Error).message,
      });
      throw error;
    }
  }

  /**
   * Remover usuario de tenant (desactivar relación)
   */
  async removeUserFromTenant(
    userId: string,
    userRole: UserRole,
    tenantId: string,
  ): Promise<boolean> {
    try {
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        throw new Error('Tenant no encontrado');
      }

      if (userRole === 'professor') {
        const professor = await ProfessorModel.findOne({ authUserId: userId });
        if (!professor) {
          return false; // No tiene relación si no existe el profesor
        }

        const professorTenant = await ProfessorTenantModel.findOne({
          professorId: professor._id,
          tenantId: tenant._id,
        });

        if (professorTenant) {
          professorTenant.isActive = false;
          await professorTenant.save();
          logger.info('Profesor removido de tenant', { professorId: professor._id, tenantId });
          return true;
        }
      } else if (userRole === 'student') {
        const student = await StudentModel.findOne({ authUserId: userId });
        if (!student) {
          return false; // No tiene relación si no existe el estudiante
        }

        const studentTenant = await StudentTenantModel.findOne({
          studentId: student._id,
          tenantId: tenant._id,
        });

        if (studentTenant) {
          studentTenant.isActive = false;
          await studentTenant.save();
          logger.info('Estudiante removido de tenant', { studentId: student._id, tenantId });
          return true;
        }
      } else if (userRole === 'tenant_admin') {
        // No se puede remover un Tenant Admin de su propio tenant
        throw new Error('No se puede remover un Tenant Admin de su tenant');
      }

      return false;
    } catch (error) {
      logger.error('Error removiendo usuario de tenant', {
        userId,
        tenantId,
        error: (error as Error).message,
      });
      throw error;
    }
  }

  /**
   * Generar slug desde nombre
   */
  private generateSlug(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }
}

