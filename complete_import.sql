-- COMPLETO - IMPORTACIÓN BASE DE DATOS UNEXCA PARA RAILWAY
-- Copia y pega todo este contenido en tu cliente MySQL

-- 1. CREAR TABLAS
CREATE TABLE IF NOT EXISTS categoria (
  cod_categoria INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
  cod_cliente INT PRIMARY KEY AUTO_INCREMENT,
  usuario VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  correo VARCHAR(100),
  num_telefono VARCHAR(20),
  direccion TEXT,
  cod_privilegio CHAR(2),
  estado VARCHAR(20) DEFAULT 'Activo',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS privilegios (
  cod_privilegio CHAR(2) PRIMARY KEY,
  rol VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS equipos (
  cod_equipo INT PRIMARY KEY AUTO_INCREMENT,
  marca VARCHAR(50),
  modelo VARCHAR(50),
  descripcion TEXT
);

CREATE TABLE IF NOT EXISTS tecnicos (
  cod_tecnico INT PRIMARY KEY AUTO_INCREMENT,
  usuario VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  cod_privilegio CHAR(2),
  estado VARCHAR(20) DEFAULT 'Activo',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ordenes_reclamos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cod_categoria INT,
  descripcion_problema TEXT NOT NULL,
  prioridad VARCHAR(20) NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'ABIERTA',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  cod_cliente INT,
  cod_equipo INT,
  diagnostico TEXT,
  costo_estimado DECIMAL(10,2),
  costo_final DECIMAL(10,2),
  cod_tecnico INT,
  fecha_modificacion TIMESTAMP,
  correcciones TEXT,
  recomendaciones TEXT,
  tipo VARCHAR(20)
);

-- 2. INSERTAR DATOS BÁSICOS
INSERT INTO privilegios (cod_privilegio, rol) VALUES
('92', 'Administrador'),
('42', 'Cliente'),
('99', 'Master'),
('50', 'Tecnico');

INSERT INTO categoria (cod_categoria, nombre, descripcion) VALUES
(1, 'Laptop', 'Computadoras portátiles y notebooks'),
(2, 'PC Escritorio', 'Computadoras de escritorio y torres');

INSERT INTO clientes (cod_cliente, usuario, nombre, password, correo, num_telefono, direccion, cod_privilegio, estado, fecha_creacion) VALUES
(9, 'Prueba1', 'Maelo Ruiz', '$2b$10$PGx2MQOrDK1/wrpqSnTcFOlMZUaYt6NlCpqvUqso3NMAbAN1/u6EC', 'prueba@gmail.com', '+5804128417519', 'Guarenas', '42', 'Activo', '2026-04-29 19:18:00'),
(10, 'Prueba2', 'Bryan Moncada', '$2b$10$TKB4K8q6Pt5fHSKLln1Mc.IaNVXpa123bYrBUhsVxkYvQbrwn0o1W', 'prueba@test.com', '123456789', 'Sector 1', '42', 'Activo', '2026-05-01 14:20:54');

INSERT INTO tecnicos (cod_tecnico, usuario, nombre, password, cod_privilegio, estado, fecha_creacion) VALUES
(1, 'Jesmillan', 'Jesus Millan', '$2b$10$YourHashedPasswordHere', '99', 'Activo', '2026-05-01 00:00:00'),
(2, 'Carduty', 'Carlos Duran', '$2b$10$YourHashedPasswordHere', '92', 'Activo', '2026-05-01 00:00:00');

-- 3. VERIFICACIÓN
SELECT 'Base de datos importada exitosamente' as mensaje;
SELECT 'Categorías:' as tabla, COUNT(*) as registros FROM categoria
UNION ALL
SELECT 'Clientes:', COUNT(*) FROM clientes  
UNION ALL
SELECT 'Privilegios:', COUNT(*) FROM privilegios
UNION ALL
SELECT 'Técnicos:', COUNT(*) FROM tecnicos;

-- 4. USUARIOS DE PRUEBA
-- Prueba1 / 123456 (Cliente)
-- Prueba2 / 123456 (Cliente)
-- Jesmillan / 05621994 (Master)
-- Carduty / cordiforever (Administrador)
