# ARES - Aplicativo para Atención de Reclamos y Servicio Técnico

Aplicación móvil Flutter para la atención y gestion de reclamos por tickets, para realizar servicio técnico.

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

### Seguridad
- **Restricciones por rol:** Solo Master puede eliminar técnicos
- **Protección del usuario Master:** No puede ser inactivado ni modificado
- **Validación de sesión** en todas las operaciones
- **Manejo seguro de contraseñas** con bcrypt

### Roles Disponibles
- **Master:** Acceso completo a todas las funciones
- **Administrador:** Gestión de usuarios y tickets
- **Técnico:** Gestión de tickets asignados
- **Cliente:** Creación y seguimiento de tickets propios

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

## 📞 Soporte

Para soporte técnico o preguntas, contactar al desarrollador.

---

**Desarrollado con ❤️ usando Flutter**
