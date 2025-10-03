// Script para eliminar issues duplicados del Sprint 1
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

async function removeDuplicatesSprint1() {
    try {
        console.log('🗑️ Eliminando issues duplicados del Sprint 1...\n');

        // Issues duplicados a eliminar (mantener los primeros: TEN-6, TEN-7, TEN-8)
        const duplicateIssues = [
            'TEN-11', // Duplicado de TEN-6
            'TEN-12', // Duplicado de TEN-7
            'TEN-13'  // Duplicado de TEN-8
        ];

        // Issues únicos a mantener
        const uniqueIssues = [
            'TEN-6', // US-MT-001: Crear Modelo de Tenant
            'TEN-7', // US-MT-002: Implementar TenantService
            'TEN-8'  // US-MT-003: Middleware de Extracción de Tenant
        ];

        console.log('📋 Issues únicos a mantener:');
        uniqueIssues.forEach(issue => {
            console.log(`   ✅ ${issue}`);
        });

        console.log('\n📋 Issues duplicados a eliminar:');
        duplicateIssues.forEach(issue => {
            console.log(`   ❌ ${issue}`);
        });

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
        
        // Filtrar issues duplicados del Sprint 1
        const duplicateIssuesData = allIssues.filter(issue => 
            duplicateIssues.includes(issue.identifier) && 
            issue.project && 
            issue.project.name === 'Multi-Tenancy Backend'
        );

        console.log(`✅ Issues duplicados encontrados: ${duplicateIssuesData.length}`);
        
        // Mostrar issues a eliminar
        console.log('\n📋 Issues a eliminar:');
        duplicateIssuesData.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            console.log(`   ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        // Eliminar issues duplicados
        console.log('\n🗑️ Eliminando issues duplicados...');
        let deletedCount = 0;

        for (const issue of duplicateIssuesData) {
            const deleteMutation = `
                mutation {
                    issueDelete(id: "${issue.id}") {
                        success
                    }
                }
            `;

            try {
                const response = await makeLinearRequest(deleteMutation);
                
                if (response.issueDelete.success) {
                    console.log(`   ✅ ${issue.identifier}: Eliminado`);
                    deletedCount++;
                } else {
                    console.log(`   ❌ Error eliminando ${issue.identifier}`);
                }
            } catch (error) {
                console.log(`   ❌ Error eliminando ${issue.identifier}:`, error.message);
            }
        }

        console.log(`\n🎉 ¡Duplicados eliminados!`);
        console.log(`📊 Issues eliminados: ${deletedCount}/${duplicateIssuesData.length}`);

        // Verificar issues únicos restantes
        console.log('\n🔍 Verificando issues únicos restantes...');
        const finalIssuesData = await makeLinearRequest(issuesQuery);
        const finalSprint1Issues = finalIssuesData.issues.nodes.filter(issue => 
            uniqueIssues.includes(issue.identifier) && 
            issue.project && 
            issue.project.name === 'Multi-Tenancy Backend'
        );

        console.log(`\n📋 Issues únicos del Sprint 1: ${finalSprint1Issues.length}`);
        finalSprint1Issues.forEach(issue => {
            const points = issue.estimate ? `${issue.estimate} pts` : 'Sin puntos';
            const status = issue.state.name === 'In Progress' ? '✅' : '❌';
            console.log(`   ${status} ${issue.identifier}: ${issue.title} (${issue.state.name}) - ${points}`);
        });

        // Calcular total de story points únicos
        const totalPoints = finalSprint1Issues.reduce((sum, issue) => sum + (issue.estimate || 0), 0);
        console.log(`\n📊 Total de story points únicos: ${totalPoints}`);

        console.log('\n🎯 Sprint 1 optimizado:');
        console.log('════════════════════════════════════════════════════════════════════════════════');
        console.log('📝 Objetivo: Implementar la base de multi-tenancy para permitir múltiples clubes');
        console.log(`📊 Story Points: ${totalPoints} (optimizado, sin duplicados)`);
        console.log(`⏱️ Duración: 2 semanas (3-17 de octubre, 2025)`);
        console.log(`👥 Asignado a: fernando rodriguez`);
        console.log(`📋 Issues únicos: ${finalSprint1Issues.length}`);
        console.log('════════════════════════════════════════════════════════════════════════════════');

    } catch (error) {
        console.error('❌ Error eliminando duplicados:', error.message);
    }
}

removeDuplicatesSprint1();
