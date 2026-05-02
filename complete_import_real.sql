-- IMPORTACIÓN COMPLETA DESDE LOCALHOST - DATOS REALES
-- Base de datos: flutter_login
-- Exportado: 02-05-2026

-- 1. CREAR TABLAS (adaptadas para Railway)
CREATE TABLE IF NOT EXISTS categoria (
  cod_categoria INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(30) NOT NULL,
  descripcion VARCHAR(50) DEFAULT NULL,
  fecha_creacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
  cod_cliente INT PRIMARY KEY AUTO_INCREMENT,
  usuario VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(50) NOT NULL,
  password VARCHAR(60) NOT NULL,
  correo VARCHAR(50) NOT NULL,
  num_telefono VARCHAR(14) NOT NULL,
  direccion VARCHAR(255) NOT NULL,
  cod_privilegio CHAR(2) NOT NULL DEFAULT '42',
  estado ENUM('Activo','Inactivo') DEFAULT 'Activo',
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS privilegios (
  cod_privilegio CHAR(2) PRIMARY KEY,
  rol VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS equipos (
  cod_equipos INT PRIMARY KEY AUTO_INCREMENT,
  tipo VARCHAR(30) NOT NULL,
  marca VARCHAR(30) NOT NULL,
  modelo VARCHAR(30) NOT NULL,
  serial VARCHAR(30) NOT NULL,
  cod_cliente INT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS tecnicos (
  cod_tecnico INT PRIMARY KEY AUTO_INCREMENT,
  usuario VARCHAR(30) NOT NULL UNIQUE,
  nombre VARCHAR(50) NOT NULL,
  password VARCHAR(60) NOT NULL,
  correo VARCHAR(50) DEFAULT NULL,
  num_telefono VARCHAR(13) DEFAULT NULL,
  cod_privilegio CHAR(2) DEFAULT '50',
  estado ENUM('Activo','Inactivo') DEFAULT 'Activo',
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ordenes_reclamos (
  cod_orden INT PRIMARY KEY AUTO_INCREMENT,
  cod_equipo INT DEFAULT NULL,
  cod_cliente INT DEFAULT NULL,
  descripcion_problema TEXT NOT NULL,
  diagnostico TEXT,
  estado VARCHAR(30) NOT NULL DEFAULT 'ABIERTO',
  prioridad VARCHAR(5) NOT NULL,
  tipo VARCHAR(13) NOT NULL,
  costo_estimado DECIMAL(10,2) DEFAULT NULL,
  costo_final DECIMAL(10,2) DEFAULT NULL,
  cod_categoria INT NOT NULL,
  cod_tecnico INT DEFAULT NULL,
  fecha_creacion TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_modificacion TIMESTAMP NULL DEFAULT NULL,
  correcciones TEXT,
  recomendaciones TEXT
);

-- 2. INSERTAR DATOS REALES
INSERT IGNORE INTO privilegios (cod_privilegio, rol) VALUES
('92', 'Administrador'),
('42', 'Cliente'),
('99', 'Master'),
('50', 'Tecnico');

INSERT IGNORE INTO categoria (cod_categoria, nombre, descripcion, fecha_creacion) VALUES
(1, 'Laptop', 'Computadoras portátiles y notebooks', '2026-05-01 05:46:27'),
(2, 'PC Escritorio', 'Computadoras de escritorio y torres', '2026-05-01 05:46:27');

INSERT IGNORE INTO clientes (cod_cliente, usuario, nombre, password, correo, num_telefono, direccion, cod_privilegio, estado, fecha_creacion) VALUES
(9, 'Prueba1', 'Maelo Ruiz', '$2b$10$PGx2MQOrDK1/wrpqSnTcFOlMZUaYt6NlCpqvUqso3NMAbAN1/u6EC', 'prueba@gmail.com', '+5804128417519', 'Guarenas', '42', 'Activo', '2026-04-29 23:18:00'),
(10, 'Prueba2', 'Bryan Moncada', '$2b$10$TKB4K8q6Pt5fHSKLln1Mc.IaNVXpa123bYrBUhsVxkYvQbrwn0o1W', 'prueba@test.com', '123456789', 'Sector 1', '42', 'Activo', '2026-05-01 18:20:54');

INSERT IGNORE INTO equipos (cod_equipos, tipo, marca, modelo, serial, cod_cliente) VALUES
(7, 'Laptop', 'Lenovo', 'Triniti', 'asd456s', 9),
(8, 'PC Escritorio', 'Vit', '3', 'asd561435d', 10);

INSERT IGNORE INTO tecnicos (cod_tecnico, usuario, nombre, password, correo, num_telefono, cod_privilegio, estado, fecha_creacion) VALUES
(4, 'Jesmillan', 'Jesus Millan', '$2b$10$DRXS3UVuIPugzv3sH6GKxuWRse//uLBTvKDfUm4ghDkRZRInOoWCm', 'jesusm0562@gmail.com', '123456789', '99', 'Activo', '2026-04-29 23:06:24'),
(15, 'Carduty', 'Carlos Malave', '$2b$10$PolJxSwqy36ha3NjVAoil.5Bs1iNM12F0cfZbcuOF9Ofp67XmYuGG', 'carlos_d_malave@test.com', '987654321', '50', 'Activo', '2026-04-30 02:42:10'),
(16, 'Marpaña', 'Mariana España', '$2b$10$op.6SONWM3ThMkM8o3Oib.n1JqxqNySoNshAy9Kxi9ELMLOXFrF7m', 'mariana_españa@test.com', '987654321', '92', 'Activo', '2026-04-30 02:42:29');

INSERT IGNORE INTO ordenes_reclamos (cod_orden, cod_equipo, cod_cliente, descripcion_problema, diagnostico, estado, prioridad, tipo, costo_estimado, costo_final, cod_categoria, cod_tecnico, fecha_creacion, fecha_modificacion, correcciones, recomendaciones) VALUES
(4, NULL, 9, 'La laptop no enciende y la pantalla está negra', NULL, 'ABIERTO', 'MEDIA', 'Reparación', NULL, NULL, 1, NULL, '2026-05-01 05:39:53', NULL, NULL, NULL),
(5, NULL, 9, 'Mantenimiento preventivo del equipo de escritorio', NULL, 'ABIERTO', 'BAJA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:39:59', NULL, NULL, NULL),
(7, NULL, 9, 'Se rompio la pantalla', 'Cambiar placa base.', 'EN DIAGNOSTICO', 'MEDIA', 'Reparación', '50.00', '70.00', 1, 15, '2026-05-01 05:47:00', '2026-05-01 19:29:26', 'Se cambio la placa, pero la pantalla sigue rota.', 'Cambiar la pantalla.'),
(8, NULL, 9, 'Se recalienta en poco tiempo', NULL, 'ABIERTO', 'ALTA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:47:11', NULL, NULL, NULL),
(9, NULL, 9, 'La laptop no enciende, pantalla negra', 'Se encuentra dañado el cable que va desde la placa a la pantalla de la laptop. Hay que cambiar la pantalla.', 'LISTO', 'ALTA', 'Reparación', '85.00', '90.00', 1, 15, '2026-05-01 05:49:42', '2026-05-01 23:48:30', 'Cambio de pantalla realizado.', 'No limpiar la pantalla con jabon ni alcohol.'),
(12, NULL, 9, 'Mantenimiento preventivo del equipo', NULL, 'ABIERTO', 'MEDIA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:57:38', NULL, NULL, NULL),
(41, NULL, 10, '1', 'Se realiza revision...', 'EN DIAGNOSTICO', 'BAJA', 'Reparación', '10.00', NULL, 1, NULL, '2026-05-01 22:27:56', '2026-05-01 23:56:44', 'No...', NULL),
(42, NULL, 10, '2', NULL, 'ABIERTO', 'ALTA', 'Reparación', NULL, NULL, 2, NULL, '2026-05-01 22:28:06', NULL, NULL, NULL);

-- 3. VERIFICACIÓN
SELECT 'Base de datos real importada exitosamente' as mensaje;
SELECT 'Categorías:' as tabla, COUNT(*) as registros FROM categoria
UNION ALL
SELECT 'Clientes:', COUNT(*) FROM clientes
UNION ALL
SELECT 'Privilegios:', COUNT(*) FROM privilegios
UNION ALL
SELECT 'Equipos:', COUNT(*) FROM equipos
UNION ALL
SELECT 'Técnicos:', COUNT(*) FROM tecnicos
UNION ALL
SELECT 'Órdenes:', COUNT(*) FROM ordenes_reclamos;
