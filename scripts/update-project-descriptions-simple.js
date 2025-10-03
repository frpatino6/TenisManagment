#!/usr/bin/env node

/**
 * Script simple para actualizar descripciones de proyectos
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Descripciones estándar para cada proyecto
const projectDescriptions = {
  'Backend - Sistema de Mensajería': `## Objetivo

Implementar la infraestructura backend para el sistema de mensajería que permita el funcionamiento robusto y escalable del sistema.

## Alcance

- APIs RESTful para todas las funcionalidades de mensajería
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

## Timeline

Estimado: 2-3 semanas
Estado actual: planned

## Recursos

- 1-2 Backend Developers
- 1 DevOps Engineer (part-time)
- Herramientas: Node.js, MongoDB, Jest, Postman`,

  'Frontend - Chat y Comunicación': `## Objetivo

Desarrollar interfaces de usuario modernas y responsivas para el sistema de chat y comunicación que proporcionen una excelente experiencia de usuario.

## Alcance

- Componentes de UI reutilizables para chat
- Pantallas de conversaciones y mensajes
- Integración con APIs backend
- Manejo de estados y datos en tiempo real
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

## Timeline

Estimado: 3-4 semanas
Estado actual: planned

## Recursos

- 1-2 Frontend Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Dart, Firebase`,

  'Notificaciones y Tiempo Real': `## Objetivo

Desarrollar sistema de notificaciones y tiempo real para mantener a los usuarios informados y comprometidos con la plataforma.

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

## Timeline

Estimado: 2-3 semanas
Estado actual: planned

## Recursos

- 1-2 Backend Developers
- 1 Frontend Developer
- Herramientas: Firebase Cloud Messaging, Node.js`,

  'Gestión de Estudiantes': `## Objetivo

Implementar funcionalidades para gestión y seguimiento de estudiantes que mejoren la experiencia de los profesores.

## Alcance

- Pantalla de historial de clases
- API de historial de clases del estudiante
- Integración con perfil de estudiante
- Estados de carga y error
- Testing de funcionalidad
- Optimización de performance

## Criterios de Éxito

- Historial cargando en <2 segundos
- Datos actualizados en tiempo real
- Integración funcionando correctamente
- Estados de carga y error manejados
- Tests de funcionalidad >80% coverage
- Performance optimizada
- Code review aprobado

## Timeline

Estimado: 1-2 semanas
Estado actual: planned

## Recursos

- 1-2 Full-stack Developers
- 1 UI/UX Designer (part-time)
- Herramientas: Flutter, Node.js, MongoDB`,

  'Testing y Optimización': `## Objetivo

Establecer testing y optimización del sistema de mensajería para asegurar la calidad, rendimiento y mantenibilidad.

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

## Timeline

Estimado: 1-2 semanas
Estado actual: planned

## Recursos

- 1-2 QA Engineers
- 1 DevOps Engineer
- 1 Technical Writer (part-time)
- Herramientas: Jest, Cypress, GitHub Actions`,

  'Sistema de Mensajería': `## Objetivo

Sistema completo de comunicación entre profesores y estudiantes, incluyendo chat en tiempo real, notificaciones y gestión de conversaciones.

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

## Timeline

Estimado: 4-6 semanas
Estado actual: planned

## Recursos

- 2-3 Full-stack Developers
- 1 UI/UX Designer
- 1 DevOps Engineer (part-time)
- Herramientas: Flutter, Node.js, WebSocket, Firebase`
};

async function updateProjectDescriptions() {
  try {
    console.log('📋 Actualizando descripciones de proyectos...\n');

    const { teamId } = getLinearConfig();

    // Obtener todos los proyectos
    const projectsQuery = `
      query {
        projects(first: 50) {
          nodes {
            id
            name
            description
            state
            issues {
              nodes {
                id
                title
                number
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
      console.log(`📝 Procesando: ${project.name}`);
      console.log(`   📅 Estado: ${project.state}`);
      console.log(`   📊 Issues: ${project.issues.nodes.length}`);
      
      // Verificar si tenemos una descripción para este proyecto
      const newDescription = projectDescriptions[project.name];
      
      if (!newDescription) {
        console.log(`   ⚠️  No hay descripción estándar para este proyecto`);
        continue;
      }
      
      try {
        // Actualizar el proyecto usando la mutación correcta
        const updateMutation = `
          mutation {
            projectUpdate(
              id: "${project.id}"
              input: {
                description: ${JSON.stringify(newDescription)}
              }
            ) {
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
        
        if (updateResponse.data.projectUpdate?.success) {
          console.log(`   ✅ Actualizado exitosamente`);
          console.log(`   📝 Nueva descripción: ${newDescription.length} caracteres`);
          updatedCount++;
        } else {
          console.log(`   ❌ Error en la actualización`);
          errorCount++;
        }
        
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
        errorCount++;
      }
      
      console.log('');
    }

    console.log(`🎉 ¡Actualización completada!`);
    console.log(`📊 Proyectos actualizados: ${updatedCount}`);
    console.log(`❌ Errores: ${errorCount}`);

    console.log('\n📋 PROYECTOS ACTUALIZADOS:');
    console.log('─'.repeat(50));
    Object.keys(projectDescriptions).forEach(projectName => {
      console.log(`✅ ${projectName}`);
    });

  } catch (error) {
    console.error('❌ Error actualizando proyectos:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
updateProjectDescriptions();
