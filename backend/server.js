console.log('🚀 SERVIDOR RAILWAY - NUEVA VERSIÓN SIN ENSURESCHEMA');
require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cors());

// Configurar puerto para Railway
const PORT = process.env.PORT || 3000;

// Logging simple
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Si el host incluye puerto (formato host:port), extraer el puerto
let dbHost = process.env.DB_HOST || 'localhost';
let dbPort = process.env.DB_PORT || 3306;

if (dbHost.includes(':')) {
  const [host, port] = dbHost.split(':');
  dbHost = host;
  dbPort = parseInt(port) || 3306;
}

// Configuración de base de datos para Railway
const pool = mysql.createPool({
  host: dbHost,
  port: dbPort,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'vnrzzSYkAJtQqMIukCRGGonSELOkXYwf',
  database: process.env.DB_NAME || 'railway',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Configuración SSL para Railway
  ssl: {
    rejectUnauthorized: false
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'OK', 
      timestamp: new Date().toISOString(),
      port: PORT,
      database: 'connected'
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'ERROR', 
      timestamp: new Date().toISOString(),
      port: PORT,
      database: 'disconnected',
      error: error.message
    });
  }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { usuario, password } = req.body;
    
    if (!usuario || !password) {
      return res.status(400).json({ msg: 'Usuario y contraseña requeridos' });
    }

    // Buscar en técnicos
    const [tecnicoRows] = await pool.query(
      'SELECT * FROM tecnicos WHERE usuario = ?',
      [usuario]
    );

    if (tecnicoRows.length > 0) {
      const tecnico = tecnicoRows[0];
      const isValid = await bcrypt.compare(password, tecnico.password);
      
      if (isValid) {
        const token = jwt.sign(
          { userId: tecnico.cod_tecnico, rol: 'tecnico' },
          process.env.JWT_SECRET || 'secret',
          { expiresIn: '24h' }
        );
        
        return res.json({
          token,
          rol: 'tecnico',
          tipo: 'tecnico',
          nombre: tecnico.nombre,
          userId: tecnico.cod_tecnico,
          cod_privilegio: tecnico.cod_privilegio
        });
      }
    }

    // Buscar en clientes
    const [clienteRows] = await pool.query(
      'SELECT * FROM clientes WHERE usuario = ?',
      [usuario]
    );

    if (clienteRows.length > 0) {
      const cliente = clienteRows[0];
      const isValid = await bcrypt.compare(password, cliente.password);
      
      if (isValid) {
        const token = jwt.sign(
          { userId: cliente.cod_cliente, rol: 'cliente' },
          process.env.JWT_SECRET || 'secret',
          { expiresIn: '24h' }
        );
        
        return res.json({
          token,
          rol: 'cliente',
          tipo: 'cliente',
          nombre: cliente.nombre,
          userId: cliente.cod_cliente,
          cod_privilegio: cliente.cod_privilegio
        });
      }
    }

    return res.status(401).json({ msg: 'Credenciales inválidas' });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ msg: 'Error del servidor' });
  }
});

// Endpoint para órdenes de trabajo
app.get('/api/ordenes-trabajo', async (req, res) => {
  try {
    const { cod_cliente } = req.query;
    
    let query = `
      SELECT o.*, c.nombre AS cliente_nombre, cat.nombre AS category_name
      FROM ordenes_reclamos o
      LEFT JOIN clientes c ON o.cod_cliente = c.cod_cliente
      LEFT JOIN categoria cat ON o.cod_categoria = cat.cod_categoria
      WHERE o.tipo = 'Reparación'
    `;
    
    const params = [];
    
    // Si se especifica cod_cliente, filtrar por ese cliente
    if (cod_cliente) {
      query += ' AND o.cod_cliente = ?';
      params.push(cod_cliente);
    }
    
    query += ' ORDER BY o.fecha_creacion DESC';
    
    const [rows] = await pool.query(query, params);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo órdenes:', error);
    res.status(500).json({ msg: 'Error obteniendo órdenes' });
  }
});

// Endpoint para órdenes de mantenimiento
app.get('/api/ordenes-mantenimiento', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT o.*, c.nombre AS cliente_nombre, cat.nombre AS category_name
      FROM ordenes_reclamos o
      LEFT JOIN clientes c ON o.cod_cliente = c.cod_cliente
      LEFT JOIN categoria cat ON o.cod_categoria = cat.cod_categoria
      WHERE o.tipo = 'Mantenimiento'
      ORDER BY o.fecha_creacion DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo mantenimientos:', error);
    res.status(500).json({ msg: 'Error obteniendo mantenimientos' });
  }
});

