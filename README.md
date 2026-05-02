# ARES - Sistema de Gestión de Tickets Técnicos

Aplicación móvil Flutter para gestión de tickets técnicos con backend Node.js y base de datos MySQL.

## 🚀 Funcionalidades Principales

### 🔐 Gestión de Usuarios
- **Login y registro** con autenticación JWT
- **Roles de usuario:** Master, Administrador, Técnico, Cliente
- **Protección de usuarios inactivos** (no pueden iniciar sesión)

### 👥 Gestión de Técnicos
- **Ver lista de técnicos** con estado y privilegios
- **Inactivar/Activar técnicos** con indicadores visuales
- **Cambiar privilegios** entre roles de usuario
- **Agregar nuevos técnicos** con validación
- **Eliminar técnicos** (solo usuarios Master)

### 📋 Gestión de Tickets
- **Crear nuevos tickets** con categoría, prioridad y descripción
- **Editar tickets existentes** con actualización de estado
- **Ver lista de tickets** con filtros y búsqueda
- **Asignar técnicos** a tickets
- **Seguimiento de estados:** Abierto, Asignado, En Diagnóstico, En Reparación, Listo, Entregado, Cancelado

### 🖥️ Gestión de Clientes
- **Ver lista de clientes** con información de contacto
- **Inactivar/Activar clientes** con indicadores visuales
- **Información detallada** de cada cliente

### 💻 Gestión de Equipos
- **Ver lista de equipos** con información técnica
- **Eliminar equipos** con actualización automática de la lista
- **Asociar equipos** a clientes y tickets

## 🔧 Características Técnicas

### Backend (Node.js + Express)
- **API RESTful** con endpoints seguros
- **Autenticación JWT** para todas las operaciones
- **Validación de datos** y manejo de errores
- **Base de datos MySQL** con relaciones optimizadas
- **Endpoints especializados** por rol de usuario

### Frontend (Flutter)
- **Interfaz moderna** con Material Design
- **Navegación fluida** entre módulos
- **Formularios validados** con feedback en tiempo real
- **Indicadores visuales** de estado y acciones
- **Responsive design** para diferentes pantallas

### Seguridad
- **Restricciones por rol:** Solo Master puede eliminar técnicos
- **Protección del usuario Master:** No puede ser inactivado ni modificado
- **Validación de sesión** en todas las operaciones
- **Manejo seguro de contraseñas** con bcrypt

## 📋 Requisitos

- **Flutter SDK** (última versión estable)
- **Node.js LTS** (incluye `node` y `npm`)
- **MySQL o MariaDB** (versión 8.0+ recomendada)

## 🚀 Instalación y Ejecución

### 1) Configurar Backend
```bash
cd backend
npm install
# Configurar variables de entorno en .env
npm start
```

### 2) Ejecutar Aplicación Flutter
```bash
cd ares_new
flutter pub get
flutter run
```

## 🎯 Usuarios de Prueba

### Master (Acceso Total)
- **Usuario:** Jesmillan
- **Contraseña:** [Configurar en instalación]

### Roles Disponibles
- **Master (99):** Acceso completo a todas las funciones
- **Administrador (92):** Gestión de usuarios y tickets
- **Técnico (50):** Gestión de tickets asignados
- **Cliente (42):** Creación y seguimiento de tickets propios

## 📊 Estructura del Proyecto

```
ares_new/
├── lib/
│   ├── main.dart              # Página principal y navegación
│   ├── services/
│   │   └── auth_service.dart  # Conexión con API backend
│   ├── tecnicos_page.dart     # Gestión de técnicos
│   ├── clientes_page.dart     # Gestión de clientes
│   └── edit_work_order_page.dart  # Edición de tickets
├── backend/
│   └── server.js             # API RESTful con Express
└── database/
    └── [archivos SQL]        # Estructura y datos iniciales
```

## 🔍 Características Especiales

- **Indicadores visuales** de estado (verde/rojo)
- **Menús contextuales** con acciones específicas por rol
- **Diálogos de confirmación** para acciones críticas
- **Mensajes de error** claros y específicos
- **Actualización automática** de listas después de operaciones
- **Navegación intuitiva** entre diferentes módulos

---

**Desarrollado con ❤️ para gestión eficiente de tickets técnicos**
