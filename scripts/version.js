#!/usr/bin/env node

/**
 * Script para manejo de versiones usando Semantic Versioning (SemVer)
 * Uso: node scripts/version.js [major|minor|patch|prerelease] [--preid=alpha|beta|rc]
 */

const fs = require('fs');
const path = require('path');

// Colores para la consola
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function parseVersion(version) {
  const [versionPart, buildPart] = version.split('+');
  const [major, minor, patch, ...prerelease] = versionPart.split('.');
  
  return {
    major: parseInt(major),
    minor: parseInt(minor),
    patch: parseInt(patch),
    prerelease: prerelease.join('.'),
    build: buildPart ? parseInt(buildPart) : 1
  };
}

function formatVersion(versionObj) {
  let version = `${versionObj.major}.${versionObj.minor}.${versionObj.patch}`;
  if (versionObj.prerelease) {
    version += `.${versionObj.prerelease}`;
  }
  return `${version}+${versionObj.build}`;
}

function incrementVersion(currentVersion, type, preid = 'alpha') {
  const version = parseVersion(currentVersion);
  
  switch (type) {
    case 'major':
      version.major++;
      version.minor = 0;
      version.patch = 0;
      version.prerelease = '';
      break;
    case 'minor':
      version.minor++;
      version.patch = 0;
      version.prerelease = '';
      break;
    case 'patch':
      version.patch++;
      version.prerelease = '';
      break;
    case 'prerelease':
      if (version.prerelease) {
        const [preType, preNum] = version.prerelease.split('.');
        if (preType === preid) {
          version.prerelease = `${preid}.${parseInt(preNum || '0') + 1}`;
        } else {
          version.prerelease = `${preid}.1`;
        }
      } else {
        version.prerelease = `${preid}.1`;
      }
      break;
    default:
      throw new Error(`Tipo de versión no válido: ${type}`);
  }
  
  version.build++;
  return formatVersion(version);
}

function updatePackageJson(filePath, newVersion) {
  const packageJson = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  packageJson.version = newVersion.split('+')[0]; // Solo la parte de versión, no el build
  fs.writeFileSync(filePath, JSON.stringify(packageJson, null, 2) + '\n');
}

function updatePubspecYaml(filePath, newVersion) {
  let content = fs.readFileSync(filePath, 'utf8');
  const versionRegex = /^version:\s*(.+)$/m;
  content = content.replace(versionRegex, `version: ${newVersion}`);
  fs.writeFileSync(filePath, content);
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    log('Uso: node scripts/version.js [major|minor|patch|prerelease] [--preid=alpha|beta|rc]', 'yellow');
    log('Ejemplos:', 'cyan');
    log('  node scripts/version.js patch          # 1.2.0 -> 1.2.1', 'cyan');
    log('  node scripts/version.js minor          # 1.2.0 -> 1.3.0', 'cyan');
    log('  node scripts/version.js major          # 1.2.0 -> 2.0.0', 'cyan');
    log('  node scripts/version.js prerelease     # 1.2.0 -> 1.2.1-alpha.1', 'cyan');
    log('  node scripts/version.js prerelease --preid=beta  # 1.2.0 -> 1.2.1-beta.1', 'cyan');
    process.exit(1);
  }
  
  const type = args[0];
  const preidArg = args.find(arg => arg.startsWith('--preid='));
  const preid = preidArg ? preidArg.split('=')[1] : 'alpha';
  
  if (!['major', 'minor', 'patch', 'prerelease'].includes(type)) {
    log(`Error: Tipo de versión no válido: ${type}`, 'red');
    process.exit(1);
  }
  
  try {
    // Leer versiones actuales
    const frontendPath = path.join(__dirname, '../mobile/pubspec.yaml');
    const backendPath = path.join(__dirname, '../backend/package.json');
    
    const frontendContent = fs.readFileSync(frontendPath, 'utf8');
    const backendContent = fs.readFileSync(backendPath, 'utf8');
    
    const frontendVersionMatch = frontendContent.match(/^version:\s*(.+)$/m);
    const backendVersionMatch = JSON.parse(backendContent).version;
    
    if (!frontendVersionMatch) {
      throw new Error('No se pudo encontrar la versión en pubspec.yaml');
    }
    
    const currentFrontendVersion = frontendVersionMatch[1];
    const currentBackendVersion = backendVersionMatch;
    
    log(`Versión actual Frontend: ${currentFrontendVersion}`, 'blue');
    log(`Versión actual Backend: ${currentBackendVersion}`, 'blue');
    
    // Incrementar versiones
    const newFrontendVersion = incrementVersion(currentFrontendVersion, type, preid);
    const newBackendVersion = incrementVersion(currentBackendVersion, type, preid);
    
    log(`Nueva versión Frontend: ${newFrontendVersion}`, 'green');
    log(`Nueva versión Backend: ${newBackendVersion}`, 'green');
    
    // Actualizar archivos
    updatePubspecYaml(frontendPath, newFrontendVersion);
    updatePackageJson(backendPath, newBackendVersion);
    
    log('✅ Versiones actualizadas exitosamente!', 'green');
    log('📝 Recuerda hacer commit de los cambios:', 'yellow');
    log('   git add .', 'cyan');
    log(`   git commit -m "chore: bump version to ${newFrontendVersion.split('+')[0]}"`, 'cyan');
    log('   git push', 'cyan');
    
  } catch (error) {
    log(`Error: ${error.message}`, 'red');
    process.exit(1);
  }
}

main();
