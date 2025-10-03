const { getLinearConfig, makeLinearRequest } = require('./linear-utils');

async function fixProjectAssociations() {
    try {
        const { teamId } = getLinearConfig();
        console.log('🔧 Solucionando asociaciones de issues a projects...\n');

        // Primero, vamos a verificar qué issues tenemos
        console.log('📋 Verificando issues existentes...');
        
        // Query simple para obtener issues
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

        // Mostrar issues sin project
        const issuesWithoutProject = issues.filter(issue => !issue.project);
        const issuesWithProject = issues.filter(issue => issue.project);

        console.log(`📊 Issues con project: ${issuesWithProject.length}`);
        console.log(`📊 Issues sin project: ${issuesWithoutProject.length}`);

        if (issuesWithoutProject.length > 0) {
            console.log('\n📋 Issues sin project:');
            issuesWithoutProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        if (issuesWithProject.length > 0) {
            console.log('\n📋 Issues con project:');
            issuesWithProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title} → ${issue.project.name}`);
            });
        }

        // Ahora vamos a obtener los projects
        console.log('\n📋 Verificando projects existentes...');
        
        const projectsQuery = `
            query {
                projects(first: 20) {
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
        projects.forEach(project => {
            console.log(`   - ${project.name} (${project.id})`);
        });

        // Si hay issues sin project, vamos a asociarlos manualmente
        if (issuesWithoutProject.length > 0 && projects.length > 0) {
            console.log('\n🔗 Asociando issues a projects...');
            
            // Mapeo manual basado en los nombres de los issues
            const projectMapping = {
                'Multi-Tenancy Backend': ['US-MT-001', 'US-MT-002', 'US-MT-003'],
                'Multi-Tenancy Frontend': ['US-MT-004', 'US-MT-005', 'US-MT-006'],
                'Tenant Signup & Onboarding': ['US-ONB-001', 'US-ONB-002'],
                'Subscription & Billing': ['US-BILL-001', 'US-BILL-003', 'US-BILL-004'],
                'Plan Management & Limits': ['US-PLAN-001', 'US-PLAN-002', 'US-PLAN-003'],
                'Super Admin Dashboard': ['US-ADMIN-001'],
                'Quality & DevOps': ['US-QA-001', 'US-QA-002', 'US-QA-003'],
                'Go-to-Market': ['US-GTM-001', 'US-GTM-002']
            };

            let associated = 0;
            for (const [projectName, issueIdentifiers] of Object.entries(projectMapping)) {
                const project = projects.find(p => p.name === projectName);
                if (!project) {
                    console.log(`❌ Project no encontrado: ${projectName}`);
                    continue;
                }

                console.log(`\n🎯 Asociando issues a: ${projectName}`);
                
                for (const issueIdentifier of issueIdentifiers) {
                    const issue = issuesWithoutProject.find(i => i.identifier === issueIdentifier);
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
                                    identifier
                                    title
                                }
                            }
                        }
                    `;

                    try {
                        const response = await makeLinearRequest(associateMutation);
                        if (response.issueUpdate.success) {
                            console.log(`   ✅ ${issueIdentifier}: ${issue.title}`);
                            associated++;
                        } else {
                            console.log(`   ❌ Error asociando ${issueIdentifier}`);
                        }
                    } catch (error) {
                        console.log(`   ❌ Error asociando ${issueIdentifier}:`, error.message);
                    }
                }
            }

            console.log(`\n🎉 ¡Asociación completada!`);
            console.log(`📊 Issues asociados: ${associated}`);
        }

        console.log('\n💡 Instrucciones para ver los issues en Linear:');
        console.log('1. Ve a la vista principal de "Projects"');
        console.log('2. Haz clic en cualquier project (ej: "Multi-Tenancy Backend")');
        console.log('3. Haz clic en la pestaña "Issues"');
        console.log('4. Ahora deberías ver los issues asociados a ese sprint');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

fixProjectAssociations();