// Endpoint para detalles de orden
app.get('/api/ordenes-reclamos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Query con JOIN de categoria para obtener el nombre
    const [rows] = await pool.query(`
      SELECT 
        o.*,
        cat.nombre as category_name
      FROM ordenes_reclamos o
      LEFT JOIN categoria cat ON o.cod_categoria = cat.cod_categoria
      WHERE o.cod_orden = ?
    `, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Orden de reclamo no encontrada' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Error obteniendo detalles de orden:', error);
    res.status(500).json({ msg: 'Error obteniendo detalles de orden', error: error.message });
  }
});

// Endpoint para obtener técnicos
app.get('/api/tecnicos', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT t.*, p.rol 
      FROM tecnicos t
      LEFT JOIN privilegios p ON t.cod_privilegio = p.cod_privilegio
      WHERE t.estado = 'Activo'
      ORDER BY t.fecha_creacion DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo técnicos:', error);
    res.status(500).json({ msg: 'Error obteniendo técnicos' });
  }
});

// Endpoint para obtener clientes
app.get('/api/clientes', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT c.*, p.rol 
      FROM clientes c
      LEFT JOIN privilegios p ON c.cod_privilegio = p.cod_privilegio
      WHERE c.estado = 'Activo'
      ORDER BY c.fecha_creacion DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo clientes:', error);
    res.status(500).json({ msg: 'Error obteniendo clientes' });
  }
});

// Endpoint para obtener equipos
app.get('/api/equipos', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT e.*, c.nombre as cliente_nombre
      FROM equipos e
      LEFT JOIN clientes c ON e.cod_cliente = c.cod_cliente
      ORDER BY e.cod_equipos DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo equipos:', error);
    res.status(500).json({ msg: 'Error obteniendo equipos' });
  }
});

// Endpoint para obtener categorías
app.get('/api/categorias', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT * FROM categoria
      ORDER BY cod_categoria ASC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error obteniendo categorías:', error);
    res.status(500).json({ msg: 'Error obteniendo categorías' });
  }
});

// Endpoint para crear orden de trabajo
app.post('/api/ordenes-reclamos', async (req, res) => {
  try {
    const {
      cod_categoria,
      descripcion_problema,
      prioridad,
      tipo = 'Reparación',
      cod_cliente,
      cod_equipo = null
    } = req.body;

    // Validar campos requeridos
    if (!cod_categoria || !descripcion_problema || !prioridad || !cod_cliente) {
      return res.status(400).json({ 
        msg: 'Faltan campos requeridos: cod_categoria, descripcion_problema, prioridad, cod_cliente' 
      });
    }

    // Insertar nueva orden
    const [result] = await pool.query(`
      INSERT INTO ordenes_reclamos 
      (cod_categoria, descripcion_problema, prioridad, tipo, cod_cliente, cod_equipo, estado)
      VALUES (?, ?, ?, ?, ?, ?, 'ABIERTA')
    `, [cod_categoria, descripcion_problema, prioridad, tipo, cod_cliente, cod_equipo]);

    res.status(201).json({
      message: 'Orden de trabajo creada exitosamente',
      cod_orden: result.insertId,
      data: {
        cod_orden: result.insertId,
        cod_categoria,
        descripcion_problema,
        prioridad,
        tipo,
        cod_cliente,
        cod_equipo,
        estado: 'ABIERTA'
      }
    });

  } catch (error) {
    console.error('Error creando orden:', error);
    res.status(500).json({ 
      msg: 'Error creando orden de trabajo',
      error: error.message 
    });
  }
});

