#!/usr/bin/env node

/**
 * Script de Versionamiento Automático
 * Actualiza las versiones en todos los archivos del proyecto
 * 
 * Uso:
 *   node scripts/version.js patch      # 1.3.3 -> 1.3.4
 *   node scripts/version.js minor      # 1.3.3 -> 1.4.0
 *   node scripts/version.js major      # 1.3.3 -> 2.0.0
 *   node scripts/version.js prerelease # 1.3.3 -> 1.3.4-alpha.1
 */

const fs = require('fs');
const path = require('path');

// Colores para la consola
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
};

// Rutas de los archivos
const paths = {
  backendPackage: path.join(__dirname, '../backend/package.json'),
  mobilePubspec: path.join(__dirname, '../mobile/pubspec.yaml'),
  versionService: path.join(__dirname, '../mobile/lib/core/services/version_service.dart'),
  versionWidget: path.join(__dirname, '../mobile/lib/core/widgets/version_widget.dart'),
  professorScreen: path.join(__dirname, '../mobile/lib/features/professor/presentation/screens/professor_home_screen.dart'),
  webIndex: path.join(__dirname, '../mobile/web/index.html'),
};

/**
 * Parsea una versión SemVer
 */
function parseVersion(version) {
  const match = version.match(/^(\d+)\.(\d+)\.(\d+)(?:-([\w.]+))?(?:\+(\d+))?$/);
  if (!match) {
    throw new Error(`Versión inválida: ${version}`);
  }
  return {
    major: parseInt(match[1], 10),
    minor: parseInt(match[2], 10),
    patch: parseInt(match[3], 10),
    prerelease: match[4] || null,
    build: match[5] ? parseInt(match[5], 10) : null,
  };
}

/**
 * Formatea una versión SemVer
 */
function formatVersion(version, includeBuild = false) {
  let versionStr = `${version.major}.${version.minor}.${version.patch}`;
  if (version.prerelease) {
    versionStr += `-${version.prerelease}`;
  }
  if (includeBuild && version.build !== null) {
    versionStr += `+${version.build}`;
  }
  return versionStr;
}

/**
 * Incrementa una versión según el tipo
 */
function incrementVersion(currentVersion, type, preId = 'alpha') {
  const version = parseVersion(currentVersion);
  
  switch (type) {
    case 'major':
      return {
        ...version,
        major: version.major + 1,
        minor: 0,
        patch: 0,
        prerelease: null,
        build: version.build !== null ? version.build + 1 : 1,
      };
    
    case 'minor':
      return {
        ...version,
        minor: version.minor + 1,
        patch: 0,
        prerelease: null,
        build: version.build !== null ? version.build + 1 : 1,
      };
    
    case 'patch':
      return {
        ...version,
        patch: version.patch + 1,
        prerelease: null,
        build: version.build !== null ? version.build + 1 : 1,
      };
    
    case 'prerelease':
      if (version.prerelease) {
        // Si ya es prerelease, incrementa el número
        const match = version.prerelease.match(/^([\w]+)\.(\d+)$/);
        if (match && match[1] === preId) {
          return {
            ...version,
            prerelease: `${preId}.${parseInt(match[2], 10) + 1}`,
            build: version.build !== null ? version.build + 1 : 1,
          };
        }
      }
      // Nuevo prerelease
      return {
        ...version,
        patch: version.patch + 1,
        prerelease: `${preId}.1`,
        build: version.build !== null ? version.build + 1 : 1,
      };
    
    default:
      throw new Error(`Tipo de incremento inválido: ${type}`);
  }
}

/**
 * Lee la versión del backend
 */
function getBackendVersion() {
  const content = fs.readFileSync(paths.backendPackage, 'utf8');
  const json = JSON.parse(content);
  return json.version;
}

/**
 * Lee la versión del frontend
 */
function getFrontendVersion() {
  const content = fs.readFileSync(paths.mobilePubspec, 'utf8');
  const match = content.match(/^version:\s*(.+)$/m);
  if (!match) {
    throw new Error('No se encontró la versión en pubspec.yaml');
  }
  return match[1].trim();
}

/**
 * Actualiza la versión del backend
 */
function updateBackendVersion(newVersion) {
  const content = fs.readFileSync(paths.backendPackage, 'utf8');
  const json = JSON.parse(content);
  json.version = formatVersion(newVersion);
  fs.writeFileSync(paths.backendPackage, JSON.stringify(json, null, 2) + '\n', 'utf8');
  console.log(`${colors.green}✓${colors.reset} Backend: ${paths.backendPackage}`);
}

/**
 * Actualiza la versión del frontend (pubspec.yaml)
 */
function updateFrontendVersion(newVersion) {
  let content = fs.readFileSync(paths.mobilePubspec, 'utf8');
  const versionStr = formatVersion(newVersion, true);
  content = content.replace(/^version:\s*.+$/m, `version: ${versionStr}`);
  fs.writeFileSync(paths.mobilePubspec, content, 'utf8');
  console.log(`${colors.green}✓${colors.reset} Frontend: ${paths.mobilePubspec}`);
}

/**
 * Actualiza version_service.dart
 */
