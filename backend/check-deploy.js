#!/usr/bin/env node

import fetch from 'node-fetch';

const API_KEY = 'rnd_kfpRKz3takdTfisxcOyCGeHG0PsO';
const BASE_URL = 'https://api.render.com/v1';

async function checkDeployStatus() {
  try {
    console.log('🔍 Verificando estado del servicio...');
    
    // 1. Listar servicios
    const servicesResponse = await fetch(`${BASE_URL}/services`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!servicesResponse.ok) {
      throw new Error(`Error API: ${servicesResponse.status} ${servicesResponse.statusText}`);
    }
    
    const servicesData = await servicesResponse.json();
    console.log('📋 Respuesta completa:', JSON.stringify(servicesData, null, 2));
    
    // La API de Render devuelve un array directo, no un objeto con services
    const services = Array.isArray(servicesData) ? servicesData : servicesData.services || [];
    console.log(`📋 Servicios encontrados: ${services.length}`);
    
    // 2. Buscar nuestro servicio
    const ourService = services.find(s => 
      s.service?.name === 'TenisManagment' || 
      s.service?.name?.includes('TenisManagment') ||
      s.service?.name?.includes('tennis')
    );
    
    if (!ourService) {
      console.log('❌ Servicio TenisManagment no encontrado');
      console.log('Servicios disponibles:', services.map(s => s.service?.name));
      return;
    }
    
    console.log(`✅ Servicio encontrado: ${ourService.service.name} (ID: ${ourService.service.id})`);
    
    // 3. Obtener estado del servicio
    const serviceResponse = await fetch(`${BASE_URL}/services/${ourService.service.id}`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const serviceDetails = await serviceResponse.json();
    const service = serviceDetails.service || serviceDetails;
    
    console.log('\n📊 Estado del servicio:');
    console.log(`   🆔 ID: ${service.id}`);
    console.log(`   📛 Nombre: ${service.name}`);
    console.log(`   🟢 Estado: ${service.serviceDetails?.buildStatus || 'unknown'}`);
    console.log(`   🌐 URL: ${service.serviceDetails?.url || 'No disponible'}`);
    console.log(`   ⏰ Última actualización: ${new Date(service.updatedAt).toLocaleString()}`);
    
    // 4. Obtener historial de despliegues
    console.log('\n📋 Obteniendo historial de despliegues...');
    const deploysResponse = await fetch(`${BASE_URL}/services/${ourService.service.id}/deploys?limit=5`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const deploys = await deploysResponse.json();
    console.log(`\n🔄 Últimos ${deploys.deploys?.length || 0} despliegues:`);
    
    deploys.deploys?.forEach((deploy, index) => {
      console.log(`\n${index + 1}. 🆔 ${deploy.id}`);
      console.log(`   📊 Estado: ${deploy.status}`);
      console.log(`   ⏰ Fecha: ${new Date(deploy.createdAt).toLocaleString()}`);
      console.log(`   🔗 URL: ${deploy.url || 'N/A'}`);
      
      if (deploy.status === 'build_failed' || deploy.status === 'deploy_failed') {
        console.log(`   ❌ ERROR: Despliegue falló`);
      }
    });
    
    // 5. Obtener logs del último despliegue si falló
    const lastDeploy = deploys.deploys?.[0];
    if (lastDeploy && (lastDeploy.status === 'build_failed' || lastDeploy.status === 'deploy_failed')) {
      console.log('\n📋 Obteniendo logs del último despliegue fallido...');
      
      const logsResponse = await fetch(`${BASE_URL}/services/${ourService.service.id}/deploys/${lastDeploy.id}/logs?lines=50`, {
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json'
        }
      });
      
      const logs = await logsResponse.json();
      console.log('\n📄 Logs del despliegue fallido:');
      console.log('```');
      console.log(logs.logs || 'No hay logs disponibles');
      console.log('```');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkDeployStatus();
