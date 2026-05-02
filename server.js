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

// Configuración de base de datos para Railway
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
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
    const [rows] = await pool.query(`
      SELECT o.*, c.nombre AS cliente_nombre, cat.nombre AS category_name
      FROM ordenes_reclamos o
      LEFT JOIN clientes c ON o.cod_cliente = c.cod_cliente
      LEFT JOIN categoria cat ON o.cod_categoria = cat.cod_categoria
      WHERE o.tipo = 'Reparación'
      ORDER BY o.fecha_creacion DESC
    `);
    
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
    
    const [rows] = await pool.query(`
      SELECT
        o.*,
        c.nombre AS cliente_nombre,
        c.email AS cliente_correo,
        c.num_telefono AS cliente_telefono,
        cat.nombre AS category_name,
        e.marca AS equipo_marca,
        e.modelo AS equipo_modelo,
        t.nombre AS tecnico_nombre
      FROM ordenes_reclamos o
      LEFT JOIN clientes c ON o.cod_cliente = c.cod_cliente
      LEFT JOIN categoria cat ON o.cod_categoria = cat.cod_categoria
      LEFT JOIN equipos e ON o.cod_equipo = e.cod_equipo
      LEFT JOIN tecnicos t ON o.cod_tecnico = t.cod_tecnico
      WHERE o.id = ?
    `, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Orden de reclamo no encontrada' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Error obteniendo detalles de orden:', error);
    res.status(500).json({ msg: 'Error obteniendo detalles de orden' });
  }
});

// Endpoint para importar base de datos
app.post('/api/import-database', async (req, res) => {
  try {
    console.log('🚀 Iniciando importación de base de datos...');
    
    // Crear tablas
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
        cod_equipo INT PRIMARY KEY AUTO_INCREMENT,
        marca VARCHAR(50),
        modelo VARCHAR(50),
        descripcion TEXT
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS tecnicos (
        cod_tecnico INT PRIMARY KEY AUTO_INCREMENT,
        usuario VARCHAR(50) UNIQUE NOT NULL,
        nombre VARCHAR(100) NOT NULL,
        password VARCHAR(255) NOT NULL,
        cod_privilegio CHAR(2),
        estado VARCHAR(20) DEFAULT 'Activo',
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
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
      )
    `);

    // Insertar datos básicos
    await pool.query(`
      INSERT INTO privilegios (cod_privilegio, rol) VALUES
      ('92', 'Administrador'),
      ('42', 'Cliente'),
      ('99', 'Master'),
      ('50', 'Tecnico')
    `);

    await pool.query(`
      INSERT INTO categoria (cod_categoria, nombre, descripcion) VALUES
      (1, 'Laptop', 'Computadoras portátiles y notebooks'),
      (2, 'PC Escritorio', 'Computadoras de escritorio y torres')
    `);

    await pool.query(`
      INSERT INTO clientes (cod_cliente, usuario, nombre, password, correo, num_telefono, direccion, cod_privilegio, estado, fecha_creacion) VALUES
      (9, 'Prueba1', 'Maelo Ruiz', '$2b$10$PGx2MQOrDK1/wrpqSnTcFOlMZUaYt6NlCpqvUqso3NMAbAN1/u6EC', 'prueba@gmail.com', '+5804128417519', 'Guarenas', '42', 'Activo', '2026-04-29 19:18:00'),
      (10, 'Prueba2', 'Bryan Moncada', '$2b$10$TKB4K8q6Pt5fHSKLln1Mc.IaNVXpa123bYrBUhsVxkYvQbrwn0o1W', 'prueba@test.com', '123456789', 'Sector 1', '42', 'Activo', '2026-05-01 14:20:54')
    `);

    await pool.query(`
      INSERT INTO tecnicos (cod_tecnico, usuario, nombre, password, cod_privilegio, estado, fecha_creacion) VALUES
      (1, 'Jesmillan', 'Jesus Millan', '$2b$10$YourHashedPasswordHere', '99', 'Activo', '2026-05-01 00:00:00'),
      (2, 'Carduty', 'Carlos Duran', '$2b$10$YourHashedPasswordHere', '92', 'Activo', '2026-05-01 00:00:00')
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
