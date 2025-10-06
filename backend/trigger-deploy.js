#!/usr/bin/env node

import fetch from 'node-fetch';

const API_KEY = 'rnd_kfpRKz3takdTfisxcOyCGeHG0PsO';
const BASE_URL = 'https://api.render.com/v1';
const SERVICE_ID = 'srv-d3f05fhr0fns73d3jm60';

async function triggerDeploy() {
  try {
    console.log('🚀 Iniciando nuevo despliegue...');
    
    const response = await fetch(`${BASE_URL}/services/${SERVICE_ID}/deploys`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error iniciando despliegue: ${response.status} ${response.statusText}\n${errorText}`);
    }
    
    const result = await response.json();
    console.log('📋 Respuesta completa:', JSON.stringify(result, null, 2));
    
    const deploy = result.deploy || result;
    console.log('✅ Despliegue iniciado exitosamente!');
    console.log(`🆔 ID del despliegue: ${deploy.id}`);
    console.log(`📊 Estado: ${deploy.status}`);
    console.log(`⏰ Iniciado: ${new Date(deploy.createdAt).toLocaleString()}`);
    
    // Monitorear el despliegue
    console.log('\n🔍 Monitoreando despliegue...');
    await monitorDeploy(deploy.id);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function monitorDeploy(deployId) {
  const maxAttempts = 20; // 10 minutos máximo
  let attempts = 0;
  
  while (attempts < maxAttempts) {
    attempts++;
    
    try {
      const response = await fetch(`${BASE_URL}/services/${SERVICE_ID}/deploys/${deployId}`, {
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error(`Error obteniendo estado: ${response.status}`);
      }
      
      const deploy = await response.json();
      const status = deploy.deploy.status;
      
      console.log(`📊 Intento ${attempts}: Estado = ${status}`);
      
      if (status === 'live') {
        console.log('✅ Despliegue completado exitosamente!');
        console.log(`🌐 URL: https://tenismanagment.onrender.com`);
        return;
      } else if (status === 'build_failed' || status === 'deploy_failed') {
        console.log('❌ Despliegue falló!');
        console.log(`📊 Estado final: ${status}`);
        
        // Intentar obtener logs
        try {
          const logsResponse = await fetch(`${BASE_URL}/services/${SERVICE_ID}/deploys/${deployId}/logs`, {
            headers: {
              'Authorization': `Bearer ${API_KEY}`,
              'Content-Type': 'application/json'
            }
          });
          
          if (logsResponse.ok) {
            const logs = await logsResponse.json();
            console.log('\n📄 Logs del error:');
            console.log('```');
            console.log(logs.logs || 'No hay logs disponibles');
            console.log('```');
          }
        } catch (logError) {
          console.log('⚠️ No se pudieron obtener los logs');
        }
        
        return;
      }
      
      // Esperar 30 segundos antes del siguiente check
      await new Promise(resolve => setTimeout(resolve, 30000));
      
    } catch (error) {
      console.log(`⚠️ Error en intento ${attempts}: ${error.message}`);
      await new Promise(resolve => setTimeout(resolve, 30000));
    }
  }
  
  console.log('⏰ Timeout: El despliegue tardó más de 10 minutos');
}

triggerDeploy();
