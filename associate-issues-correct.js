// Script para asociar issues usando los identifiers reales
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

async function associateIssuesCorrectly() {
    try {
        console.log('🔗 Asociando issues a projects usando identifiers correctos...\n');

        // Mapeo correcto basado en los identifiers reales
        const sprintMapping = {
            'Multi-Tenancy Backend': [
                'TEN-6', 'TEN-7', 'TEN-8', 'TEN-11', 'TEN-12', 'TEN-13'
            ],
            'Multi-Tenancy Frontend': [
                'TEN-9'
            ],
            'Tenant Signup & Onboarding': [
                'TEN-26', 'TEN-27'
            ],
            'Subscription & Billing': [
                'TEN-14', 'TEN-15', 'TEN-16'
            ],
            'Plan Management & Limits': [
                'TEN-10'
            ],
            'Super Admin Dashboard': [
                'TEN-28'
            ],
            'Quality & DevOps': [
                'TEN-5'
            ],
            'Go-to-Market': [
                'TEN-31', 'TEN-32'
            ]
        };

        // Obtener projects
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

        // Crear mapa de projects
        const projectsMap = {};
        projects.forEach(project => {
            projectsMap[project.name] = project;
            console.log(`   - ${project.name}`);
        });

        // Obtener issues
        console.log('\n📋 Obteniendo issues...');
        const issuesQuery = `
            query {
                issues {
                    nodes {
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

        const issuesData = await makeLinearRequest(issuesQuery);
        const issues = issuesData.issues.nodes;
        console.log(`✅ Issues encontrados: ${issues.length}`);

        // Crear mapa de issues
        const issuesMap = {};
        issues.forEach(issue => {
            issuesMap[issue.identifier] = issue;
        });

        // Asociar issues a projects
        console.log('\n🔗 Asociando issues a projects...');
        let totalAssociated = 0;

        for (const [projectName, issueIdentifiers] of Object.entries(sprintMapping)) {
            const project = projectsMap[projectName];
            
            if (!project) {
                console.log(`❌ Project no encontrado: ${projectName}`);
                continue;
            }

            console.log(`\n🎯 ${projectName}:`);
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
                        projectAssociated++;
                        totalAssociated++;
                    } else {
                        console.log(`   ❌ Error asociando ${issueIdentifier}`);
                    }
                } catch (error) {
                    console.log(`   ❌ Error asociando ${issueIdentifier}:`, error.message);
                }
            }

            console.log(`   📊 Asociados: ${projectAssociated}/${issueIdentifiers.length}`);
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

        console.log('\n💡 Ahora puedes:');
        console.log('1. Ir a Linear y ver cualquier project');
        console.log('2. Hacer clic en la pestaña "Issues"');
        console.log('3. Ver todos los issues asociados a ese sprint');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

associateIssuesCorrectly();
