// Script para iniciar el Sprint 1 - Multi-Tenancy Foundation
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

async function startSprint1() {
    try {
        console.log('🚀 Iniciando Sprint 1 - Multi-Tenancy Foundation...\n');

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

        // Encontrar el estado "In Progress"
        const inProgressState = states.find(state => 
            state.name.toLowerCase().includes('progress') || 
            state.name.toLowerCase().includes('doing') ||
            state.type === 'started'
        );

        if (!inProgressState) {
            console.log('❌ No se encontró el estado "In Progress"');
            return;
        }

        console.log(`\n🎯 Estado "In Progress" encontrado: ${inProgressState.name}`);

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
        
        // Mostrar issues actuales
        console.log('\n📋 Issues del Sprint 1:');
        sprint1IssuesData.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            console.log(`   ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        // Calcular total de story points
        const totalPoints = sprint1IssuesData.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        console.log(`\n📊 Total de story points: ${totalPoints}`);

        // Mover issues a "In Progress"
        console.log('\n🔄 Moviendo issues a "In Progress"...');
        let movedCount = 0;

        for (const issue of sprint1IssuesData) {
            // Solo mover si no está ya en progreso
            if (issue.state.name.toLowerCase().includes('progress') || 
                issue.state.name.toLowerCase().includes('doing')) {
                console.log(`   ✅ ${issue.identifier}: Ya está en progreso`);
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
                    console.log(`   ✅ ${issue.identifier}: Movido a ${inProgressState.name}`);
                    movedCount++;
                } else {
                    console.log(`   ❌ Error moviendo ${issue.identifier}`);
                }
            } catch (error) {
                console.log(`   ❌ Error moviendo ${issue.identifier}:`, error.message);
            }
        }

        console.log(`\n🎉 ¡Sprint 1 iniciado!`);
        console.log(`📊 Issues movidos a "In Progress": ${movedCount}/${sprint1IssuesData.length}`);

        // Configurar fechas del sprint
        console.log('\n📅 Configurando fechas del sprint...');
        
        const today = new Date();
        const sprintEnd = new Date(today);
        sprintEnd.setDate(today.getDate() + 14); // 2 semanas

        console.log(`📅 Fecha de inicio: ${today.toLocaleDateString()}`);
        console.log(`📅 Fecha de fin: ${sprintEnd.toLocaleDateString()}`);
        console.log(`⏱️ Duración: 2 semanas`);

        // Actualizar project con fechas
        const projectQuery = `
            query {
                projects {
                    nodes {
                        id
                        name
                    }
                }
            }
        `;

        const projectData = await makeLinearRequest(projectQuery);
        const multiTenancyProject = projectData.projects.nodes.find(p => p.name === 'Multi-Tenancy Backend');

        if (multiTenancyProject) {
            const updateProjectMutation = `
                mutation {
                    projectUpdate(
                        id: "${multiTenancyProject.id}"
                        input: {
                            startDate: "${today.toISOString().split('T')[0]}"
                            targetDate: "${sprintEnd.toISOString().split('T')[0]}"
                        }
                    ) {
                        success
                        project {
                            name
                            startDate
                            targetDate
                        }
                    }
                }
            `;

            try {
                const response = await makeLinearRequest(updateProjectMutation);
                if (response.projectUpdate.success) {
                    console.log(`✅ Project actualizado con fechas del sprint`);
                } else {
                    console.log(`❌ Error actualizando fechas del project`);
                }
            } catch (error) {
                console.log(`❌ Error actualizando project:`, error.message);
            }
        }

        console.log('\n🎯 Sprint 1 - Multi-Tenancy Foundation INICIADO');
        console.log('════════════════════════════════════════════════════════════════════════════════');
        console.log('📝 Objetivo: Implementar la base de multi-tenancy para permitir múltiples clubes');
        console.log(`📊 Story Points: ${totalPoints}`);
        console.log(`⏱️ Duración: 2 semanas (${today.toLocaleDateString()} - ${sprintEnd.toLocaleDateString()})`);
        console.log(`👥 Asignado a: fernando rodriguez`);
        console.log('════════════════════════════════════════════════════════════════════════════════');

        console.log('\n💡 Próximos pasos:');
        console.log('1. Ve a Linear y verifica que los issues estén en "In Progress"');
        console.log('2. Comienza trabajando en TEN-6: US-MT-001: Crear Modelo de Tenant');
        console.log('3. Mueve issues a "Done" cuando los completes');
        console.log('4. Actualiza el progreso diariamente');

    } catch (error) {
        console.error('❌ Error iniciando sprint:', error.message);
    }
}

startSprint1();
