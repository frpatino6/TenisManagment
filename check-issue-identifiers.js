// Script para verificar los identifiers reales de los issues
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

async function checkIssueIdentifiers() {
    try {
        console.log('🔍 Verificando identifiers reales de los issues...\n');

        // Obtener todos los issues
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
                        assignee {
                            name
                        }
                        estimate
                        project {
                            name
                        }
                    }
                }
            }
        `;

        const issuesData = await makeLinearRequest(issuesQuery);
        const issues = issuesData.issues.nodes;
        
        console.log(`✅ Issues encontrados: ${issues.length}\n`);

        // Agrupar por tipo de issue
        const issuesByType = {};
        issues.forEach(issue => {
            const type = issue.identifier.split('-')[0] + '-' + issue.identifier.split('-')[1];
            if (!issuesByType[type]) issuesByType[type] = [];
            issuesByType[type].push(issue);
        });

        console.log('📋 Issues por tipo:');
        Object.keys(issuesByType).sort().forEach(type => {
            console.log(`\n🎯 ${type}:`);
            issuesByType[type].forEach(issue => {
                const assignee = issue.assignee ? issue.assignee.name : 'Sin asignar';
                const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
                const project = issue.project ? issue.project.name : 'Sin project';
                console.log(`   ${issue.identifier}: ${issue.title}`);
                console.log(`      Estado: ${issue.state.name} | Asignado: ${assignee} | ${points} | Project: ${project}`);
            });
        });

        // Mostrar issues sin project
        const issuesWithoutProject = issues.filter(issue => !issue.project);
        console.log(`\n📊 Issues sin project: ${issuesWithoutProject.length}`);
        
        if (issuesWithoutProject.length > 0) {
            console.log('\nIssues sin project:');
            issuesWithoutProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title}`);
            });
        }

        // Mostrar issues con project
        const issuesWithProject = issues.filter(issue => issue.project);
        console.log(`\n📊 Issues con project: ${issuesWithProject.length}`);
        
        if (issuesWithProject.length > 0) {
            console.log('\nIssues con project:');
            issuesWithProject.forEach(issue => {
                console.log(`   - ${issue.identifier}: ${issue.title} → ${issue.project.name}`);
            });
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

checkIssueIdentifiers();
