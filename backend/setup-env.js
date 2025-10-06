#!/usr/bin/env node

import fetch from 'node-fetch';

const API_KEY = 'rnd_kfpRKz3takdTfisxcOyCGeHG0PsO';
const BASE_URL = 'https://api.render.com/v1';
const SERVICE_ID = 'srv-d3f05fhr0fns73d3jm60';

// Variables de entorno necesarias para el build
const requiredEnvVars = [
  {
    key: 'NODE_ENV',
    value: 'production'
  },
  {
    key: 'PORT',
    value: '3000'
  },
  {
    key: 'FIREBASE_PROJECT_ID',
    value: 'tennis-management-fcd54'
  },
  {
    key: 'CORS_ORIGINS',
    value: 'https://tennis-management-fcd54.web.app'
  },
  {
    key: 'JSON_LIMIT',
    value: '1mb'
  },
  {
    key: 'RATE_LIMIT_WINDOW_MS',
    value: '900000'
  },
  {
    key: 'RATE_LIMIT_MAX',
    value: '100'
  },
  {
    key: 'RATE_LIMIT_AUTH_MAX',
    value: '20'
  }
];

async function setupEnvironmentVariables() {
  try {
    console.log('🔧 Configurando variables de entorno en Render...');
    
    const response = await fetch(`${BASE_URL}/services/${SERVICE_ID}/env-vars`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        envVars: requiredEnvVars
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error configurando variables: ${response.status} ${response.statusText}\n${errorText}`);
    }
    
    console.log('✅ Variables de entorno configuradas exitosamente!');
    console.log('📋 Variables configuradas:');
    requiredEnvVars.forEach((envVar, index) => {
      console.log(`${index + 1}. ${envVar.key}: ${envVar.value}`);
    });
    
    console.log('\n⚠️ IMPORTANTE: Las siguientes variables críticas necesitan ser configuradas manualmente en el dashboard de Render:');
    console.log('   • MONGO_URI (tu conexión a MongoDB)');
    console.log('   • JWT_SECRET (clave secreta para JWT)');
    console.log('   • FIREBASE_PRIVATE_KEY (clave privada de Firebase)');
    console.log('   • FIREBASE_CLIENT_EMAIL (email del cliente de Firebase)');
    
    console.log('\n🔗 Ve a: https://dashboard.render.com/web/srv-d3f05fhr0fns73d3jm60/environment');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

setupEnvironmentVariables();
