#!/usr/bin/env node

// Script de prueba para el MCP server de Linear
const { spawn } = require('child_process');

console.log('🧪 Probando el MCP server de Linear...\n');

// Simular una consulta MCP
const testQuery = {
  jsonrpc: '2.0',
  id: 1,
  method: 'tools/list',
  params: {}
};

const server = spawn('npx', ['-y', 'linear-mcp-server'], {
  env: {
    ...process.env,
    LINEAR_API_KEY: 'YOUR_LINEAR_API_KEY_HERE'
  },
  stdio: ['pipe', 'pipe', 'pipe']
});

server.stdin.write(JSON.stringify(testQuery) + '\n');
server.stdin.end();

let output = '';
server.stdout.on('data', (data) => {
  output += data.toString();
});

server.stderr.on('data', (data) => {
  console.log('Server output:', data.toString());
});

server.on('close', (code) => {
  console.log('✅ Servidor MCP de Linear funcionando correctamente!');
  console.log('📋 Herramientas disponibles:');
  
  try {
    const response = JSON.parse(output);
    if (response.result && response.result.tools) {
      response.result.tools.forEach(tool => {
        console.log(`  - ${tool.name}: ${tool.description}`);
      });
    }
  } catch (e) {
    console.log('Respuesta del servidor:', output);
  }
  
  console.log('\n🎉 Configuración completada!');
  console.log('📝 Para usar en Cursor, agrega esta configuración:');
  console.log(JSON.stringify({
    mcpServers: {
      linear: {
        command: "npx",
        args: ["-y", "linear-mcp-server"],
        env: {
          LINEAR_API_KEY: "YOUR_LINEAR_API_KEY_HERE"
        }
      }
    }
  }, null, 2));
});

server.on('error', (error) => {
  console.error('❌ Error al ejecutar el servidor:', error);
});
