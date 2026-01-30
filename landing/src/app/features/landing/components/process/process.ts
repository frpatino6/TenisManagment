import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
    selector: 'app-process',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './process.html',
    styleUrl: './process.scss'
})
export class ProcessComponent { }

/*
### Ajustes Visuales y Responsivos
- **Jerarquía**: Se añadió `mb-6` al `<h1>` para evitar que el texto se vea apiñado contra el subtítulo en dispositivos móviles.
- **Botón Mobile**: Se configuró para que ocupe el ancho completo (`full-width`) en dispositivos móviles, facilitando la interacción.

## Nueva Sección: Cómo funciona

Se ha añadido una nueva sección debajo del Hero que guía a los dueños de clubes en su proceso de digitalización.

### Diseño y Estructura
- **Título**: "Modernice su gestión en 3 simples pasos" (H2 centrado con acento verde).
- **Cards de 3 Pasos**:
    1. **Configura tu academia**: Carga de canchas y horarios.
    2. **Digitaliza a tus alumnos**: Activación de monedero virtual.
    3. **Toma el control**: Rankings, torneos y datos en tiempo real.
- **Responsividad**: Las cards se apilan automáticamente en mobile y se muestran en 3 columnas en desktop.
- **Estética**: Números grandes en color verde institucional y padding generoso (`py-24`) para un aire moderno.

## Verificación Realizada

### Verificación Visual
Se validaron tanto el Hero actualizado como la nueva sección de proceso.

```carousel
![Optimización del Hero](/home/fernando/.gemini/antigravity/brain/e82776ae-dd40-49e6-9497-da71381e62b8/hero_optimization_verification_1769741090764.webp)
<!-- slide -->
![Sección Cómo funciona](/home/fernando/.gemini/antigravity/brain/e82776ae-dd40-49e6-9497-da71381e62b8/process_section_verification_1769741189429.webp)
```

> [!NOTE]
> La grabación muestra la navegación por ambas secciones, validando textos, jerarquía visual y comportamiento responsivo.

### Verificación de Build
- Se ejecutó `npm run build` exitosamente después de todas las modificaciones.
*/
