// Script para corregir el estado de los issues del Sprint 1
const fs = require('fs');

// Leer configuración
const envContent = fs.readFileSync('./linear-config.env', 'utf8');
const apiKey = envContent.match(/LINEAR_API_KEY=(.+)/)?.[1];
const teamId = envContent.match(/LINEAR_TEAM_ID=(.+)/)?.[1];

async function makeLinearRequest(query, variables = {}) {
    try {
        const response = await fetch('https://api.linear.app/graphql', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': apiKey
            },
            body: JSON.stringify({ query, variables })
        });

        const data = await response.json();
        
        if (data.errors) {
            console.error('❌ Linear API Errors:', JSON.stringify(data.errors, null, 2));
            throw new Error('Linear API returned errors');
        }
        
        return data.data;
    } catch (error) {
        console.error('❌ Error making Linear API request:', error.message);
        throw error;
    }
}

async function fixSprint1Status() {
    try {
        console.log('🔧 Corrigiendo estado de los issues del Sprint 1...\n');

        // Issues del Sprint 1
        const sprint1Issues = [
            'TEN-6', 'TEN-7', 'TEN-8', 'TEN-11', 'TEN-12', 'TEN-13'
        ];

        // Obtener estados disponibles
        console.log('📋 Obteniendo estados disponibles...');
        const statesQuery = `
            query {
                workflowStates {
                    nodes {
                        id
                        name
                        type
                        position
                    }
                }
            }
        `;

        const statesData = await makeLinearRequest(statesQuery);
        const states = statesData.workflowStates.nodes;
        
        console.log('✅ Estados disponibles:');
        states.forEach(state => {
            console.log(`   - ${state.name} (${state.type})`);
        });

        // Encontrar el estado "In Progress" correcto
        const inProgressState = states.find(state => 
            state.name === 'In Progress' && state.type === 'started'
        );

        if (!inProgressState) {
            console.log('❌ No se encontró el estado "In Progress"');
            return;
        }

        console.log(`\n🎯 Estado "In Progress" encontrado: ${inProgressState.name} (${inProgressState.type})`);

        // Obtener issues del Sprint 1
        console.log('\n📋 Obteniendo issues del Sprint 1...');
        const issuesQuery = `
            query {
                issues {
                    nodes {
                        id
                        identifier
                        title
                        state {
                            id
                            name
                        }
                        project {
                            name
                        }
                        estimate
                    }
                }
            }
        `;

        const issuesData = await makeLinearRequest(issuesQuery);
        const allIssues = issuesData.issues.nodes;
        
        // Filtrar issues del Sprint 1
        const sprint1IssuesData = allIssues.filter(issue => 
            sprint1Issues.includes(issue.identifier) && 
            issue.project && 
            issue.project.name === 'Multi-Tenancy Backend'
        );

        console.log(`✅ Issues del Sprint 1 encontrados: ${sprint1IssuesData.length}`);
        
        // Mostrar estado actual
        console.log('\n📋 Estado actual de los issues:');
        sprint1IssuesData.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            console.log(`   ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        // Mover issues a "In Progress"
        console.log('\n🔄 Moviendo issues a "In Progress"...');
        let movedCount = 0;

        for (const issue of sprint1IssuesData) {
            // Solo mover si no está ya en "In Progress"
            if (issue.state.name === 'In Progress') {
                console.log(`   ✅ ${issue.identifier}: Ya está en "In Progress"`);
                continue;
            }

            const updateMutation = `
                mutation {
                    issueUpdate(
                        id: "${issue.id}"
                        input: {
                            stateId: "${inProgressState.id}"
                        }
                    ) {
                        success
                        issue {
                            identifier
                            title
                            state {
                                name
                            }
                        }
                    }
                }
            `;

            try {
                const response = await makeLinearRequest(updateMutation);
                
                if (response.issueUpdate.success) {
                    console.log(`   ✅ ${issue.identifier}: Movido a "In Progress"`);
                    movedCount++;
                } else {
                    console.log(`   ❌ Error moviendo ${issue.identifier}`);
                }
            } catch (error) {
                console.log(`   ❌ Error moviendo ${issue.identifier}:`, error.message);
            }
        }

        console.log(`\n🎉 ¡Estado corregido!`);
        console.log(`📊 Issues movidos a "In Progress": ${movedCount}/${sprint1IssuesData.length}`);

        // Verificar estado final
        console.log('\n🔍 Verificando estado final...');
        const finalIssuesData = await makeLinearRequest(issuesQuery);
        const finalSprint1Issues = finalIssuesData.issues.nodes.filter(issue => 
            sprint1Issues.includes(issue.identifier) && 
            issue.project && 
            issue.project.name === 'Multi-Tenancy Backend'
        );

        console.log('\n📋 Estado final de los issues:');
        finalSprint1Issues.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            const status = issue.state.name === 'In Progress' ? '✅' : '❌';
            console.log(`   ${status} ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        const inProgressCount = finalSprint1Issues.filter(issue => issue.state.name === 'In Progress').length;
        console.log(`\n📊 Issues en "In Progress": ${inProgressCount}/${finalSprint1Issues.length}`);

        if (inProgressCount === finalSprint1Issues.length) {
            console.log('\n🎯 ¡Sprint 1 listo para trabajar!');
            console.log('💡 Ahora puedes comenzar a trabajar en los issues del Sprint 1');
        }

    } catch (error) {
        console.error('❌ Error corrigiendo estado:', error.message);
    }
}

fixSprint1Status();
