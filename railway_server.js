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
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '05621994',
  database: process.env.DB_NAME || 'flutter_login',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Opciones adicionales para Railway
  acquireTimeout: 60000,
  timeout: 60000,
  reconnect: true
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

// Iniciar servidor SIN ensureSchema
const startServer = async () => {
  try {
    console.log('🚀 Iniciando servidor...');
    
    // Probar conexión simple a la base de datos
    await pool.query('SELECT 1');
    console.log('✅ Base de datos conectada');
    
    app.listen(PORT, () => {
      console.log(`🌍 Servidor corriendo en puerto ${PORT}`);
      console.log(`📊 Health check: https://tu-app-production.up.railway.app/health`);
    });
  } catch (error) {
    console.error('❌ Error iniciando servidor:', error.message);
    // Iniciar servidor de todas formas para que Railway no falle
    app.listen(PORT, () => {
      console.log(`🚀 Servidor corriendo en puerto ${PORT} (sin BD)`);
    });
  }
};

startServer();

module.exports = app;
