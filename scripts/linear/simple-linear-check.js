const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function simpleCheck() {
    try {
        const { teamId } = getLinearConfig();
        console.log('🔍 Verificando funcionalidades básicas de Linear...\n');

        // Query simple para verificar conexión
        const basicQuery = `
            query {
                viewer {
                    id
                    name
                }
                team(id: "${teamId}") {
                    id
                    name
                    key
                }
            }
        `;

        const data = await makeLinearRequest(basicQuery);
        console.log('✅ Conexión exitosa a Linear');
        console.log('👤 Usuario:', data.viewer.name);
        console.log('🏢 Equipo:', data.team.name, `(${data.team.key})`);

        // Verificar milestones
        console.log('\n🔍 Verificando milestones...');
        const milestonesQuery = `
            query {
                milestones {
                    nodes {
                        id
                        name
                    }
                }
            }
        `;

        try {
            const milestonesData = await makeLinearRequest(milestonesQuery);
            if (milestonesData.milestones && milestonesData.milestones.nodes) {
                console.log(`✅ Milestones disponibles: ${milestonesData.milestones.nodes.length}`);
                if (milestonesData.milestones.nodes.length > 0) {
                    milestonesData.milestones.nodes.forEach(milestone => {
                        console.log(`   - ${milestone.name}`);
                    });
                } else {
                    console.log('   No hay milestones creados aún');
                }
            } else {
                console.log('❌ Milestones no disponibles en este workspace');
            }
        } catch (error) {
            console.log('❌ Error verificando milestones:', error.message);
        }

        // Verificar projects
        console.log('\n🔍 Verificando projects...');
        const projectsQuery = `
            query {
                projects {
                    nodes {
                        id
                        name
                        state
                    }
                }
            }
        `;

        try {
            const projectsData = await makeLinearRequest(projectsQuery);
            if (projectsData.projects && projectsData.projects.nodes) {
                console.log(`✅ Projects disponibles: ${projectsData.projects.nodes.length}`);
                if (projectsData.projects.nodes.length > 0) {
                    projectsData.projects.nodes.forEach(project => {
                        console.log(`   - ${project.name} (${project.state})`);
                    });
                } else {
                    console.log('   No hay projects creados aún');
                }
            } else {
                console.log('❌ Projects no disponibles en este workspace');
            }
        } catch (error) {
            console.log('❌ Error verificando projects:', error.message);
        }

        // Verificar issues
        console.log('\n🔍 Verificando issues...');
        const issuesQuery = `
            query {
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
        `;

        try {
            const issuesData = await makeLinearRequest(issuesQuery);
            if (issuesData.issues && issuesData.issues.nodes) {
                console.log(`✅ Issues encontrados: ${issuesData.issues.nodes.length}`);
                const completed = issuesData.issues.nodes.filter(issue => issue.state.name === 'Done').length;
                const inProgress = issuesData.issues.nodes.filter(issue => issue.state.name === 'In Progress').length;
                const todo = issuesData.issues.nodes.filter(issue => issue.state.name === 'Todo').length;
                
                console.log(`   - Completados: ${completed}`);
                console.log(`   - En progreso: ${inProgress}`);
                console.log(`   - Por hacer: ${todo}`);
            }
        } catch (error) {
            console.log('❌ Error verificando issues:', error.message);
        }

    } catch (error) {
        console.error('❌ Error general:', error.message);
    }
}

simpleCheck();