// Endpoint para importar base de datos
app.post('/api/import-database', async (req, res) => {
  try {
    console.log('🚀 Iniciando importación de base de datos...');
    
    // Borrar tablas existentes para recrear con estructura correcta
    await pool.query('DROP TABLE IF EXISTS ordenes_reclamos');
    await pool.query('DROP TABLE IF EXISTS equipos');
    await pool.query('DROP TABLE IF EXISTS tecnicos');
    await pool.query('DROP TABLE IF EXISTS clientes');
    await pool.query('DROP TABLE IF EXISTS categoria');
    await pool.query('DROP TABLE IF EXISTS privilegios');
    
    // Crear tablas con estructura correcta
    await pool.query(`
      CREATE TABLE IF NOT EXISTS categoria (
        cod_categoria INT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        descripcion TEXT,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
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
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS privilegios (
        cod_privilegio CHAR(2) PRIMARY KEY,
        rol VARCHAR(30) NOT NULL UNIQUE
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS equipos (
        cod_equipos INT PRIMARY KEY AUTO_INCREMENT,
        tipo VARCHAR(30) NOT NULL,
        marca VARCHAR(30) NOT NULL,
        modelo VARCHAR(30) NOT NULL,
        serial VARCHAR(30) NOT NULL,
        cod_cliente INT DEFAULT NULL
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS tecnicos (
        cod_tecnico INT PRIMARY KEY AUTO_INCREMENT,
        usuario VARCHAR(50) UNIQUE NOT NULL,
        nombre VARCHAR(100) NOT NULL,
        password VARCHAR(255) NOT NULL,
        correo VARCHAR(50) DEFAULT NULL,
        num_telefono VARCHAR(13) DEFAULT NULL,
        cod_privilegio CHAR(2) DEFAULT '50',
        estado VARCHAR(20) DEFAULT 'Activo',
        fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
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
      )
    `);

    // Insertar datos básicos (solo si no existen)
    await pool.query(`
      INSERT IGNORE INTO privilegios (cod_privilegio, rol) VALUES
      ('92', 'Administrador'),
      ('42', 'Cliente'),
      ('99', 'Master'),
      ('50', 'Tecnico')
    `);

    await pool.query(`
      INSERT IGNORE INTO categoria (cod_categoria, nombre, descripcion) VALUES
      (1, 'Laptop', 'Computadoras portátiles y notebooks'),
      (2, 'PC Escritorio', 'Computadoras de escritorio y torres')
    `);

    await pool.query(`
      INSERT IGNORE INTO clientes (cod_cliente, usuario, nombre, password, correo, num_telefono, direccion, cod_privilegio, estado, fecha_creacion) VALUES
      (9, 'Prueba1', 'Maelo Ruiz', '$2b$10$PGx2MQOrDK1/wrpqSnTcFOlMZUaYt6NlCpqvUqso3NMAbAN1/u6EC', 'prueba@gmail.com', '+5804128417519', 'Guarenas', '42', 'Activo', '2026-04-29 19:18:00'),
      (10, 'Prueba2', 'Bryan Moncada', '$2b$10$TKB4K8q6Pt5fHSKLln1Mc.IaNVXpa123bYrBUhsVxkYvQbrwn0o1W', 'prueba@test.com', '123456789', 'Sector 1', '42', 'Activo', '2026-05-01 14:20:54')
    `);

    await pool.query(`
      INSERT IGNORE INTO tecnicos (cod_tecnico, usuario, nombre, password, correo, num_telefono, cod_privilegio, estado, fecha_creacion) VALUES
      (4, 'Jesmillan', 'Jesus Millan', '$2b$10$DRXS3UVuIPugzv3sH6GKxuWRse//uLBTvKDfUm4ghDkRZRInOoWCm', 'jesusm0562@gmail.com', '123456789', '99', 'Activo', '2026-04-29 23:06:24'),
      (15, 'Carduty', 'Carlos Malave', '$2b$10$PolJxSwqy36ha3NjVAoil.5Bs1iNM12F0cfZbcuOF9Ofp67XmYuGG', 'carlos_d_malave@test.com', '987654321', '50', 'Activo', '2026-04-30 02:42:10'),
      (16, 'Marpaña', 'Mariana España', '$2b$10$op.6SONWM3ThMkM8o3Oib.n1JqxqNySoNshAy9Kxi9ELMLOXFrF7m', 'mariana_españa@test.com', '987654321', '92', 'Activo', '2026-04-30 02:42:29')
    `);

    // Insertar equipos reales
    await pool.query(`
      INSERT IGNORE INTO equipos (cod_equipos, tipo, marca, modelo, serial, cod_cliente) VALUES
      (7, 'Laptop', 'Lenovo', 'Triniti', 'asd456s', 9),
      (8, 'PC Escritorio', 'Vit', '3', 'asd561435d', 10)
    `);

    // Insertar órdenes reales
    await pool.query(`
      INSERT IGNORE INTO ordenes_reclamos (cod_orden, cod_equipo, cod_cliente, descripcion_problema, diagnostico, estado, prioridad, tipo, costo_estimado, costo_final, cod_categoria, cod_tecnico, fecha_creacion, fecha_modificacion, correcciones, recomendaciones) VALUES
      (4, NULL, 9, 'La laptop no enciende y la pantalla está negra', NULL, 'ABIERTO', 'MEDIA', 'Reparación', NULL, NULL, 1, NULL, '2026-05-01 05:39:53', NULL, NULL, NULL),
      (5, NULL, 9, 'Mantenimiento preventivo del equipo de escritorio', NULL, 'ABIERTO', 'BAJA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:39:59', NULL, NULL, NULL),
      (7, NULL, 9, 'Se rompio la pantalla', 'Cambiar placa base.', 'EN DIAGNOSTICO', 'MEDIA', 'Reparación', '50.00', '70.00', 1, 15, '2026-05-01 05:47:00', '2026-05-01 19:29:26', 'Se cambio la placa, pero la pantalla sigue rota.', 'Cambiar la pantalla.'),
      (8, NULL, 9, 'Se recalienta en poco tiempo', NULL, 'ABIERTO', 'ALTA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:47:11', NULL, NULL, NULL),
      (9, NULL, 9, 'La laptop no enciende, pantalla negra', 'Se encuentra dañado el cable que va desde la placa a la pantalla de la laptop. Hay que cambiar la pantalla.', 'LISTO', 'ALTA', 'Reparación', '85.00', '90.00', 1, 15, '2026-05-01 05:49:42', '2026-05-01 23:48:30', 'Cambio de pantalla realizado.', 'No limpiar la pantalla con jabon ni alcohol.'),
      (12, NULL, 9, 'Mantenimiento preventivo del equipo', NULL, 'ABIERTO', 'MEDIA', 'Mantenimiento', NULL, NULL, 2, NULL, '2026-05-01 05:57:38', NULL, NULL, NULL),
      (41, NULL, 10, '1', 'Se realiza revision...', 'EN DIAGNOSTICO', 'BAJA', 'Reparación', '10.00', NULL, 1, NULL, '2026-05-01 22:27:56', '2026-05-01 23:56:44', 'No...', NULL),
      (42, NULL, 10, '2', NULL, 'ABIERTO', 'ALTA', 'Reparación', NULL, NULL, 2, NULL, '2026-05-01 22:28:06', NULL, NULL, NULL)
    `);

    // Verificar
    const [result] = await pool.query(`
      SELECT 'Categorías:' as tabla, COUNT(*) as registros FROM categoria
      UNION ALL
      SELECT 'Clientes:', COUNT(*) FROM clientes
      UNION ALL
      SELECT 'Privilegios:', COUNT(*) FROM privilegios
      UNION ALL
      SELECT 'Técnicos:', COUNT(*) FROM tecnicos
      UNION ALL
      SELECT 'Equipos:', COUNT(*) FROM equipos
      UNION ALL
      SELECT 'Órdenes:', COUNT(*) FROM ordenes_reclamos
    `);

    console.log('✅ Base de datos importada exitosamente');
    res.json({ 
      message: 'Base de datos importada exitosamente',
      data: result
    });

  } catch (error) {
    console.error('❌ Error en importación:', error);
    res.status(500).json({ 
      error: error.message,
      details: error.sqlMessage
    });
  }
});

// Iniciar servidor SIN ensureSchema
const startServer = async () => {
  try {
    console.log('🚀 Iniciando servidor SIN ensureSchema...');
    
    // Probar conexión simple a la base de datos
    await pool.query('SELECT 1');
    console.log('✅ Base de datos conectada');
    
    app.listen(PORT, () => {
      console.log(`🌍 Servidor corriendo en puerto ${PORT}`);
      console.log(`📊 Health check disponible`);
      console.log(`📊 Import database: POST /api/import-database`);
    });
  } catch (error) {
    console.error('❌ Error iniciando servidor:', error.message);
    // Iniciar servidor de todas formas para que Railway no falle
    app.listen(PORT, () => {
      console.log(`🚀 Servidor corriendo en puerto ${PORT} (sin BD)`);
    });
  }
};

// Manejar cierre graceful
process.on('SIGTERM', () => {
  console.log('📡 Recibido SIGTERM - cerrando gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('📡 Recibido SIGINT - cerrando gracefully');
  process.exit(0);
});

startServer();

module.exports = app;
