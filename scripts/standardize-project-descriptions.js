#!/usr/bin/env node

/**
 * Script para estandarizar descripciones de proyectos
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Plantillas de descripción estándar por tipo de proyecto
const getStandardProjectDescription = (project) => {
  const name = project.name;
  const state = project.state;
  const issuesCount = project.issuesCount;
  
  // Determinar el tipo de proyecto
  let projectType = 'feature';
  if (name.toLowerCase().includes('backend')) projectType = 'backend';
  if (name.toLowerCase().includes('frontend')) projectType = 'frontend';
  if (name.toLowerCase().includes('multi-tenancy')) projectType = 'foundation';
  if (name.toLowerCase().includes('billing') || name.toLowerCase().includes('subscription')) projectType = 'billing';
  if (name.toLowerCase().includes('admin') || name.toLowerCase().includes('dashboard')) projectType = 'admin';
  if (name.toLowerCase().includes('onboarding') || name.toLowerCase().includes('signup')) projectType = 'onboarding';
  if (name.toLowerCase().includes('messaging') || name.toLowerCase().includes('chat')) projectType = 'messaging';
  if (name.toLowerCase().includes('notifications')) projectType = 'notifications';
  if (name.toLowerCase().includes('testing') || name.toLowerCase().includes('quality')) projectType = 'quality';
  if (name.toLowerCase().includes('gtm') || name.toLowerCase().includes('go-to-market')) projectType = 'marketing';

  return getDescriptionByType(projectType, name, state, issuesCount);
};

const getDescriptionByType = (type, name, state, issuesCount) => {
  const descriptions = {
    backend: `## Objetivo

Implementar la infraestructura backend para ${name.toLowerCase().replace('backend - ', '').replace('sistema de ', '')} que permita el funcionamiento robusto y escalable del sistema.

## Alcance

- APIs RESTful para todas las funcionalidades
- Modelos de datos y esquemas de base de datos
- Servicios de negocio y lógica de aplicación
- Middleware de autenticación y autorización
- Validación de datos y manejo de errores
- Integración con servicios externos
- Testing unitario e integración

## Criterios de Éxito

- APIs funcionando correctamente con >95% uptime
- Tests unitarios con >80% coverage
- Performance <200ms response time promedio
- Documentación API completa y actualizada
- Code review aprobado por 2+ desarrolladores
- Deploy exitoso a staging y producción

## Dependencias

- Base de datos configurada y migrada
- Servicios de autenticación implementados
- Infraestructura de testing establecida

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Backend Developers
- 1 DevOps Engineer (part-time)
- Herramientas: Node.js, MongoDB, Jest, Postman`,

    frontend: `## Objetivo

Desarrollar interfaces de usuario modernas y responsivas para ${name.toLowerCase().replace('frontend - ', '').replace('sistema de ', '')} que proporcionen una excelente experiencia de usuario.

## Alcance

- Componentes de UI reutilizables
- Pantallas y flujos de usuario completos
- Integración con APIs backend
- Manejo de estados y datos
- Responsive design para móvil y desktop
- Testing de componentes e integración
- Optimización de performance

## Criterios de Éxito

- UI/UX consistente con design system
- Performance <3s load time inicial
- Responsive en todos los dispositivos
- Tests de componentes >80% coverage
- Accesibilidad WCAG 2.1 AA
- Code review aprobado por 2+ desarrolladores
- Deploy exitoso a staging y producción

## Dependencias

- APIs backend implementadas y documentadas
- Design system y componentes base
- Sistema de autenticación funcionando

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Frontend Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Dart, Firebase`,

    foundation: `## Objetivo

Establecer la base arquitectónica de ${name.toLowerCase()} que permita la escalabilidad y mantenibilidad del sistema a largo plazo.

## Alcance

- Arquitectura de datos y modelos base
- Servicios fundamentales del sistema
- Middleware y utilidades compartidas
- Configuración de infraestructura
- Documentación arquitectónica
- Testing de integración
- Migración de datos existentes

## Criterios de Éxito

- Arquitectura implementada y documentada
- Migración de datos sin pérdida
- Performance optimizada para escalabilidad
- Tests de integración >90% coverage
- Documentación técnica completa
- Code review aprobado por arquitecto
- Deploy exitoso sin downtime

## Dependencias

- Análisis de requisitos completado
- Diseño arquitectónico aprobado
- Infraestructura base configurada

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Senior Developers
- 1 System Architect
- 1 DevOps Engineer
- Herramientas: Node.js, MongoDB, Docker`,

    billing: `## Objetivo

Implementar sistema completo de ${name.toLowerCase()} para monetizar la plataforma y gestionar suscripciones de usuarios.

## Alcance

- Integración con Stripe para pagos
- Planes de suscripción (Free, Pro, Enterprise)
- Flujos de checkout y upgrade
- Webhooks para eventos de pago
- Gestión de límites por plan
- Reportes de facturación
- Testing de transacciones

## Criterios de Éxito

- Integración con Stripe funcionando 100%
- <3% tasa de fallos en pagos
- Conversión trial-to-paid >5%
- Webhooks procesados correctamente
- Reportes de facturación precisos
- Tests de transacciones completos
- Compliance con PCI DSS

## Dependencias

- Cuenta Stripe configurada
- Modelos de usuario y tenant implementados
- Sistema de autenticación funcionando

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Backend Developers
- 1 Frontend Developer
- 1 DevOps Engineer (part-time)
- Herramientas: Stripe, Node.js, MongoDB`,

    admin: `## Objetivo

Desarrollar ${name.toLowerCase()} para proporcionar herramientas de administración y supervisión del sistema.

## Alcance

- Dashboard con métricas en tiempo real
- Gestión de usuarios y permisos
- Herramientas de administración
- Reportes y analytics
- Configuración del sistema
- Logs y auditoría
- Testing de funcionalidad administrativa

## Criterios de Éxito

- Dashboard cargando en <2 segundos
- Métricas actualizadas en tiempo real
- Gestión de usuarios funcionando
- Reportes generándose correctamente
- Tests de funcionalidad >80% coverage
- Seguridad administrativa verificada
- Code review aprobado por 2+ desarrolladores

## Dependencias

- APIs de métricas implementadas
- Sistema de autenticación y roles
- Base de datos con datos de prueba

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Full-stack Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Node.js, MongoDB`,

    onboarding: `## Objetivo

Crear ${name.toLowerCase()} que facilite la incorporación de nuevos usuarios y mejore la experiencia de primer uso.

## Alcance

- Flujos de registro y configuración inicial
- Wizard paso a paso para setup
- Emails de bienvenida y confirmación
- Tutoriales y guías interactivas
- Validación de datos y errores
- Testing de flujos completos
- Analytics de conversión

## Criterios de Éxito

- Tasa de completación de onboarding >80%
- Tiempo promedio de setup <10 minutos
- Emails de bienvenida enviándose
- Tutoriales funcionando correctamente
- Tests E2E del flujo completo
- Analytics tracking implementado
- Code review aprobado

## Dependencias

- Sistema de autenticación implementado
- Templates de email configurados
- Base de datos con esquemas necesarios

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Full-stack Developers
- 1 UI/UX Designer
- Herramientas: Flutter, Node.js, SendGrid`,

    messaging: `## Objetivo

Implementar ${name.toLowerCase()} que permita comunicación efectiva entre profesores y estudiantes.

## Alcance

- Chat en tiempo real entre usuarios
- Gestión de conversaciones y mensajes
- Notificaciones push y en-app
- Estados de mensaje (enviado, leído, etc.)
- Integración con perfiles de usuario
- Testing de funcionalidad de chat
- Optimización de performance

## Criterios de Éxito

- Mensajes entregándose en <1 segundo
- Notificaciones funcionando correctamente
- Chat responsive en todos los dispositivos
- Estados de mensaje actualizándose
- Tests de funcionalidad >80% coverage
- Performance optimizada para múltiples usuarios
- Code review aprobado

## Dependencias

- Sistema de autenticación funcionando
- Perfiles de usuario implementados
- Infraestructura de tiempo real configurada

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Full-stack Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Node.js, WebSocket, Firebase`,

    notifications: `## Objetivo

Desarrollar ${name.toLowerCase()} para mantener a los usuarios informados y comprometidos con la plataforma.

## Alcance

- Sistema de notificaciones push
- Notificaciones en-app
- Templates de notificación
- Configuración de preferencias
- Analytics de engagement
- Testing de entrega de notificaciones
- Optimización de timing

## Criterios de Éxito

- Notificaciones entregándose >95% del tiempo
- Tiempo de entrega <30 segundos
- Templates funcionando correctamente
- Preferencias de usuario respetadas
- Analytics de engagement implementados
- Tests de entrega completos
- Code review aprobado

## Dependencias

- Sistema de autenticación implementado
- Servicio de notificaciones configurado
- Base de datos con preferencias de usuario

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Backend Developers
- 1 Frontend Developer
- Herramientas: Firebase Cloud Messaging, Node.js`,

    quality: `## Objetivo

Establecer ${name.toLowerCase()} para asegurar la calidad, rendimiento y mantenibilidad del sistema.

## Alcance

- Testing unitario e integración
- Testing E2E automatizado
- Optimización de performance
- Documentación técnica
- CI/CD pipeline
- Monitoreo y alertas
- Code quality tools

## Criterios de Éxito

- Coverage de tests >80%
- Performance <200ms response time
- CI/CD pipeline funcionando
- Documentación actualizada
- Monitoreo configurado
- Code quality metrics cumplidas
- Deploy automatizado funcionando

## Dependencias

- Código base estable
- Infraestructura de testing configurada
- Herramientas de CI/CD disponibles

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 QA Engineers
- 1 DevOps Engineer
- 1 Technical Writer (part-time)
- Herramientas: Jest, Cypress, GitHub Actions`,

    marketing: `## Objetivo

Desarrollar ${name.toLowerCase()} para impulsar el crecimiento y la adquisición de clientes.

## Alcance

- Landing page optimizada para conversión
- Help center con documentación
- Materiales de marketing
- Analytics de conversión
- SEO y performance
- A/B testing setup
- Integración con herramientas de marketing

## Criterios de Éxito

- Landing page cargando en <3 segundos
- Tasa de conversión >2%
- Help center con >20 artículos
- SEO score >90
- Analytics tracking implementado
- A/B testing funcionando
- Code review aprobado

## Dependencias

- Brand guidelines definidas
- Contenido de marketing creado
- Herramientas de analytics configuradas

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Frontend Developers
- 1 Marketing Specialist
- 1 Content Writer (part-time)
- Herramientas: Flutter, Firebase, Google Analytics`,

    feature: `## Objetivo

Implementar ${name.toLowerCase()} para agregar nueva funcionalidad al sistema y mejorar la experiencia del usuario.

## Alcance

- Desarrollo de funcionalidad completa
- Integración con sistemas existentes
- Testing unitario e integración
- Documentación de usuario
- Optimización de performance
- Testing de usabilidad
- Deploy y monitoreo

## Criterios de Éxito

- Funcionalidad implementada según especificaciones
- Tests unitarios >80% coverage
- Performance optimizada
- Documentación completa
- Usabilidad verificada
- Deploy exitoso sin errores
- Code review aprobado

## Dependencias

- Requisitos claramente definidos
- APIs necesarias implementadas
- Infraestructura base funcionando

## Timeline

Estimado: ${getTimelineByIssues(issuesCount)} semanas
Estado actual: ${state}

## Recursos

- 1-2 Full-stack Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Node.js, MongoDB`
  };

  return descriptions[type] || descriptions.feature;
};

const getTimelineByIssues = (issuesCount) => {
  if (issuesCount <= 2) return '1-2';
  if (issuesCount <= 4) return '2-3';
  if (issuesCount <= 6) return '3-4';
  return '4-6';
};

async function standardizeProjectDescriptions() {
  try {
    console.log('📋 Estandarizando descripciones de proyectos...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los proyectos
    const projectsQuery = `
      query {
        projects(first: 20) {
          nodes {
            id
            name
            description
            state
            startDate
            targetDate
            url
            issues {
              nodes {
                id
                title
                number
                state {
                  name
                }
              }
            }
          }
        }
      }
    `;

    const projectsResponse = await makeLinearRequest(projectsQuery);
    const allProjects = projectsResponse.data.projects.nodes;

    console.log(`📋 Proyectos encontrados: ${allProjects.length}\n`);

    let updatedCount = 0;
    let errorCount = 0;

    for (const project of allProjects) {
      console.log(`📝 Actualizando: ${project.name}`);
      console.log(`   📅 Estado: ${project.state}`);
      console.log(`   📊 Issues: ${project.issues.nodes.length}`);
      
      try {
        // Generar nueva descripción estándar
        const newDescription = getStandardProjectDescription({
          name: project.name,
          state: project.state,
          issuesCount: project.issues.nodes.length
        });

        // Actualizar el proyecto
        const updateMutation = `
          mutation {
            projectUpdate(id: "${project.id}", input: {
              description: ${JSON.stringify(newDescription)}
            }) {
              success
              project {
                id
                name
                description
              }
            }
          }
        `;

        const updateResponse = await makeLinearRequest(updateMutation);
        const updatedProject = updateResponse.data.projectUpdate?.project;
        
        console.log(`   ✅ Actualizado exitosamente`);
        console.log(`   📝 Nueva descripción: ${newDescription.length} caracteres`);
        
        updatedCount++;
        
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
        errorCount++;
      }
      
      console.log('');
    }

    console.log(`🎉 ¡Estandarización completada!`);
    console.log(`📊 Proyectos actualizados: ${updatedCount}`);
    console.log(`❌ Errores: ${errorCount}`);

    console.log('\n📋 RESUMEN DE CAMBIOS:');
    console.log('─'.repeat(50));
    console.log('✅ Descripciones estandarizadas con estructura profesional');
    console.log('✅ Objetivos claros definidos para cada proyecto');
    console.log('✅ Alcance detallado especificado');
    console.log('✅ Criterios de éxito medibles');
    console.log('✅ Dependencias identificadas');
    console.log('✅ Timeline estimado por proyecto');
    console.log('✅ Recursos necesarios especificados');

  } catch (error) {
    console.error('❌ Error estandarizando proyectos:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
standardizeProjectDescriptions();
