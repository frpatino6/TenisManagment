const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function associateIssuesToProjects() {
    try {
        const { teamId } = getLinearConfig();
        console.log('🔗 Asociando issues a projects...\n');

        // Mapeo de issues a projects basado en el backlog
        const sprintMapping = {
            'Multi-Tenancy Backend': [
                'US-MT-001', 'US-MT-002', 'US-MT-003'
            ],
            'Multi-Tenancy Frontend': [
                'US-MT-004', 'US-MT-005', 'US-MT-006'
            ],
            'Tenant Signup & Onboarding': [
                'US-ONB-001', 'US-ONB-002'
            ],
            'Subscription & Billing': [
                'US-BILL-001', 'US-BILL-003', 'US-BILL-004'
            ],
            'Plan Management & Limits': [
                'US-PLAN-001', 'US-PLAN-002', 'US-PLAN-003'
            ],
            'Super Admin Dashboard': [
                'US-ADMIN-001'
            ],
            'Quality & DevOps': [
                'US-QA-001', 'US-QA-002', 'US-QA-003'
            ],
            'Go-to-Market': [
                'US-GTM-001', 'US-GTM-002'
            ]
        };

        // Obtener todos los projects
        console.log('📋 Obteniendo projects...');
        const projectsQuery = `
            query {
                projects {
                    nodes {
                        id
                        name
                    }
                }
            }
        `;

        const projectsData = await makeLinearRequest(projectsQuery);
        const projects = projectsData.projects.nodes;
        console.log(`✅ Projects encontrados: ${projects.length}`);

        // Crear mapa de projects por nombre
        const projectsMap = {};
        projects.forEach(project => {
            projectsMap[project.name] = project;
        });

        // Obtener todos los issues
        console.log('\n📋 Obteniendo issues...');
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
        console.log(`✅ Issues encontrados: ${issues.length}`);

        // Crear mapa de issues por identifier
        const issuesMap = {};
        issues.forEach(issue => {
            issuesMap[issue.identifier] = issue;
        });

        // Asociar issues a projects
        let totalAssociated = 0;
        for (const [projectName, issueIdentifiers] of Object.entries(sprintMapping)) {
            const project = projectsMap[projectName];
            
            if (!project) {
                console.log(`❌ Project no encontrado: ${projectName}`);
                continue;
            }

            console.log(`\n🎯 Asociando issues al project: ${projectName}`);
            let projectAssociated = 0;

            for (const issueIdentifier of issueIdentifiers) {
                const issue = issuesMap[issueIdentifier];
                
                if (!issue) {
                    console.log(`   ⚠️ Issue no encontrado: ${issueIdentifier}`);
                    continue;
                }

                // Asociar issue al project
                const associateMutation = `
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
                                project {
                                    name
                                }
                            }
                        }
                    }
                `;

                try {
                    const response = await makeLinearRequest(associateMutation);
                    
                    if (response.issueUpdate.success) {
                        console.log(`   ✅ ${issueIdentifier}: ${issue.title}`);
                        projectAssociated++;
                        totalAssociated++;
                    } else {
                        console.log(`   ❌ Error asociando ${issueIdentifier}`);
                    }
                } catch (error) {
                    console.log(`   ❌ Error asociando ${issueIdentifier}:`, error.message);
                }
            }

            console.log(`   📊 Issues asociados: ${projectAssociated}/${issueIdentifiers.length}`);
        }

        console.log(`\n🎉 ¡Asociación completada!`);
        console.log(`📊 Total de issues asociados: ${totalAssociated}`);

        // Verificar asociaciones
        console.log('\n🔍 Verificando asociaciones...');
        const verificationQuery = `
            query {
                projects {
                    nodes {
                        id
                        name
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

        const verificationData = await makeLinearRequest(verificationQuery);
        const projectsWithIssues = verificationData.projects.nodes;

        projectsWithIssues.forEach(project => {
            if (project.issues.nodes.length > 0) {
                console.log(`\n🎯 ${project.name}: ${project.issues.nodes.length} issues`);
                project.issues.nodes.forEach(issue => {
                    console.log(`   - ${issue.identifier}: ${issue.title} (${issue.state.name})`);
                });
            }
        });

        console.log('\n💡 Ahora puedes:');
        console.log('1. Ir a cualquier project en Linear');
        console.log('2. Hacer clic en la pestaña "Issues"');
        console.log('3. Ver todos los issues asociados a ese sprint');

    } catch (error) {
        console.error('❌ Error asociando issues:', error.message);
    }
}

associateIssuesToProjects();