function updateVersionService(newVersion) {
  let content = fs.readFileSync(paths.versionService, 'utf8');
  const versionStr = formatVersion(newVersion);
  content = content.replace(
    /String get version => _packageInfo\?\.version \?\? '[\d.]+';/,
    `String get version => _packageInfo?.version ?? '${versionStr}';`
  );
  fs.writeFileSync(paths.versionService, content, 'utf8');
  console.log(`${colors.green}✓${colors.reset} VersionService: ${paths.versionService}`);
}

/**
 * Actualiza version_widget.dart
 */
function updateVersionWidget(newVersion) {
  let content = fs.readFileSync(paths.versionWidget, 'utf8');
  const versionStr = formatVersion(newVersion);
  const versionWithoutV = versionStr;
  const versionWithV = `v${versionStr}`;
  
  // Actualizar _version
  content = content.replace(
    /final String _version = 'v[\d.]+';/,
    `final String _version = '${versionWithV}';`
  );
  
  // Actualizar buildNumber si existe
  if (newVersion.build !== null) {
    content = content.replace(
      /final String _buildNumber = '[\d]+';/,
      `final String _buildNumber = '${newVersion.build}';`
    );
  }
  
  // Actualizar en el badge
  content = content.replace(
    /'v[\d.]+'/g,
    `'${versionWithV}'`
  );
  
  fs.writeFileSync(paths.versionWidget, content, 'utf8');
  console.log(`${colors.green}✓${colors.reset} VersionWidget: ${paths.versionWidget}`);
}

/**
 * Actualiza professor_home_screen.dart
 */
function updateProfessorScreen(newVersion) {
  let content = fs.readFileSync(paths.professorScreen, 'utf8');
  const versionStr = formatVersion(newVersion);
  
  // Actualizar ambas ocurrencias de version
  content = content.replace(
    /version: '[\d.]+',/g,
    `version: '${versionStr}',`
  );
  
  fs.writeFileSync(paths.professorScreen, content, 'utf8');
  console.log(`${colors.green}✓${colors.reset} ProfessorScreen: ${paths.professorScreen}`);
}

/**
 * Actualiza web/index.html
 */
function updateWebIndex(newVersion) {
  let content = fs.readFileSync(paths.webIndex, 'utf8');
  const versionStr = formatVersion(newVersion);
  const versionWithV = `v${versionStr}`;
  
  content = content.replace(
    /<title>v[\d.]+ tennis_management<\/title>/,
    `<title>${versionWithV} tennis_management</title>`
  );
  
  fs.writeFileSync(paths.webIndex, content, 'utf8');
  console.log(`${colors.green}✓${colors.reset} Web Index: ${paths.webIndex}`);
}

/**
 * Función principal
 */
function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error(`${colors.red}Error:${colors.reset} Debes especificar el tipo de incremento (patch, minor, major, prerelease)`);
    console.log(`\nUso: node scripts/version.js <tipo> [--preid=<id>]`);
    console.log(`\nTipos:`);
    console.log(`  patch      - Incrementa patch (1.3.3 -> 1.3.4)`);
    console.log(`  minor      - Incrementa minor (1.3.3 -> 1.4.0)`);
    console.log(`  major      - Incrementa major (1.3.3 -> 2.0.0)`);
    console.log(`  prerelease - Crea prerelease (1.3.3 -> 1.3.4-alpha.1)`);
    process.exit(1);
  }
  
  const type = args[0];
  if (!['patch', 'minor', 'major', 'prerelease'].includes(type)) {
    console.error(`${colors.red}Error:${colors.reset} Tipo inválido: ${type}`);
    console.log(`Tipos válidos: patch, minor, major, prerelease`);
    process.exit(1);
  }
  
  // Extraer preid si existe
  let preId = 'alpha';
  const preIdArg = args.find(arg => arg.startsWith('--preid='));
  if (preIdArg) {
    preId = preIdArg.split('=')[1];
  }
  
  try {
    // Obtener versiones actuales
    const backendVersion = getBackendVersion();
    const frontendVersion = getFrontendVersion();
    
    // Usar la versión más alta como base
    const baseVersion = backendVersion > frontendVersion.split('+')[0] 
      ? backendVersion 
      : frontendVersion.split('+')[0];
    
    console.log(`${colors.blue}Versión actual:${colors.reset} ${baseVersion}`);
    
    // Incrementar versión
    const newVersion = incrementVersion(baseVersion, type, preId);
    const newVersionStr = formatVersion(newVersion, true);
    
    console.log(`${colors.blue}Nueva versión:${colors.reset} ${newVersionStr}\n`);
    
    // Actualizar todos los archivos
    updateBackendVersion(newVersion);
    updateFrontendVersion(newVersion);
    updateVersionService(newVersion);
    updateVersionWidget(newVersion);
    updateProfessorScreen(newVersion);
    updateWebIndex(newVersion);
    
    console.log(`\n${colors.bright}${colors.green}✓ Versión actualizada exitosamente${colors.reset}`);
    console.log(`\n${colors.yellow}Nota:${colors.reset} Revisa los cambios y haz commit:`);
    console.log(`  git add .`);
    console.log(`  git commit -m "chore: bump version to ${formatVersion(newVersion)}"`);
    
  } catch (error) {
    console.error(`${colors.red}Error:${colors.reset} ${error.message}`);
    process.exit(1);
  }
}

// Ejecutar
main();

