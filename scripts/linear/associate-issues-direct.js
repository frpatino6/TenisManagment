const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function associateIssuesDirectly() {
    try {
        const { apiKey, teamId } = getLinearConfig();

        console.log('🔗 Asociando issues a projects usando API directa...\n');

        // Mapeo de issues a projects
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
            console.log(`   - ${project.name} (${project.id})`);
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
                        project {
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

        // Mostrar issues sin project
        const issuesWithoutProject = issues.filter(issue => !issue.project);
        console.log(`\n📊 Issues sin project: ${issuesWithoutProject.length}`);
        
        if (issuesWithoutProject.length > 0) {
            console.log('Issues sin project:');
            issuesWithoutProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        // Asociar issues a projects
        console.log('\n🔗 Asociando issues a projects...');
        let totalAssociated = 0;

        for (const [projectName, issueIdentifiers] of Object.entries(sprintMapping)) {
            const project = projectsMap[projectName];
            
            if (!project) {
                console.log(`❌ Project no encontrado: ${projectName}`);
                continue;
            }

            console.log(`\n🎯 Asociando issues a: ${projectName}`);
            let projectAssociated = 0;

            for (const issueIdentifier of issueIdentifiers) {
                const issue = issuesMap[issueIdentifier];
                
                if (!issue) {
                    console.log(`   ⚠️ Issue no encontrado: ${issueIdentifier}`);
                    continue;
                }

                // Si ya está asociado, saltarlo
                if (issue.project && issue.project.name === projectName) {
                    console.log(`   ✅ ${issueIdentifier}: Ya asociado`);
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

        // Verificar asociaciones finales
        console.log('\n🔍 Verificando asociaciones finales...');
        const finalIssuesData = await makeLinearRequest(issuesQuery);
        const finalIssues = finalIssuesData.issues.nodes;

        const finalIssuesWithProject = finalIssues.filter(issue => issue.project);
        const finalIssuesWithoutProject = finalIssues.filter(issue => !issue.project);

        console.log(`📊 Issues con project: ${finalIssuesWithProject.length}`);
        console.log(`📊 Issues sin project: ${finalIssuesWithoutProject.length}`);

        if (finalIssuesWithProject.length > 0) {
            console.log('\n✅ Issues asociados correctamente:');
            finalIssuesWithProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title} → ${issue.project.name}`);
            });
        }

        if (finalIssuesWithoutProject.length > 0) {
            console.log('\n⚠️ Issues sin project:');
            finalIssuesWithoutProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        console.log('\n💡 Ahora puedes:');
        console.log('1. Ir a Linear y ver cualquier project');
        console.log('2. Hacer clic en la pestaña "Issues"');
        console.log('3. Ver todos los issues asociados a ese sprint');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

associateIssuesDirectly();
