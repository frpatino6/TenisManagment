#!/usr/bin/env node

import fetch from 'node-fetch';

const API_KEY = 'rnd_kfpRKz3takdTfisxcOyCGeHG0PsO';
const BASE_URL = 'https://api.render.com/v1';
const SERVICE_ID = 'srv-d3f05fhr0fns73d3jm60';

async function checkEnvironmentVariables() {
  try {
    console.log('🔍 Verificando variables de entorno en Render...');
    
    const response = await fetch(`${BASE_URL}/services/${SERVICE_ID}/env-vars`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Error API: ${response.status} ${response.statusText}`);
    }
    
    const envVars = await response.json();
    console.log('📋 Variables de entorno configuradas:');
    
    if (envVars.envVars && envVars.envVars.length > 0) {
      envVars.envVars.forEach((envVar, index) => {
        const value = envVar.value ? (envVar.value.length > 20 ? envVar.value.substring(0, 20) + '...' : envVar.value) : 'NO CONFIGURADA';
        console.log(`${index + 1}. ${envVar.key}: ${value}`);
      });
    } else {
      console.log('❌ No hay variables de entorno configuradas');
    }
    
    // Verificar variables críticas
    console.log('\n🔍 Verificando variables críticas:');
    const criticalVars = ['MONGO_URI', 'JWT_SECRET', 'FIREBASE_PRIVATE_KEY', 'FIREBASE_CLIENT_EMAIL'];
    
    if (envVars.envVars) {
      criticalVars.forEach(varName => {
        const found = envVars.envVars.find(env => env.key === varName);
        if (found) {
          console.log(`✅ ${varName}: Configurada`);
        } else {
          console.log(`❌ ${varName}: NO CONFIGURADA`);
        }
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkEnvironmentVariables();
