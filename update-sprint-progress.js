// Script para actualizar el progreso del Sprint 1 en Linear
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

async function updateSprintProgress() {
    try {
        console.log('📊 Actualizando progreso del Sprint 1...\n');

        // Issues del Sprint 1 (únicos)
        const sprint1Issues = ['TEN-6', 'TEN-7', 'TEN-8'];

        // Obtener issues del Sprint 1
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
                        description
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
        console.log('\n📋 Estado actual del Sprint 1:');
        sprint1IssuesData.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            const status = issue.state.name === 'Done' ? '✅' : 
                          issue.state.name === 'In Progress' ? '🔄' : '⏳';
            console.log(`   ${status} ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        // Calcular progreso
        const totalPoints = sprint1IssuesData.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        const completedIssues = sprint1IssuesData.filter(issue => issue.state.name === 'Done');
        const completedPoints = completedIssues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        const progressPercentage = totalPoints > 0 ? Math.round((completedPoints / totalPoints) * 100) : 0;

        console.log('\n📊 Progreso del Sprint:');
        console.log(`   📋 Issues completados: ${completedIssues.length}/${sprint1IssuesData.length}`);
        console.log(`   📊 Story points completados: ${completedPoints}/${totalPoints}`);
        console.log(`   📈 Progreso: ${progressPercentage}%`);

        // Crear burndown chart simple
        console.log('\n📈 Burndown Chart:');
        const barLength = 20;
        const filledLength = Math.round((progressPercentage / 100) * barLength);
        const bar = '█'.repeat(filledLength) + '░'.repeat(barLength - filledLength);
        console.log(`   [${bar}] ${progressPercentage}%`);

        // Mostrar próximos pasos
        const inProgressIssues = sprint1IssuesData.filter(issue => issue.state.name === 'In Progress');
        const todoIssues = sprint1IssuesData.filter(issue => issue.state.name === 'Todo' || issue.state.name === 'Backlog');

        if (inProgressIssues.length > 0) {
            console.log('\n🔄 Issues en progreso:');
            inProgressIssues.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        if (todoIssues.length > 0) {
            console.log('\n⏳ Issues pendientes:');
            todoIssues.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        // Función para mover issue a Done
        async function moveIssueToDone(issueIdentifier) {
            const issue = sprint1IssuesData.find(i => i.identifier === issueIdentifier);
            if (!issue) {
                console.log(`❌ Issue ${issueIdentifier} no encontrado`);
                return false;
            }

            // Obtener estado "Done"
            const statesQuery = `
                query {
                    workflowStates {
                        nodes {
                            id
                            name
                            type
                        }
                    }
                }
            `;

            const statesData = await makeLinearRequest(statesQuery);
            const doneState = statesData.workflowStates.nodes.find(state => 
                state.name === 'Done' && state.type === 'completed'
            );

            if (!doneState) {
                console.log('❌ Estado "Done" no encontrado');
                return false;
            }

            const updateMutation = `
                mutation {
                    issueUpdate(
                        id: "${issue.id}"
                        input: {
                            stateId: "${doneState.id}"
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
                    console.log(`✅ ${issueIdentifier}: Movido a "Done"`);
                    return true;
                } else {
                    console.log(`❌ Error moviendo ${issueIdentifier}`);
                    return false;
                }
            } catch (error) {
                console.log(`❌ Error moviendo ${issueIdentifier}:`, error.message);
                return false;
            }
        }

        // Función para agregar comentario de progreso
        async function addProgressComment(issueIdentifier, comment) {
            const issue = sprint1IssuesData.find(i => i.identifier === issueIdentifier);
            if (!issue) {
                console.log(`❌ Issue ${issueIdentifier} no encontrado`);
                return false;
            }

            const commentMutation = `
                mutation {
                    commentCreate(
                        input: {
                            issueId: "${issue.id}"
                            body: "${comment}"
                        }
                    ) {
                        success
                        comment {
                            id
                            body
                        }
                    }
                }
            `;

            try {
                const response = await makeLinearRequest(commentMutation);
                if (response.commentCreate.success) {
                    console.log(`✅ Comentario agregado a ${issueIdentifier}`);
                    return true;
                } else {
                    console.log(`❌ Error agregando comentario a ${issueIdentifier}`);
                    return false;
                }
            } catch (error) {
                console.log(`❌ Error agregando comentario a ${issueIdentifier}:`, error.message);
                return false;
            }
        }

        console.log('\n💡 Comandos disponibles:');
        console.log('   - Para mover un issue a "Done": node update-sprint-progress.js done TEN-6');
        console.log('   - Para agregar comentario: node update-sprint-progress.js comment TEN-6 "Progreso actualizado"');

        // Procesar argumentos de línea de comandos
        const args = process.argv.slice(2);
        if (args.length >= 2) {
            const command = args[0];
            const issueId = args[1];

            if (command === 'done') {
                console.log(`\n🔄 Moviendo ${issueId} a "Done"...`);
                await moveIssueToDone(issueId);
            } else if (command === 'comment' && args.length >= 3) {
                const comment = args.slice(2).join(' ');
                console.log(`\n💬 Agregando comentario a ${issueId}...`);
                await addProgressComment(issueId, comment);
            }
        }

    } catch (error) {
        console.error('❌ Error actualizando progreso:', error.message);
    }
}

updateSprintProgress();
