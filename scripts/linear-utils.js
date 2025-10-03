#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');

// Load environment variables from linear-config.env if it exists
function loadLinearConfig() {
  const envPath = path.join(__dirname, 'linear-config.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    const lines = envContent.split('\n');
    
    lines.forEach(line => {
      const [key, value] = line.split('=');
      if (key && value) {
        process.env[key.trim()] = value.trim();
      }
    });
  }
}

// Load config
loadLinearConfig();

// Get Linear configuration from environment variables
function getLinearConfig() {
  const apiKey = process.env.LINEAR_API_KEY;
  const teamId = process.env.LINEAR_TEAM_ID;
  
  if (!apiKey) {
    throw new Error('LINEAR_API_KEY environment variable is required. Please set it in linear-config.env file.');
  }
  
  if (!teamId) {
    throw new Error('LINEAR_TEAM_ID environment variable is required. Please set it in linear-config.env file.');
  }
  
  return { apiKey, teamId };
}

// Función para hacer requests a la API de Linear
function makeLinearRequest(query, variables = {}) {
  const { apiKey } = getLinearConfig();
  
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      query: query,
      variables: variables
    });

    const options = {
      hostname: 'api.linear.app',
      port: 443,
      path: '/graphql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'Authorization': apiKey
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve(response);
        } catch (error) {
          reject(new Error(`Error parsing response: ${error.message}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Export functions for use in other scripts
module.exports = {
  getLinearConfig,
  makeLinearRequest,
  loadLinearConfig
};
