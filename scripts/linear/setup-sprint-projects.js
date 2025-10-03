const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function setupSprintProjects() {
    try {
        const { teamId } = getLinearConfig();
        console.log('🎯 Configurando projects para organizar sprints...\n');

        // Definir los sprints como projects
        const sprints = [
            {
                name: 'Sprint 1 - Multi-Tenancy Foundation',
                description: 'Base de multi-tenancy para el sistema. Implementar la base de multi-tenancy para permitir múltiples clubes.',
                color: '#FF6B6B',
                issues: ['US-MT-001', 'US-MT-002', 'US-MT-003']
            },
            {
                name: 'Sprint 2 - Authentication & Authorization',
                description: 'Sistema de autenticación y autorización. Implementar login seguro y sistema de roles.',
                color: '#4ECDC4',
                issues: ['US-AUTH-001', 'US-AUTH-002', 'US-AUTH-003']
            },
            {
                name: 'Sprint 3 - Onboarding & Signup',
                description: 'Flujo de registro y onboarding. Crear experiencia de onboarding fluida para nuevos clubes.',
                color: '#45B7D1',
                issues: ['US-ONB-001', 'US-ONB-002']
            },
            {
                name: 'Sprint 6 - Subscription & Billing',
                description: 'Sistema de suscripciones y facturación. Implementar monetización con Stripe.',
                color: '#96CEB4',
                issues: ['US-BILL-001', 'US-BILL-003', 'US-BILL-004']
            },
            {
                name: 'Sprint 8 - Admin Dashboard',
                description: 'Dashboard administrativo. Dashboard para super administradores.',
                color: '#FFEAA7',
                issues: ['US-ADMIN-001']
            },
            {
                name: 'Sprint 9 - Analytics & Reporting',
                description: 'Analytics y reportes. Sistema completo de analytics y reportes.',
                color: '#DDA0DD',
                issues: ['US-ANALYTICS-001']
            },
            {
                name: 'Sprint 10 - Mobile Features',
                description: 'Funcionalidades móviles. Optimizaciones y funcionalidades específicas para móvil.',
                color: '#98D8C8',
                issues: ['US-MOBILE-001']
            },
            {
                name: 'Sprint 11 - Go-to-Market',
                description: 'Preparación para lanzamiento. Preparar todo para el lanzamiento público.',
                color: '#F7DC6F',
                issues: ['US-GTM-001', 'US-GTM-002']
            }
        ];

        // Primero, obtener todos los issues existentes
        const issuesQuery = `
            query {
                issues {
                    nodes {
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

        const issuesData = await makeLinearRequest(issuesQuery);
        const issues = issuesData.issues.nodes;
        console.log(`📋 Issues encontrados: ${issues.length}`);

        // Crear un mapa de issues por identifier
        const issuesMap = {};
        issues.forEach(issue => {
            issuesMap[issue.identifier] = issue;
        });

        // Crear projects para cada sprint
        for (const sprint of sprints) {
            console.log(`\n🎯 Creando project: ${sprint.name}`);

            // Crear el project
            const createProjectMutation = `
                mutation {
                    projectCreate(
                        input: {
                            name: "${sprint.name}"
                            description: "${sprint.description}"
                            color: "${sprint.color}"
                            teamId: "${teamId}"
                            state: "planned"
                        }
                    ) {
                        success
                        project {
                            id
                            name
                            description
                            color
                            state
                        }
                    }
                }
            `;

            try {
                const projectResponse = await makeLinearRequest(createProjectMutation);
                
                if (projectResponse.projectCreate.success) {
                    const project = projectResponse.projectCreate.project;
                    console.log(`✅ Project creado: ${project.name} (${project.id})`);

                    // Asignar issues al project
                    let assignedIssues = 0;
                    for (const issueIdentifier of sprint.issues) {
                        if (issuesMap[issueIdentifier]) {
                            const issue = issuesMap[issueIdentifier];
                            
                            const updateIssueMutation = `
                                mutation {
                                    issueUpdate(
                                        id: "${issue.id}"
                                        input: {
                                            projectId: "${project.id}"
                                        }
                                    ) {
                                        success
                                        issue {
                                            id
                                            identifier
                                            title
                                        }
                                    }
                                }
                            `;

                            try {
                                const updateResponse = await makeLinearRequest(updateIssueMutation);
                                if (updateResponse.issueUpdate.success) {
                                    assignedIssues++;
                                    console.log(`   ✅ Issue asignado: ${issue.identifier} - ${issue.title}`);
                                } else {
                                    console.log(`   ❌ Error asignando issue: ${issue.identifier}`);
                                }
                            } catch (error) {
                                console.log(`   ❌ Error asignando issue ${issue.identifier}:`, error.message);
                            }
                        } else {
                            console.log(`   ⚠️ Issue no encontrado: ${issueIdentifier}`);
                        }
                    }

                    console.log(`   📊 Issues asignados: ${assignedIssues}/${sprint.issues.length}`);
                } else {
                    console.log(`❌ Error creando project: ${sprint.name}`);
                }
            } catch (error) {
                console.log(`❌ Error creando project ${sprint.name}:`, error.message);
            }
        }

        // Verificar projects creados
        console.log('\n🔍 Verificando projects creados...');
        const projectsQuery = `
            query {
                projects {
                    nodes {
                        id
                        name
                        description
                        color
                        state
                        progress
                        issues {
                            nodes {
                                id
                                identifier
                                title
                                state {
                                    name
                                }
                            }
                        }
                    }
                }
            }
        `;

        const projectsData = await makeLinearRequest(projectsQuery);
        const projects = projectsData.projects.nodes;

        console.log(`\n📊 Projects creados: ${projects.length}`);
        projects.forEach(project => {
            const totalIssues = project.issues.nodes.length;
            const completedIssues = project.issues.nodes.filter(issue => issue.state.name === 'Done').length;
            const progress = totalIssues > 0 ? Math.round((completedIssues / totalIssues) * 100) : 0;
            
            console.log(`\n🎯 ${project.name}`);
            console.log(`   📊 Progreso: ${progress}% (${completedIssues}/${totalIssues} issues)`);
            console.log(`   🎨 Color: ${project.color}`);
            console.log(`   📝 Estado: ${project.state}`);
            
            if (project.issues.nodes.length > 0) {
                console.log(`   📋 Issues:`);
                project.issues.nodes.forEach(issue => {
                    console.log(`      - ${issue.identifier}: ${issue.title} (${issue.state.name})`);
                });
            }
        });

        console.log('\n🎉 ¡Configuración de projects completada!');
        console.log('\n💡 Cómo ver los sprints en Linear:');
        console.log('1. Ve a tu workspace de Linear');
        console.log('2. En el menú lateral, busca "Projects"');
        console.log('3. Verás todos los sprints organizados como projects');
        console.log('4. Cada project muestra el progreso y los issues asignados');
        console.log('5. Puedes hacer clic en cada project para ver detalles');

    } catch (error) {
        console.error('❌ Error configurando projects:', error.message);
    }
}

setupSprintProjects();
