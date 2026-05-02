# 🚀 CONFIGURACIÓN COMPLETA - ARES Sistema de Gestión

## 📋 REQUISITOS PARA INSTALACIÓN

### 🖥️ SOFTWARE NECESARIO
- **Node.js 18+** (LTS recomendado)
- **MySQL 8.0+** o **MariaDB 10.5+**
- **Git** (para clonar repositorio)
- **Navegador web** (para administración)

---

## 🔧 PASO 1: CONFIGURACIÓN DE BASE DE DATOS

### 1.1 Instalar MySQL/MariaDB
```bash
# Windows (usando Chocolatey)
choco install mysql

# Ubuntu/Debian
sudo apt update
sudo apt install mysql-server

# macOS (usando Homebrew)
brew install mysql
```

### 1.2 Crear Base de Datos
```sql
-- Conectar a MySQL
mysql -u root -p

-- Crear base de datos
CREATE DATABASE ares_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear usuario (opcional, recomendado)
CREATE USER 'ares_user'@'localhost' IDENTIFIED BY 'tu_contraseña_segura';
GRANT ALL PRIVILEGES ON ares_system.* TO 'ares_user'@'localhost';
FLUSH PRIVILEGES;
```

### 1.3 Importar Estructura de Tablas
```bash
# Desde la carpeta database/
mysql -u root -p ares_system < categoria.sql
mysql -u root -p ares_system < clientes.sql
mysql -u root -p ares_system < equipos.sql
mysql -u root -p ares_system < tecnicos.sql
mysql -u root -p ares_system < ordenes_reclamos.sql
mysql -u root -p ares_system < privilegios.sql
mysql -u root -p ares_system < create_categoria_table.sql
```

---

## 🌐 PASO 2: CONFIGURACIÓN DEL BACKEND

### 2.1 Clonar Repositorio
```bash
git clone https://github.com/TheRainWolf/ARES.git
cd ARES/backend
```

### 2.2 Instalar Dependencias
```bash
npm install
```

### 2.3 Configurar Variables de Entorno
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar archivo .env con tu configuración
```

### 2.4 Archivo .env (Configuración)
```env
# Configuración de Base de Datos
DB_HOST=localhost
DB_USER=ares_user
DB_PASS=tu_contraseña_segura
DB_NAME=ares_system
DB_PORT=3306

# Configuración del Servidor
PORT=3000
JWT_SECRET=tu_clave_secreta_super_segura_12345

# Configuración adicional (opcional)
NODE_ENV=production
```

### 2.5 Iniciar Servidor Backend
```bash
# Para desarrollo
npm run dev

# Para producción
npm start

# Verificar funcionamiento
curl http://localhost:3000/health
```

---

## 📱 PASO 3: CONFIGURACIÓN DEL APK

### 3.1 Instalar APK en Dispositivo Android
1. **Habilitar instalación de fuentes desconocidas** en configuraciones
2. **Transferir APK** `ARES-APP-20260502.apk` al dispositivo
3. **Instalar APK** haciendo clic en el archivo

### 3.2 Configurar Conexión al Servidor

#### Opción A: Red Local (Wi-Fi)
```dart
// Editar en lib/services/auth_service.dart
static const String _baseUrl = 'http://192.168.1.100:3000';
```

#### Opción B: Servidor Externo
```dart
// Editar en lib/services/auth_service.dart
static const String _baseUrl = 'https://tu-dominio.com:3000';
```

### 3.3 Archivos a Modificar (si cambia IP)
- `lib/services/auth_service.dart`
- `lib/main.dart`
- `lib/register_page.dart`

---

## 🔐 PASO 4: CONFIGURACIÓN DE RED

### 4.1 Configuración de Firewall
```bash
# Windows (PowerShell como Administrador)
New-NetFirewallRule -DisplayName "ARES Backend" -Direction Inbound -Port 3000 -Protocol TCP -Action Allow

# Ubuntu/Debian
sudo ufw allow 3000/tcp

# macOS
sudo pfctl -f /etc/pf.conf
```

### 4.2 Verificar Conexión
```bash
# Desde el mismo servidor
curl http://localhost:3000/health

# Desde otro dispositivo en la red
curl http://192.168.1.100:3000/health
```

---

## 👤 PASO 5: USUARIOS DE PRUEBA

### 5.1 Conectar a Base de Datos y Agregar Usuarios
```sql
USE ares_system;

