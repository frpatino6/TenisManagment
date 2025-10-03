#!/usr/bin/env node

/**
 * Script para estandarizar el formato de historias en backlog
 * Tennis Management System
 */

const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

// Plantillas de descripción estándar por tipo de historia
const getStandardDescription = (issue) => {
  const title = issue.title;
  const currentDesc = issue.currentDescription || '';
  
  // Determinar el tipo de historia basado en el título
  let storyType = 'feature';
  if (title.toLowerCase().includes('epic')) storyType = 'epic';
  if (title.toLowerCase().includes('webhook')) storyType = 'integration';
  if (title.toLowerCase().includes('email')) storyType = 'communication';
  if (title.toLowerCase().includes('wizard') || title.toLowerCase().includes('dashboard')) storyType = 'ui';
  if (title.toLowerCase().includes('middleware') || title.toLowerCase().includes('service')) storyType = 'backend';
  if (title.toLowerCase().includes('stripe') || title.toLowerCase().includes('billing')) storyType = 'billing';
  if (title.toLowerCase().includes('landing') || title.toLowerCase().includes('help center')) storyType = 'marketing';

  // Extraer información existente
  const hasAcceptanceCriteria = currentDesc.includes('## Acceptance Criteria') || currentDesc.includes('### Scenario:');
  const hasDefinitionOfDone = currentDesc.includes('## Definition of Done') || currentDesc.includes('- [ ]');
  const hasStoryPoints = currentDesc.includes('Story Points:') || currentDesc.includes('## Story Points');
  
  // Extraer story points si existen
  let storyPoints = issue.estimate || 5;
  if (currentDesc.includes('Story Points:')) {
    const match = currentDesc.match(/Story Points:\s*(\d+)/);
    if (match) storyPoints = parseInt(match[1]);
  }

  // Extraer criterios de aceptación existentes
  let acceptanceCriteria = '';
  if (hasAcceptanceCriteria) {
    const criteriaMatch = currentDesc.match(/## Acceptance Criteria([\s\S]*?)(?=##|$)/);
    if (criteriaMatch) {
      acceptanceCriteria = criteriaMatch[1].trim();
    }
  }

  // Extraer Definition of Done existente
  let definitionOfDone = '';
  if (hasDefinitionOfDone) {
    const doneMatch = currentDesc.match(/## Definition of Done([\s\S]*?)(?=##|$)/);
    if (doneMatch) {
      definitionOfDone = doneMatch[1].trim();
    }
  }

  // Crear descripción estándar
  let standardDescription = `## Descripción\n\n${getDescriptionByType(storyType, title)}\n\n`;

  if (acceptanceCriteria) {
    standardDescription += `## Criterios de Aceptación\n\n${acceptanceCriteria}\n\n`;
  } else {
    standardDescription += `## Criterios de Aceptación\n\n${getDefaultAcceptanceCriteria(storyType)}\n\n`;
  }

  if (definitionOfDone) {
    standardDescription += `## Definition of Done\n\n${definitionOfDone}\n\n`;
  } else {
    standardDescription += `## Definition of Done\n\n${getDefaultDefinitionOfDone(storyType)}\n\n`;
  }

  standardDescription += `## Story Points: ${storyPoints} | Priority: ${getPriorityText(issue.priority)} | Sprint: ${getSprintByProject(issue.project)}`;

  return standardDescription;
};

const getDescriptionByType = (type, title) => {
  const descriptions = {
    epic: `Implementar ${title.replace('EPIC-1: ', '').replace('(Backend)', '')} para establecer la base de multi-tenancy en el sistema.`,
    backend: `Implementar ${title} para mejorar la arquitectura y funcionalidad del backend.`,
    ui: `Desarrollar ${title} para mejorar la experiencia de usuario y la interfaz de la aplicación.`,
    integration: `Integrar ${title} para conectar el sistema con servicios externos.`,
    billing: `Implementar ${title} para gestionar suscripciones y pagos.`,
    communication: `Desarrollar ${title} para mejorar la comunicación con los usuarios.`,
    marketing: `Crear ${title} para mejorar la presencia y marketing del producto.`,
    feature: `Implementar ${title} para agregar nueva funcionalidad al sistema.`
  };
  return descriptions[type] || descriptions.feature;
};

const getDefaultAcceptanceCriteria = (type) => {
  const criteria = {
    epic: `### Scenario: Implementación completa\n\n### Given desarrollador\n\n### When implementa todos los componentes\n\n### Then debe funcionar correctamente\n\n### And debe pasar todos los tests`,
    backend: `### Scenario: Funcionalidad implementada\n\n### Given desarrollador\n\n### When implementa la funcionalidad\n\n### Then debe funcionar según especificaciones\n\n### And debe incluir manejo de errores`,
    ui: `### Scenario: Interfaz implementada\n\n### Given usuario\n\n### When accede a la funcionalidad\n\n### Then debe ver la interfaz correctamente\n\n### And debe ser responsive`,
    integration: `### Scenario: Integración funcionando\n\n### Given sistema configurado\n\n### When se ejecuta la integración\n\n### Then debe conectar correctamente\n\n### And debe manejar errores apropiadamente`,
    billing: `### Scenario: Proceso de billing\n\n### Given usuario con suscripción\n\n### When procesa pago\n\n### Then debe completar transacción\n\n### And debe actualizar estado`,
    communication: `### Scenario: Comunicación enviada\n\n### Given usuario objetivo\n\n### When se envía comunicación\n\n### Then debe llegar correctamente\n\n### And debe incluir información relevante`,
    marketing: `### Scenario: Material de marketing\n\n### Given visitante\n\n### When accede al material\n\n### Then debe ver información clara\n\n### And debe incluir call-to-action`,
    feature: `### Scenario: Funcionalidad implementada\n\n### Given usuario\n\n### When usa la funcionalidad\n\n### Then debe funcionar correctamente\n\n### And debe cumplir requisitos`
  };
  return criteria[type] || criteria.feature;
};

const getDefaultDefinitionOfDone = (type) => {
  const done = {
    epic: `- [ ] Todos los componentes implementados\n- [ ] Tests unitarios >80% coverage\n- [ ] Tests de integración pasando\n- [ ] Documentación actualizada\n- [ ] Code review aprobado\n- [ ] Deploy a staging exitoso`,
    backend: `- [ ] Funcionalidad implementada\n- [ ] Tests unitarios >80% coverage\n- [ ] Tests de integración\n- [ ] Manejo de errores robusto\n- [ ] Documentación API actualizada\n- [ ] Code review aprobado`,
    ui: `- [ ] Interfaz implementada\n- [ ] Responsive design\n- [ ] Tests de UI pasando\n- [ ] Accesibilidad verificada\n- [ ] Performance optimizada\n- [ ] Code review aprobado`,
    integration: `- [ ] Integración implementada\n- [ ] Tests de conexión\n- [ ] Manejo de errores\n- [ ] Logs de auditoría\n- [ ] Documentación de configuración\n- [ ] Code review aprobado`,
    billing: `- [ ] Funcionalidad de billing implementada\n- [ ] Tests de transacciones\n- [ ] Seguridad verificada\n- [ ] Webhooks funcionando\n- [ ] Documentación de flujo\n- [ ] Code review aprobado`,
    communication: `- [ ] Sistema de comunicación implementado\n- [ ] Templates creados\n- [ ] Tests de envío\n- [ ] Personalización funcionando\n- [ ] Analytics configurado\n- [ ] Code review aprobado`,
    marketing: `- [ ] Material de marketing creado\n- [ ] SEO optimizado\n- [ ] Analytics configurado\n- [ ] Performance verificada\n- [ ] Tests de conversión\n- [ ] Code review aprobado`,
    feature: `- [ ] Funcionalidad implementada\n- [ ] Tests unitarios\n- [ ] Tests de integración\n- [ ] Documentación actualizada\n- [ ] Performance verificada\n- [ ] Code review aprobado`
  };
  return done[type] || done.feature;
};

const getPriorityText = (priority) => {
  const priorities = {
    1: 'P0',
    2: 'P1', 
    3: 'P2',
    4: 'P3'
  };
  return priorities[priority] || 'P2';
};

const getSprintByProject = (project) => {
  const sprintMap = {
    'Multi-Tenancy Backend': '1',
    'Multi-Tenancy Frontend': '2', 
    'Tenant Signup & Onboarding': '3',
    'Subscription & Billing': '6',
    'Plan Management & Limits': '6',
    'Super Admin Dashboard': '8',
    'Go-to-Market': '11',
    'Quality & DevOps': '1'
  };
  return sprintMap[project] || 'TBD';
};

async function standardizeBacklogStories() {
  try {
    console.log('📋 Estandarizando historias en backlog...\n');

    const { teamId } = getLinearConfig();

    // Obtener todas las historias en backlog
    const issuesQuery = `
      query {
        issues(first: 50, filter: { state: { name: { eq: "Backlog" } } }) {
          nodes {
            id
            title
            description
            number
            state {
              name
            }
            labels {
              nodes {
                name
                color
              }
            }
            estimate
            priority
            project {
              name
            }
            url
          }
        }
      }
    `;

    const issuesResponse = await makeLinearRequest(issuesQuery);
    const backlogIssues = issuesResponse.data.issues.nodes;

    console.log(`📋 Historias en backlog encontradas: ${backlogIssues.length}\n`);

    let updatedCount = 0;
    let errorCount = 0;

    for (const issue of backlogIssues) {
      console.log(`📝 Actualizando: #${issue.number} - ${issue.title}`);
      console.log(`   📁 Proyecto: ${issue.project?.name || 'Sin proyecto'}`);
      
      try {
        // Generar nueva descripción estándar
        const newDescription = getStandardDescription({
          title: issue.title,
          currentDescription: issue.description,
          estimate: issue.estimate,
          priority: issue.priority,
          project: issue.project?.name || 'Sin proyecto'
        });

        // Actualizar la issue
        const updateMutation = `
          mutation {
            issueUpdate(id: "${issue.id}", input: {
              description: ${JSON.stringify(newDescription)}
            }) {
              issue {
                id
                title
                number
                description
              }
            }
          }
        `;

        const updateResponse = await makeLinearRequest(updateMutation);
        const updatedIssue = updateResponse.data.issueUpdate.issue;
        
        console.log(`   ✅ Actualizada exitosamente`);
        console.log(`   📊 Story Points: ${issue.estimate || 'Sin estimación'}`);
        console.log(`   ⚡ Priority: ${getPriorityText(issue.priority)}`);
        console.log(`   🏷️  Labels: ${issue.labels.nodes.map(l => l.name).join(', ') || 'Sin labels'}`);
        
        updatedCount++;
        
      } catch (error) {
        console.log(`   ❌ Error: ${error.message}`);
        errorCount++;
      }
      
      console.log('');
    }

    console.log(`🎉 ¡Estandarización completada!`);
    console.log(`📊 Historias actualizadas: ${updatedCount}`);
    console.log(`❌ Errores: ${errorCount}`);

    console.log('\n📋 RESUMEN DE CAMBIOS:');
    console.log('─'.repeat(50));
    console.log('✅ Formato estándar aplicado a todas las historias');
    console.log('✅ Criterios de aceptación estandarizados');
    console.log('✅ Definition of Done consistente');
    console.log('✅ Story Points y Priority formateados');
    console.log('✅ Sprint assignment basado en proyecto');

  } catch (error) {
    console.error('❌ Error estandarizando historias:', error.message);
    if (error.response) {
      console.error('Response:', error.response);
    }
    process.exit(1);
  }
}

// Ejecutar el script
standardizeBacklogStories();
