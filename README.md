# Sistema de Gestión Estudiantil - UNEXCA

Proyecto 3 de la Universidad Nacional Experimental de la Gran Caracas (UNEXCA).

## Descripción

Aplicación web para la gestión estudiantil que permite administrar:

- **Estudiantes**: registro, edición y eliminación de estudiantes con todos sus datos personales y académicos.
- **Materias**: gestión del catálogo de materias con código, semestre, créditos y profesor asignado.
- **Calificaciones**: registro de notas por estudiante, materia y período académico, con cálculo automático de estado (Aprobado / Reparación / Reprobado).
- **Reportes**: estadísticas por carrera, semestre, promedios por materia y porcentaje de aprobados vs reprobados, con exportación a CSV.

## Características

- Interfaz responsiva adaptada para dispositivos móviles y de escritorio.
- Persistencia de datos mediante `localStorage` (no requiere backend).
- Validación de formularios en el cliente.
- Búsqueda y filtrado en tiempo real en todas las tablas.
- Exportación de datos a formato CSV (compatible con Excel).
- Notificaciones visuales al realizar operaciones.

## Estructura del Proyecto

```
Proyecto-3-Unexca/
├── index.html          # Página principal (SPA)
├── css/
│   └── styles.css      # Estilos generales y responsivos
├── js/
│   ├── storage.js      # Capa de acceso a localStorage
│   ├── students.js     # Módulo de gestión de estudiantes
│   ├── courses.js      # Módulo de gestión de materias
│   ├── grades.js       # Módulo de gestión de calificaciones
│   ├── reports.js      # Módulo de reportes y exportación CSV
│   └── app.js          # Inicialización, navegación y utilidades globales
└── README.md
```

## Uso

Abrir el archivo `index.html` directamente en cualquier navegador moderno (Chrome, Firefox, Edge).
No se requiere servidor ni instalación de dependencias.

## Tecnologías

- HTML5
- CSS3 (diseño responsivo con CSS Grid y Flexbox)
- JavaScript (ES6+, vanilla, sin frameworks externos)
- Web Storage API (`localStorage`)

