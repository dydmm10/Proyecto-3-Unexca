require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cors());

// Configurar puerto para Railway
const PORT = process.env.PORT || 3000;

// Middleware para logging de requests
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
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
  queueLimit: 0
});

// Función de inicialización simplificada para Railway
async function initializeDatabase() {
  try {
    console.log('🔗 Conectando a la base de datos...');
    
    // Probar conexión
    await pool.query('SELECT 1');
    console.log('✅ Conexión a base de datos exitosa');
    
    // Verificar tablas básicas
    const [tables] = await pool.query('SHOW TABLES');
    console.log('📋 Tablas encontradas:', tables.map(t => Object.values(t)[0]));
    
    return true;
  } catch (error) {
    console.error('❌ Error de base de datos:', error.message);
    // No detener el servidor si la BD falla
    return false;
  }
}

// Endpoints básicos para verificar funcionamiento
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    port: PORT 
  });
});

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

// Endpoint para obtener órdenes (simplificado)
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

// Iniciar servidor
initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
    console.log(`🌍 URL: https://tu-app-production.up.railway.app`);
  });
}).catch((error) => {
  console.error('❌ Error al iniciar servidor:', error.message);
  // Iniciar servidor de todas formas
  app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT} (sin BD)`);
  });
});

module.exports = app;
