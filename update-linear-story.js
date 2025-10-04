const { getLinearConfig, makeLinearRequest } = require('./scripts/linear-utils');

async function updateCICDStory() {
  try {
    console.log('🔄 Actualizando estado de TEN-81: Configuración de CI/CD...\n');

    const config = getLinearConfig();

    // Query para obtener la historia TEN-81
    const getIssueQuery = `
      query GetIssue($identifier: String!) {
        issue(identifier: $identifier) {
          id
          identifier
          title
          state {
            name
          }
          description
        }
      }
    `;

    const issueData = await makeLinearRequest(getIssueQuery, { 
      identifier: 'TEN-81' 
    });

    if (issueData.errors) {
      console.error('❌ Error obteniendo historia:', issueData.errors);
      return;
    }

    const issue = issueData.data.issue;
    console.log('📋 Historia encontrada:');
    console.log(`   ID: ${issue.id}`);
    console.log(`   Identificador: ${issue.identifier}`);
    console.log(`   Título: ${issue.title}`);
    console.log(`   Estado actual: ${issue.state.name}\n`);

    // Actualizar la descripción con el progreso
    const updatedDescription = `## ✅ CONFIGURACIÓN DE CI/CD COMPLETADA

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

    // Actualizar la historia
    const updateMutation = `
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

    const updateResult = await makeLinearRequest(updateMutation, {
      id: issue.id,
      description: updatedDescription
    });

    if (updateResult.errors) {
      console.error('❌ Error actualizando historia:', updateResult.errors);
      return;
    }

    console.log('✅ Historia actualizada exitosamente:');
    console.log(`   Identificador: ${updateResult.data.issueUpdate.issue.identifier}`);
    console.log(`   Título: ${updateResult.data.issueUpdate.issue.title}`);
    console.log(`   Estado: ${updateResult.data.issueUpdate.issue.state.name}`);
    console.log('\n🎉 TEN-81: Configuración de CI/CD - COMPLETADO');

  } catch (error) {
    console.error('❌ Error actualizando historia:', error.message);
  }
}

updateCICDStory();
