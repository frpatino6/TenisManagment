const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function verifyLinearSetup() {
    try {
        const { teamId } = getLinearConfig();
        console.log('🔍 Verificando configuración de Linear...\n');

        // Query simple para verificar issues
        const issuesQuery = `
            query {
                issues(first: 50) {
                    nodes {
                        id
                        identifier
                        title
                        state {
                            name
                        }
                        assignee {
                            name
                        }
                        estimate
                    }
                }
            }
        `;

        const data = await makeLinearRequest(issuesQuery);
        const issues = data.issues.nodes;

        console.log(`✅ Conexión exitosa a Linear`);
        console.log(`📋 Total de issues: ${issues.length}`);

        // Agrupar por estado
        const byState = {};
        issues.forEach(issue => {
            const state = issue.state.name;
            if (!byState[state]) byState[state] = [];
            byState[state].push(issue);
        });

        console.log('\n📊 Issues por estado:');
        Object.keys(byState).forEach(state => {
            console.log(`   ${state}: ${byState[state].length} issues`);
        });

        // Verificar asignaciones
        const assigned = issues.filter(issue => issue.assignee);
        const unassigned = issues.filter(issue => !issue.assignee);
        
        console.log(`\n👤 Asignaciones:`);
        console.log(`   Asignados: ${assigned.length}`);
        console.log(`   Sin asignar: ${unassigned.length}`);

        // Verificar story points
        const withPoints = issues.filter(issue => issue.estimate);
        const withoutPoints = issues.filter(issue => !issue.estimate);
        
        console.log(`\n📊 Story Points:`);
        console.log(`   Con puntos: ${withPoints.length}`);
        console.log(`   Sin puntos: ${withoutPoints.length}`);

        if (withPoints.length > 0) {
            const totalPoints = issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
            console.log(`   Total de puntos: ${totalPoints}`);
        }

        // Mostrar algunos issues de ejemplo
        console.log('\n📋 Ejemplos de issues:');
        issues.slice(0, 5).forEach(issue => {
            const assignee = issue.assignee ? issue.assignee.name : 'Sin asignar';
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            console.log(`   ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${assignee} - ${points}`);
        });

        console.log('\n🎉 ¡Verificación completada!');
        console.log('\n💡 Cómo ver los sprints en Linear:');
        console.log('1. Ve a https://linear.app y accede a tu workspace');
        console.log('2. En el menú lateral izquierdo, busca "Issues"');
        console.log('3. Verás todos los issues organizados por estado');
        console.log('4. Puedes filtrar por:');
        console.log('   - Asignado a: fernando rodriguez');
        console.log('   - Estado: Todo, In Progress, Done');
        console.log('   - Etiquetas o proyectos');
        console.log('5. Para organizar por sprints, puedes:');
        console.log('   - Crear etiquetas para cada sprint');
        console.log('   - Usar la vista de "Projects" si está disponible');
        console.log('   - Usar la vista de "Cycles" si está disponible');

    } catch (error) {
        console.error('❌ Error verificando configuración:', error.message);
    }
}

verifyLinearSetup();
