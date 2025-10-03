// Script simple para asociar issues a projects usando fetch nativo
const fs = require('fs');

// Leer configuración
const envContent = fs.readFileSync('./linear-config.env', 'utf8');
const apiKey = envContent.match(/LINEAR_API_KEY=(.+)/)?.[1];
const teamId = envContent.match(/LINEAR_TEAM_ID=(.+)/)?.[1];

if (!apiKey || !teamId) {
    console.error('❌ LINEAR_API_KEY y LINEAR_TEAM_ID deben estar configurados en linear-config.env');
    process.exit(1);
}

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

async function associateIssues() {
    try {
        console.log('🔗 Asociando issues a projects...\n');

        // Mapeo de issues a projects
        const sprintMapping = {
            'Multi-Tenancy Backend': ['US-MT-001', 'US-MT-002', 'US-MT-003'],
            'Multi-Tenancy Frontend': ['US-MT-004', 'US-MT-005', 'US-MT-006'],
            'Tenant Signup & Onboarding': ['US-ONB-001', 'US-ONB-002'],
            'Subscription & Billing': ['US-BILL-001', 'US-BILL-003', 'US-BILL-004'],
            'Plan Management & Limits': ['US-PLAN-001', 'US-PLAN-002', 'US-PLAN-003'],
            'Super Admin Dashboard': ['US-ADMIN-001'],
            'Quality & DevOps': ['US-QA-001', 'US-QA-002', 'US-QA-003'],
            'Go-to-Market': ['US-GTM-001', 'US-GTM-002']
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

        // Mostrar issues sin project
        const issuesWithoutProject = issues.filter(issue => !issue.project);
        console.log(`\n📊 Issues sin project: ${issuesWithoutProject.length}`);

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

        console.log('\n💡 Ahora puedes:');
        console.log('1. Ir a Linear y ver cualquier project');
        console.log('2. Hacer clic en la pestaña "Issues"');
        console.log('3. Ver todos los issues asociados a ese sprint');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

associateIssues();