-- Usuario Master (acceso total)
INSERT INTO usuarios (usuario, nombre, correo, num_telefono, direccion, contraseña, tipo_usuario, estado) 
VALUES ('Jesmillan', 'Jesus Millan', 'jesus@ares.com', '123456789', 'Dirección Principal', 
        '$2b$10$encrypted_password_hash_here', 99, 'Activo');

-- Usuario Administrador
INSERT INTO usuarios (usuario, nombre, correo, num_telefono, direccion, contraseña, tipo_usuario, estado) 
VALUES ('admin', 'Administrador', 'admin@ares.com', '987654321', 'Dirección Admin', 
        '$2b$10$encrypted_password_hash_here', 92, 'Activo');

-- Usuario Técnico
INSERT INTO usuarios (usuario, nombre, correo, num_telefono, direccion, contraseña, tipo_usuario, estado) 
VALUES ('tecnico1', 'Técnico Principal', 'tecnico@ares.com', '555123456', 'Dirección Técnico', 
        '$2b$10$encrypted_password_hash_here', 50, 'Activo');

-- Usuario Cliente
INSERT INTO usuarios (usuario, nombre, correo, num_telefono, direccion, contraseña, tipo_usuario, estado) 
VALUES ('cliente1', 'Cliente Ejemplo', 'cliente@ares.com', '555987654', 'Dirección Cliente', 
        '$2b$10$encrypted_password_hash_here', 42, 'Activo');
```

### 5.2 Contraseñas por Defecto
- **Master:** `master123`
- **Administrador:** `admin123`
- **Técnico:** `tecnico123`
- **Cliente:** `cliente123`

---

## 🚀 PASO 6: VERIFICACIÓN FINAL

### 6.1 Checklist de Verificación
- [ ] **Base de datos creada** y tablas importadas
- [ ] **Backend corriendo** en puerto 3000
- [ ] **Health check** funcionando: `http://localhost:3000/health`
- [ ] **Firewall configurado** para puerto 3000
- [ ] **APK instalado** en dispositivo Android
- [ ] **IP del servidor** configurada en APK
- [ ] **Conexión exitosa** entre APK y backend
- [ ] **Login funcional** con usuarios de prueba

### 6.2 Pruebas Funcionales
1. **Login con usuario Master**
2. **Crear nuevo técnico**
3. **Crear cliente**
4. **Crear ticket**
5. **Asignar técnico a ticket**
6. **Cambiar estado de ticket**
7. **Probar diferentes roles**

---

## 🆘 SOLUCIÓN DE PROBLEMAS

### Problemas Comunes

#### "No se puede conectar al servidor"
- **Verificar que backend esté corriendo:** `ps aux | grep node`
- **Verificar puerto:** `netstat -an | grep 3000`
- **Verificar IP:** `ip addr show` (Linux) o `ipconfig` (Windows)

#### "Error de base de datos"
- **Verificar credenciales** en archivo .env
- **Verificar que base de datos exista:** `SHOW DATABASES;`
- **Verificar permisos del usuario**

#### "Login fallido"
- **Verificar que usuario exista** en base de datos
- **Verificar que contraseña esté encriptada** con bcrypt
- **Verificar que usuario esté activo**

---

## 📞 SOPORTE

### Información de Contacto
- **Repositorio:** https://github.com/TheRainWolf/ARES
- **Documentación:** Ver README.md
- **Backend Health Check:** `http://localhost:3000/health`

### Logs Importantes
- **Backend logs:** Consola donde se ejecuta `npm start`
- **Database logs:** `/var/log/mysql/error.log` (Linux)
- **Application logs:** Revisar consola del servidor Node.js

---

## 🎯 RESUMEN FINAL

**Componentes necesarios:**
1. ✅ **MySQL/MariaDB** con base de datos `ares_system`
2. ✅ **Backend Node.js** corriendo en puerto 3000
3. ✅ **APK Android** con IP correcta del servidor
4. ✅ **Red configurada** para permitir conexiones

**Tiempo estimado de configuración:** 15-30 minutos

---

**🚀 Una vez configurado, el sistema ARES estará completamente funcional para gestión de tickets técnicos.**
