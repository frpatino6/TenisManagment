# Backend - Tennis Management

## Linting y Formateo

Este proyecto usa ESLint (v9 flat config) y Prettier para mantener un estilo de código consistente.

- Ejecutar linter:
  
  ```bash
  npm run lint
  ```

- Auto-fix de reglas y formateo:
  
  ```bash
  npm run lint:fix
  npm run format
  ```

Configuraciones:
- `eslint.config.js` (flat config v9)
- `.prettierrc`

Notas:
- ESLint ignora `dist/` y `node_modules/` mediante `ignores` en `eslint.config.js`.
- Prettier se ejecuta sobre `src/**/*.{ts,js,json,md}`.
