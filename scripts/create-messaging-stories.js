#!/usr/bin/env node

/**
 * Script para crear historias de usuario del sistema de mensajería
 * Tennis Management System - Sistema de Comunicación Profesor-Estudiante
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Definir las historias de usuario
const messagingStories = [
  // SPRINT 1: Backend de Mensajería
  {
    title: "US-001: Modelo de Datos de Mensajes",
    description: `**Como** desarrollador backend
**Quiero** crear el modelo de datos para mensajes
**Para** almacenar y gestionar la comunicación entre usuarios

## Criterios de Aceptación:
- [ ] Crear entidad \`Message\` con campos: id, senderId, receiverId, content, timestamp, readStatus
- [ ] Crear modelo MongoDB \`MessageModel\`
- [ ] Implementar validaciones de datos
- [ ] Crear índices para optimizar consultas

## Archivos a crear:
- \`backend/src/domain/entities/Message.ts\`
- \`backend/src/infrastructure/database/models/MessageModel.ts\`

## Estimación:** 2 story points`,
    priority: 1, // Urgent
    estimate: 2,
    labels: ["backend", "messaging", "data-model"],
    sprint: "Sprint 1: Backend de Mensajería"
  },
  {
    title: "US-002: API de Envío de Mensajes",
    description: `**Como** profesor
**Quiero** enviar mensajes a mis estudiantes
**Para** comunicarme directamente con ellos

## Criterios de Aceptación:
- [ ] Endpoint \`POST /api/messaging/send\`
- [ ] Validación de autenticación
- [ ] Validación de que el profesor puede enviar al estudiante
- [ ] Almacenamiento del mensaje en BD
- [ ] Respuesta con confirmación de envío

## Archivos a crear:
- \`backend/src/application/controllers/MessagingController.ts\`
- \`backend/src/application/services/MessagingService.ts\`
- \`backend/src/presentation/routes/messaging.ts\`

## Estimación:** 3 story points`,
    priority: 1, // Urgent
    estimate: 3,
    labels: ["backend", "messaging", "api"],
    sprint: "Sprint 1: Backend de Mensajería"
  },
  {
    title: "US-003: API de Conversaciones",
    description: `**Como** profesor
**Quiero** ver mis conversaciones activas
**Para** acceder rápidamente a los chats con mis estudiantes

## Criterios de Aceptación:
- [ ] Endpoint \`GET /api/messaging/conversations\`
- [ ] Lista de conversaciones con último mensaje
- [ ] Información del estudiante (nombre, foto)
- [ ] Contador de mensajes no leídos
- [ ] Ordenamiento por último mensaje

## Estimación:** 3 story points`,
    priority: 1, // Urgent
    estimate: 3,
    labels: ["backend", "messaging", "api"],
    sprint: "Sprint 1: Backend de Mensajería"
  },
  {
    title: "US-004: API de Historial de Mensajes",
    description: `**Como** profesor
**Quiero** ver el historial completo de mensajes con un estudiante
**Para** revisar conversaciones anteriores

## Criterios de Aceptación:
- [ ] Endpoint \`GET /api/messaging/messages/:conversationId\`
- [ ] Paginación de mensajes
- [ ] Información del remitente
- [ ] Timestamps de mensajes
- [ ] Estado de lectura

## Estimación:** 2 story points`,
    priority: 2, // High
    estimate: 2,
    labels: ["backend", "messaging", "api"],
    sprint: "Sprint 1: Backend de Mensajería"
  },

  // SPRINT 2: Frontend de Chat
  {
    title: "US-005: Pantalla de Lista de Conversaciones",
    description: `**Como** profesor
**Quiero** ver una lista de mis conversaciones
**Para** acceder fácilmente a los chats con mis estudiantes

## Criterios de Aceptación:
- [ ] Lista de conversaciones con estudiantes
- [ ] Último mensaje visible
- [ ] Contador de mensajes no leídos
- [ ] Foto y nombre del estudiante
- [ ] Ordenamiento por actividad reciente
- [ ] Pull-to-refresh

## Archivos a crear:
- \`mobile/lib/features/messaging/presentation/screens/conversations_list_screen.dart\`
- \`mobile/lib/features/messaging/presentation/widgets/conversation_card.dart\`

## Estimación:** 5 story points`,
    priority: 1, // Urgent
    estimate: 5,
    labels: ["frontend", "messaging", "ui"],
    sprint: "Sprint 2: Frontend de Chat"
  },
  {
    title: "US-006: Pantalla de Chat Individual",
    description: `**Como** profesor
**Quiero** chatear con un estudiante específico
**Para** comunicarme directamente con él

## Criterios de Aceptación:
- [ ] Interfaz de chat con burbujas de mensaje
- [ ] Campo de texto para escribir mensajes
- [ ] Botón de envío
- [ ] Scroll automático a mensajes nuevos
- [ ] Indicador de "escribiendo..."
- [ ] Timestamps de mensajes

## Archivos a crear:
- \`mobile/lib/features/messaging/presentation/screens/chat_screen.dart\`
- \`mobile/lib/features/messaging/presentation/widgets/message_bubble.dart\`
- \`mobile/lib/features/messaging/domain/models/message_model.dart\`
- \`mobile/lib/features/messaging/domain/services/messaging_service.dart\`

## Estimación:** 8 story points`,
    priority: 1, // Urgent
    estimate: 8,
    labels: ["frontend", "messaging", "ui", "chat"],
    sprint: "Sprint 2: Frontend de Chat"
  },
  {
    title: "US-007: Integración con Perfil de Estudiante",
    description: `**Como** profesor
**Quiero** acceder al chat desde el perfil del estudiante
**Para** iniciar conversaciones fácilmente

## Criterios de Aceptación:
- [ ] Reemplazar botón "Contactar" con funcionalidad real
- [ ] Navegación directa al chat
- [ ] Pasar información del estudiante al chat
- [ ] Mantener contexto de navegación

## Archivos a modificar:
- \`mobile/lib/features/professor/presentation/screens/student_profile_screen.dart\`

## Estimación:** 3 story points`,
    priority: 1, // Urgent
    estimate: 3,
    labels: ["frontend", "messaging", "integration"],
    sprint: "Sprint 2: Frontend de Chat"
  },
  {
    title: "US-008: Estados de Carga y Error",
    description: `**Como** profesor
**Quiero** ver estados de carga y manejo de errores
**Para** tener una experiencia fluida

## Criterios de Aceptación:
- [ ] Loading states para envío de mensajes
- [ ] Indicador de mensajes enviados/entregados
- [ ] Manejo de errores de red
- [ ] Retry automático para mensajes fallidos
- [ ] Mensajes de error amigables

## Estimación:** 3 story points`,
    priority: 2, // High
    estimate: 3,
    labels: ["frontend", "messaging", "ux", "error-handling"],
    sprint: "Sprint 2: Frontend de Chat"
  },

  // SPRINT 3: Funcionalidades Avanzadas
  {
    title: "US-009: Notificaciones en Tiempo Real",
    description: `**Como** profesor
**Quiero** recibir notificaciones cuando reciba mensajes
**Para** no perder comunicación importante

## Criterios de Aceptación:
- [ ] WebSocket o polling para mensajes nuevos
- [ ] Notificaciones push (opcional)
- [ ] Sonido de notificación
- [ ] Badge en icono de mensajes
- [ ] Actualización automática de conversaciones

## Estimación:** 5 story points`,
    priority: 2, // High
    estimate: 5,
    labels: ["frontend", "messaging", "notifications", "realtime"],
    sprint: "Sprint 3: Funcionalidades Avanzadas"
  },
  {
    title: "US-010: API de Historial de Clases del Estudiante",
    description: `**Como** profesor
**Quiero** ver el historial de clases de un estudiante
**Para** tener contexto de su progreso

## Criterios de Aceptación:
- [ ] Endpoint \`GET /api/professor/students/:studentId/classes\`
- [ ] Lista de clases con fechas y estados
- [ ] Información de pagos asociados
- [ ] Filtros por período
- [ ] Navegación desde perfil de estudiante

## Archivos a crear:
- \`backend/src/application/controllers/StudentClassesController.ts\`
- \`backend/src/presentation/routes/student-classes.ts\`

## Estimación:** 4 story points`,
    priority: 2, // High
    estimate: 4,
    labels: ["backend", "student-management", "api"],
    sprint: "Sprint 3: Funcionalidades Avanzadas"
  },
  {
    title: "US-011: Pantalla de Historial de Clases",
    description: `**Como** profesor
**Quiero** ver el historial de clases de un estudiante
**Para** revisar su progreso y asistencia

## Criterios de Aceptación:
- [ ] Lista de clases con fechas
- [ ] Estados de clase (completada, cancelada, pendiente)
- [ ] Información de pagos
- [ ] Filtros por período
- [ ] Integración con botón "Ver Clases"

## Archivos a crear:
- \`mobile/lib/features/professor/presentation/screens/student_classes_screen.dart\`
- \`mobile/lib/features/professor/presentation/widgets/class_history_card.dart\`

## Estimación:** 4 story points`,
    priority: 2, // High
    estimate: 4,
    labels: ["frontend", "student-management", "ui"],
    sprint: "Sprint 3: Funcionalidades Avanzadas"
  },
  {
    title: "US-012: Optimizaciones y Testing",
    description: `**Como** desarrollador
**Quiero** optimizar el sistema y completar testing
**Para** asegurar calidad y rendimiento

## Criterios de Aceptación:
- [ ] Testing unitario de backend
- [ ] Testing de integración
- [ ] Optimización de queries
- [ ] Manejo de memoria en frontend
- [ ] Documentación de API

## Estimación:** 3 story points`,
    priority: 3, // Medium
    estimate: 3,
    labels: ["testing", "optimization", "documentation"],
    sprint: "Sprint 3: Funcionalidades Avanzadas"
  }
];

async function createMessagingStories() {
  try {
    console.log('🚀 Creando historias de usuario del sistema de mensajería...\n');

    const { teamId } = getLinearConfig();
    console.log(`📋 Team ID: ${teamId}`);

    // Crear las historias
    for (const story of messagingStories) {
      console.log(`📝 Creando: ${story.title}`);
      
      // Primero obtener los IDs de los labels existentes
      const labelsQuery = `
        query {
          issueLabels(first: 50) {
            nodes {
              id
              name
            }
          }
        }
      `;
      
      const labelsResponse = await makeLinearRequest(labelsQuery);
      const existingLabels = labelsResponse.data.issueLabels.nodes;
      
      // Mapear labels por nombre
      const labelMap = {};
      existingLabels.forEach(label => {
        labelMap[label.name] = label.id;
      });
      
      // Crear labels que no existen
      const labelIds = [];
      for (const labelName of story.labels) {
        if (labelMap[labelName]) {
          labelIds.push(labelMap[labelName]);
        } else {
          // Crear nuevo label
          const createLabelMutation = `
            mutation {
              issueLabelCreate(input: {
                name: "${labelName}"
                teamId: "${teamId}"
              }) {
                issueLabel {
                  id
                  name
                }
              }
            }
          `;
          
          try {
            const createLabelResponse = await makeLinearRequest(createLabelMutation);
            const newLabel = createLabelResponse.data.issueLabelCreate.issueLabel;
            labelIds.push(newLabel.id);
            console.log(`  📌 Label creado: ${newLabel.name}`);
          } catch (error) {
            console.log(`  ⚠️  No se pudo crear label: ${labelName}`);
          }
        }
      }
      
      // Crear el issue
      const createIssueMutation = `
        mutation {
          issueCreate(input: {
            title: "${story.title.replace(/"/g, '\\"')}"
            description: "${story.description.replace(/"/g, '\\"').replace(/\n/g, '\\n')}"
            teamId: "${teamId}"
            priority: ${story.priority}
            estimate: ${story.estimate}
            labelIds: [${labelIds.map(id => `"${id}"`).join(', ')}]
          }) {
            issue {
              id
              title
              number
              url
            }
          }
        }
      `;
      
      const issueResponse = await makeLinearRequest(createIssueMutation);
      const issue = issueResponse.data.issueCreate.issue;
      
      console.log(`✅ Creado: ${issue.title} (ID: ${issue.id}, #${issue.number})`);
    }

    console.log('\n🎉 ¡Todas las historias de usuario han sido creadas exitosamente!');
    console.log('\n📊 Resumen:');
    console.log(`- Total de historias: ${messagingStories.length}`);
    console.log(`- Total de story points: ${messagingStories.reduce((sum, story) => sum + story.estimate, 0)}`);
    
    // Resumen por sprint
    const sprintSummary = {};
    messagingStories.forEach(story => {
      if (!sprintSummary[story.sprint]) {
        sprintSummary[story.sprint] = { count: 0, points: 0 };
      }
      sprintSummary[story.sprint].count++;
      sprintSummary[story.sprint].points += story.estimate;
    });

    console.log('\n📅 Resumen por Sprint:');
    Object.entries(sprintSummary).forEach(([sprint, data]) => {
      console.log(`- ${sprint}: ${data.count} historias, ${data.points} pts`);
    });

  } catch (error) {
    console.error('❌ Error creando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
createMessagingStories();
