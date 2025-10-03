const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function checkLinearFeatures() {
    const { apiKey, teamId } = getLinearConfig();

    console.log('🔍 Verificando funcionalidades disponibles en Linear...\n');

    // Query para verificar qué funcionalidades están disponibles
    const query = `
        query {
            viewer {
                id
                name
                email
            }
            team(id: "${teamId}") {
                id
                name
                key
                settings {
                    issueOrdering
                    issueEstimationType
                    issueEstimationAllowZero
                }
            }
            # Verificar si milestones están disponibles
            milestones {
                nodes {
                    id
                    name
                    description
                    targetDate
                    createdAt
                }
            }
            # Verificar si projects están disponibles
            projects {
                nodes {
                    id
                    name
                    description
                    state
                    progress
                }
            }
            # Verificar si cycles están disponibles
            cycles {
                nodes {
                    id
                    number
                    name
                    description
                    startsAt
                    endsAt
                    completedAt
                }
            }
        }
    `;

    try {
        const data = await makeLinearRequest(query);
        
        console.log('👤 Usuario:', data.viewer.name, `(${data.viewer.email})`);
        console.log('🏢 Equipo:', data.team.name, `(${data.team.key})`);
        console.log('⚙️ Configuración del equipo:');
        console.log('   - Orden de issues:', data.team.settings.issueOrdering);
        console.log('   - Tipo de estimación:', data.team.settings.issueEstimationType);
        console.log('   - Permite estimación cero:', data.team.settings.issueEstimationAllowZero);
        
        console.log('\n📊 Funcionalidades disponibles:');
        
        // Verificar milestones
        if (data.milestones && data.milestones.nodes) {
            console.log(`✅ Milestones: ${data.milestones.nodes.length} encontrados`);
            if (data.milestones.nodes.length > 0) {
                console.log('   Milestones existentes:');
                data.milestones.nodes.forEach(milestone => {
                    console.log(`   - ${milestone.name} (${milestone.id})`);
                });
            }
        } else {
            console.log('❌ Milestones: No disponibles o no configurados');
        }
        
        // Verificar projects
        if (data.projects && data.projects.nodes) {
            console.log(`✅ Projects: ${data.projects.nodes.length} encontrados`);
            if (data.projects.nodes.length > 0) {
                console.log('   Projects existentes:');
                data.projects.nodes.forEach(project => {
                    console.log(`   - ${project.name} (${project.state})`);
                });
            }
        } else {
            console.log('❌ Projects: No disponibles o no configurados');
        }
        
        // Verificar cycles
        if (data.cycles && data.cycles.nodes) {
            console.log(`✅ Cycles: ${data.cycles.nodes.length} encontrados`);
            if (data.cycles.nodes.length > 0) {
                console.log('   Cycles existentes:');
                data.cycles.nodes.forEach(cycle => {
                    console.log(`   - ${cycle.name || `Cycle ${cycle.number}`} (${cycle.id})`);
                });
            }
        } else {
            console.log('❌ Cycles: No disponibles o no configurados');
        }

        console.log('\n💡 Recomendaciones:');
        if (!data.milestones || !data.milestones.nodes) {
            console.log('   - Los milestones no están disponibles. Usa Projects o Cycles para organizar sprints.');
        }
        if (!data.projects || !data.projects.nodes) {
            console.log('   - Los projects no están disponibles. Usa Cycles para organizar sprints.');
        }
        if (!data.cycles || !data.cycles.nodes) {
            console.log('   - Los cycles no están disponibles. Usa Projects para organizar sprints.');
        }

    } catch (error) {
        console.error('❌ Error verificando funcionalidades:', error.message);
        if (error.response) {
            console.error('Status Code:', error.response.status);
            console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
        }
    }
}

checkLinearFeatures();
