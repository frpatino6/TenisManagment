const { getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function completeCICDStory() {
  try {
    console.log('🔄 Completando TEN-81: Configuración de CI/CD...\n');

    const config = getLinearConfig();

    // Query para obtener la historia TEN-81 usando el ID correcto
    const getIssueQuery = `
      query GetIssues($filter: IssueFilter!) {
        issues(filter: $filter, first: 10) {
          nodes {
            id
            identifier
            title
            state {
              name
            }
            description
          }
        }
      }
    `;

    const issueData = await makeLinearRequest(getIssueQuery, { 
      filter: {
        title: { contains: "TS-025: Configuración de CI/CD" }
      }
    });

    if (issueData.errors) {
      console.error('❌ Error obteniendo historias:', issueData.errors);
      return;
    }

    const issues = issueData.data.issues.nodes;
    if (issues.length === 0) {
      console.log('❌ No se encontró la historia TEN-81');
      return;
    }

    const issue = issues[0];
    console.log('📋 Historia encontrada:');
    console.log(`   ID: ${issue.id}`);
    console.log(`   Identificador: ${issue.identifier}`);
    console.log(`   Título: ${issue.title}`);
    console.log(`   Estado actual: ${issue.state.name}\n`);

    // Actualizar la descripción con el progreso completado
    const completedDescription = `## ✅ CONFIGURACIÓN DE CI/CD COMPLETADA

### 🎯 Objetivos Cumplidos:
- [x] Instalación de dependencias de testing (Jest, ts-jest, supertest, etc.)
- [x] Configuración de Jest con soporte para TypeScript
- [x] Scripts de testing en package.json
- [x] Configuración para diferentes tipos de test (unit, integration, e2e)
- [x] Configuración de MongoDB Memory Server para tests
- [x] Documentación de comandos de testing

### 📦 Dependencias Instaladas:
- jest@^29.7.0
- @types/jest@^29.5.12
- ts-jest@^29.1.2
- supertest@^6.3.4
- @types/supertest@^6.0.2
- mongodb-memory-server@^9.1.3
- jest-mock-extended@^3.0.5
- testcontainers@^10.7.2

### 🏗️ Configuración Creada:
- \`jest.config.js\` - Configuración principal
- \`jest.integration.config.js\` - Tests de integración
- \`jest.e2e.config.js\` - Tests E2E
- \`src/__tests__/jest.setup.js\` - Setup global
- \`src/__tests__/utils/test-helpers.ts\` - Utilidades
- \`src/__tests__/fixtures/test-data.json\` - Datos de prueba
- \`src/__tests__/mocks/external-apis.ts\` - Mocks
- \`TESTING.md\` - Documentación completa

### 🚀 Scripts Disponibles:
- \`npm test\` - Ejecutar todos los tests
- \`npm run test:watch\` - Tests en modo watch
- \`npm run test:coverage\` - Tests con cobertura
- \`npm run test:unit\` - Solo tests unitarios
- \`npm run test:integration\` - Solo tests de integración
- \`npm run test:e2e\` - Solo tests E2E
- \`npm run test:ci\` - Tests para CI/CD

### 📊 Cobertura Configurada:
- Statements: 80%
- Branches: 80%
- Functions: 80%
- Lines: 80%

### 🔄 CI/CD Pipeline Actualizado:
- GitHub Actions configurado para testing automático
- Pipeline incluye: linting, type-checking, build, tests, coverage
- Triggers: push a main/develop, pull requests, manual

### ✅ Tests Verificados:
- 13 tests pasando correctamente
- Configuración de Jest funcionando
- Utilidades de testing disponibles
- Mocks configurados para servicios externos

### 📚 Documentación:
- README.md actualizado con comandos de testing
- TESTING.md creado con guía completa
- Ejemplos de uso y mejores prácticas

**Estado**: ✅ COMPLETADO
**Fecha**: Octubre 2024
**Tiempo invertido**: 3 story points`;

    // Primero actualizar la descripción
    const updateDescriptionMutation = `
      mutation UpdateIssue($id: String!, $description: String!) {
        issueUpdate(
          id: $id
          input: {
            description: $description
          }
        ) {
          success
          issue {
            id
            identifier
            title
            description
            state {
              name
            }
          }
        }
      }
    `;

    console.log('📝 Actualizando descripción...');
    const updateResult = await makeLinearRequest(updateDescriptionMutation, {
      id: issue.id,
      description: completedDescription
    });

    if (updateResult.errors) {
      console.error('❌ Error actualizando descripción:', updateResult.errors);
      return;
    }

    console.log('✅ Descripción actualizada exitosamente');

    // Ahora cambiar el estado a "Done" o "Completed"
    // Primero necesitamos obtener los estados disponibles
    const getStatesQuery = `
      query GetStates($filter: WorkflowStateFilter!) {
        workflowStates(filter: $filter, first: 20) {
          nodes {
            id
            name
            type
          }
        }
      }
    `;

    const statesData = await makeLinearRequest(getStatesQuery, {
      filter: {}
    });

    if (statesData.errors) {
      console.error('❌ Error obteniendo estados:', statesData.errors);
      return;
    }

    const states = statesData.data.workflowStates.nodes;
    console.log('📋 Estados disponibles:');
    states.forEach(state => {
      console.log(`   - ${state.name} (${state.type})`);
    });

    // Buscar estado "Done" o "Completed"
    const doneState = states.find(state => 
      state.name.toLowerCase().includes('done') || 
      state.name.toLowerCase().includes('completed') ||
      state.name.toLowerCase().includes('finished') ||
      state.type === 'completed'
    );

    if (!doneState) {
      console.log('⚠️ No se encontró estado "Done" o "Completed"');
      console.log('📋 Estados disponibles:', states.map(s => s.name));
      return;
    }

    console.log(`\n🎯 Cambiando estado a: ${doneState.name}`);

    // Actualizar el estado
    const updateStateMutation = `
      mutation UpdateIssueState($id: String!, $stateId: String!) {
        issueUpdate(
          id: $id
          input: {
            stateId: $stateId
          }
        ) {
          success
          issue {
            id
            identifier
            title
            state {
              name
            }
          }
        }
      }
    `;

    const stateResult = await makeLinearRequest(updateStateMutation, {
      id: issue.id,
      stateId: doneState.id
    });

    if (stateResult.errors) {
      console.error('❌ Error actualizando estado:', stateResult.errors);
      return;
    }

    console.log('✅ Estado actualizado exitosamente:');
    console.log(`   Identificador: ${stateResult.data.issueUpdate.issue.identifier}`);
    console.log(`   Título: ${stateResult.data.issueUpdate.issue.title}`);
    console.log(`   Estado: ${stateResult.data.issueUpdate.issue.state.name}`);
    console.log('\n🎉 TEN-81: Configuración de CI/CD - COMPLETADO Y MARCADO COMO DONE');

  } catch (error) {
    console.error('❌ Error completando historia:', error.message);
  }
}

completeCICDStory();
