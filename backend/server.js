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

// Middleware para logging de requests
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '05621994',
  database: process.env.DB_NAME || 'flutter_login',
  waitForConnections: true,
  connectionLimit: 10,
});

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ordenes_reclamos (
      cod_orden INT AUTO_INCREMENT PRIMARY KEY,
      cod_categoria VARCHAR(100) NOT NULL,
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
      recomendaciones TEXT
    )
  `);

  // Eliminar tabla equipments si existe - ahora se usa la tabla equipos existente
  await pool.query('DROP TABLE IF EXISTS equipments');

  // Crear tabla Privilegios
  await pool.query(`
    CREATE TABLE IF NOT EXISTS Privilegios (
      cod_privilegio CHAR(2) PRIMARY KEY,
      rol VARCHAR(30) NOT NULL UNIQUE
    )
  `);

  // Eliminar privilegios antiguos y insertar los nuevos códigos
  await pool.query("DELETE FROM Privilegios WHERE cod_privilegio IN ('A1', 'T1', 'T2', 'S1')");
  
  // Insertar privilegios correctos
  await pool.query(`
    INSERT IGNORE INTO Privilegios (cod_privilegio, rol) VALUES
    ('99', 'Master'),
    ('92', 'Administrador'),
    ('50', 'Tecnico'),
    ('42', 'Cliente')
  `);

  // Actualizar técnicos que usaban privilegios antiguos
  await pool.query(`
    UPDATE tecnicos SET cod_privilegio = '92' WHERE cod_privilegio = 'A1'
  `);
  await pool.query(`
    UPDATE tecnicos SET cod_privilegio = '50' WHERE cod_privilegio = 'T1'
  `);
  await pool.query(`
    UPDATE tecnicos SET cod_privilegio = '50' WHERE cod_privilegio = 'T2'
  `);
  await pool.query(`
    UPDATE tecnicos SET cod_privilegio = '50' WHERE cod_privilegio = 'S1'
  `);

  // Actualizar clientes que usaban privilegios antiguos
  await pool.query(`
    UPDATE clientes SET cod_privilegio = '42' WHERE cod_privilegio IN ('A1', 'T1', 'T2', 'S1')
  `);

  console.log('✅ Privilegios antiguos eliminados y registros actualizados');

  // Crear tabla categoria
  await pool.query(`
    CREATE TABLE IF NOT EXISTS categoria (
      cod_categoria INT(10) PRIMARY KEY AUTO_INCREMENT,
      nombre VARCHAR(30) NOT NULL,
      descripcion VARCHAR(50),
      fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  // Insertar categorías iniciales si no existen
  await pool.query(`
    INSERT IGNORE INTO categoria (cod_categoria, nombre, descripcion) VALUES
    (1, 'Laptop', 'Computadoras portátiles y notebooks'),
    (2, 'PC Escritorio', 'Computadoras de escritorio y torres')
  `);

  // Verificar si existe la columna tipo en ordenes_reclamos
  try {
    await pool.query(`SELECT tipo FROM ordenes_reclamos LIMIT 1`);
  } catch (e) {
    // Si no existe, agregar la columna tipo
    await pool.query(`
      ALTER TABLE ordenes_reclamos 
      ADD COLUMN tipo VARCHAR(12) DEFAULT 'reclamo' AFTER prioridad
    `);
    console.log('✅ Columna "tipo" agregada a ordenes_reclamos');
  }

  // Verificar si existe la columna cod_categoria en ordenes_reclamos
  try {
    await pool.query(`SELECT cod_categoria FROM ordenes_reclamos LIMIT 1`);
  } catch (e) {
    // Si no existe, agregar la columna cod_categoria
    await pool.query(`
      ALTER TABLE ordenes_reclamos 
      ADD COLUMN cod_categoria INT(10) AFTER tipo
    `);
    console.log('✅ Columna "cod_categoria" agregada a ordenes_reclamos');
  }

  // Crear/actualizar tabla tecnicos con la nueva estructura
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tecnicos (
      cod_tecnico INT AUTO_INCREMENT PRIMARY KEY,
      nombre VARCHAR(100) NOT NULL,
      correo VARCHAR(120) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      num_telefono VARCHAR(20),
      privilegio CHAR(2),
      fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (privilegio) REFERENCES Privilegios(cod_privilegio)
    )
  `);
}

app.get('/api/users/exists', async (req, res) => {
  const correo = String(req.query.email || '').trim();
  if (!correo) return res.status(400).json({ msg: 'Email requerido' });

  try {
    const [rows] = await pool.query('SELECT cod_cliente FROM clientes WHERE correo = ? LIMIT 1', [correo]);
    return res.json({ exists: rows.length > 0 });
  } catch (e) {
    console.error('Exists error:', e.message);
    return res.status(500).json({ msg: 'Error verificando email' });
  }
});

app.post('/api/register', async (req, res) => {
  const { usuario, email, password, nombre, num_telefono, direccion, tipo_usuario, cod_privilegio } = req.body;
  
  if (!usuario || !password || !tipo_usuario) {
    return res.status(400).json({ msg: 'Usuario, password y tipo de usuario son requeridos' });
  }

  const hashed = await bcrypt.hash(password, 10);
  
  try {
    if (tipo_usuario === 'cliente') {
      // Crear cliente
      await pool.query(
        'INSERT INTO clientes (usuario, correo, password, nombre, num_telefono, direccion, cod_privilegio) VALUES (?, ?, ?, ?, ?, ?, ?)', 
        [usuario, email || null, hashed, nombre || '', num_telefono || '', direccion || '', '42']
      );
      res.json({ msg: 'Cliente creado exitosamente' });
    } else if (tipo_usuario === 'tecnico') {
      // Crear técnico con el privilegio especificado
      const privilegio = cod_privilegio || '50'; // Por defecto Tecnico si no se especifica
      await pool.query(
        'INSERT INTO tecnicos (usuario, correo, password, nombre, num_telefono, cod_privilegio) VALUES (?, ?, ?, ?, ?, ?)', 
        [usuario, email || null, hashed, nombre || '', num_telefono || '', privilegio]
      );
      res.json({ msg: 'Tecnico creado exitosamente' });
    } else {
      return res.status(400).json({ msg: 'Tipo de usuario inválido' });
    }
  } catch (e) {
    console.error('Register error:', e.message);
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ msg: 'El usuario ya está registrado' });
    }
    return res.status(500).json({ msg: 'Error al crear usuario' });
  }
});

app.post('/api/login', async (req, res) => {
  const { usuario, password } = req.body;
  console.log(`🔍 Login attempt - Usuario: "${usuario}", Contraseña: "${password}"`);
  
  if (!usuario || !password) {
    console.log('❌ Faltan campos en el login');
    return res.status(400).json({ msg: 'Faltan campos' });
  }

  try {
    // Buscar en tabla clientes
    const [clientesRows] = await pool.query(`
      SELECT c.*, p.rol as rol_privilegio 
      FROM clientes c 
      LEFT JOIN Privilegios p ON c.cod_privilegio = p.cod_privilegio 
      WHERE c.usuario = ? AND c.estado = 'Activo'
    `, [usuario]);
    
    console.log(`📊 Clientes encontrados: ${clientesRows.length}`);
    
    // Buscar en tabla tecnicos
    const [tecnicosRows] = await pool.query(`
      SELECT t.*, p.rol as rol_privilegio 
      FROM tecnicos t 
      LEFT JOIN Privilegios p ON t.cod_privilegio = p.cod_privilegio 
      WHERE t.usuario = ? AND t.estado = 'Activo'
    `, [usuario]);
    
    console.log(`📊 Técnicos encontrados: ${tecnicosRows.length}`);
    
    if (tecnicosRows.length > 0) {
      const tecnico = tecnicosRows[0];
      console.log(`👤 Técnico encontrado: ${tecnico.usuario}`);
      console.log(`📧 Email: ${tecnico.correo}`);
      console.log(`🔐 Contraseña en BD: ${tecnico.password.substring(0, 20)}...`);
      console.log(`📏 Longitud contraseña: ${tecnico.password.length}`);
      console.log(`🔍 Tipo de contraseña: ${tecnico.password.startsWith('$2a$') ? 'bcrypt' : 'plain_text'}`);
      console.log(`📊 Estado: ${tecnico.estado}`);
      console.log(`🎭 Rol: ${tecnico.rol_privilegio}`);
    }

    let user = null;
    let rol = '';

    // Verificar si es cliente
    if (clientesRows.length > 0) {
      const cliente = clientesRows[0];
      console.log(`🔍 Verificando cliente: ${cliente.usuario}`);
      const ok = await bcrypt.compare(password, cliente.password);
      console.log(`✅ Cliente login result: ${ok}`);
      if (ok) {
        user = cliente;
        rol = cliente.rol_privilegio || 'cliente';
        console.log(`✅ Login exitoso como cliente: ${cliente.usuario}`);
      }
    }
    
    // Si no es cliente, verificar si es técnico
    if (!user && tecnicosRows.length > 0) {
      const tecnico = tecnicosRows[0];
      console.log(`🔍 Verificando técnico: ${tecnico.usuario}`);
      console.log(`🔍 Comparando: "${password}" con hash de BD`);
      
      const ok = await bcrypt.compare(password, tecnico.password);
      console.log(`✅ Técnico login result: ${ok}`);
      
      if (ok) {
        user = tecnico;
        rol = tecnico.rol_privilegio || 'tecnico';
        console.log(`✅ Login exitoso como técnico: ${tecnico.usuario}, rol: ${rol}`);
      } else {
        console.log(`❌ Login fallido para técnico: ${tecnico.usuario}`);
      }
    }

    if (!user) {
      console.log(`❌ Login fallido para usuario: ${usuario}`);
      return res.status(401).json({ msg: 'Credenciales inválidas' });
    }

    // Determinar tipo de usuario y ID correspondiente
    const tipoUsuario = user.cod_cliente ? 'cliente' : 'tecnico';
    const userId = user.cod_cliente || user.cod_tecnico;
    
    // Crear token con rol y datos del usuario
    const token = jwt.sign({ 
      cod_cliente: userId, 
      email: user.correo, 
      rol: rol,
      tipo: tipoUsuario
    }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });

    res.json({ 
      token, 
      rol,
      tipo: tipoUsuario,
      nombre: user.nombre,
      userId: userId,
      cod_cliente: userId,
      cod_privilegio: user.cod_privilegio
    });

  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// Middleware para verificar token y rol
const verifyToken = (req, res, next) => {
  console.log(`🔍 Verificando token para ${req.method} ${req.path}`);
  console.log(`🔍 Headers authorization: ${req.headers.authorization}`);
  
  const auth = req.headers.authorization;
  if (!auth) {
    console.log(`❌ No hay header de autorización`);
    return res.status(401).json({ msg: 'No autorizado' });
  }
  
  const parts = auth.split(' ');
  if (parts.length !== 2) {
    console.log(`❌ Formato de token inválido: ${parts.length} partes`);
    return res.status(401).json({ msg: 'No autorizado' });
  }
  
  const token = parts[1];
  console.log(`🔍 Token encontrado: ${token.substring(0, 20)}...`);
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    console.log(`✅ Token verificado, payload:`, payload);
    req.user = payload;
    next();
  } catch (e) {
    console.log(`❌ Error verificando token: ${e.message}`);
    res.status(401).json({ msg: 'Token inválido' });
  }
};

// Middleware para verificar rol específico
const verifyRole = (rolesPermitidos) => {
  return (req, res, next) => {
    console.log(`🔍 Verificando rol: ${req.user.rol}, roles permitidos: ${rolesPermitidos}`);
    
    // Normalizar rol a minúsculas para comparación
    const rolNormalizado = req.user.rol.toLowerCase();
    const rolesPermitidosNormalizados = rolesPermitidos.map(r => r.toLowerCase());
    
    console.log(`🔍 Rol normalizado: ${rolNormalizado}, roles permitidos normalizados: ${rolesPermitidosNormalizados}`);
    
    if (!rolesPermitidosNormalizados.includes(rolNormalizado)) {
      console.log(`❌ Rol ${req.user.rol} no está en roles permitidos: ${rolesPermitidos}`);
      return res.status(403).json({ msg: 'No tienes permisos para esta acción' });
    }
    console.log(`✅ Rol ${req.user.rol} verificado correctamente`);
    next();
  };
};

app.get('/api/protected', verifyToken, (req, res) => {
  res.json({ msg: 'Acceso concedido', user: req.user });
});

// Endpoint solo para técnicos - pueden ver todas las órdenes
app.get('/api/ordenes-reclamos/tecnico', verifyToken, verifyRole(['tecnico']), async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM ordenes_reclamos ORDER BY fecha_creacion DESC`
    );
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes' });
  }
});

// Endpoint solo para clientes - solo pueden ver sus propias órdenes
app.get('/api/ordenes-reclamos/cliente', verifyToken, verifyRole(['cliente', 'Cliente']), async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM ordenes_reclamos WHERE cod_cliente = ? ORDER BY fecha_creacion DESC`,
      [req.user.cod_cliente || req.user.id]
    );
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes' });
  }
});

// Endpoint temporal para probar creación de órdenes sin autenticación
app.post('/api/ordenes-reclamos-test', async (req, res) => {
  const categoria = String(req.body.categoria || '').trim();
  const tipo = String(req.body.tipo || 'reclamo').trim();
  const descripcion_problema = String(req.body.descripcion_problema || '').trim();
  const prioridad = String(req.body.prioridad || '').trim().toUpperCase();
  const cod_cliente = Number(req.body.cod_cliente) || null;

  if (!categoria || !descripcion_problema || !prioridad) {
    return res.status(400).json({ msg: 'Faltan campos requeridos' });
  }

  if (!['BAJA', 'MEDIA', 'ALTA'].includes(prioridad)) {
    return res.status(400).json({ msg: 'Prioridad inválida' });
  }

  try {
    // Buscar el código de la categoría basado en el nombre
    const [categoriaRows] = await pool.query(
      'SELECT cod_categoria FROM categoria WHERE nombre = ?',
      [categoria]
    );
    
    if (categoriaRows.length === 0) {
      return res.status(400).json({ msg: 'Categoría no encontrada' });
    }
    
    const cod_categoria = categoriaRows[0].cod_categoria;
    console.log(`✅ Categoría encontrada: ${categoria} (cod: ${cod_categoria})`);
    
    // Insertar solo los campos requeridos, los demás campos mantendrán sus valores por defecto (NULL)
    const query = `
      INSERT INTO ordenes_reclamos (
        cod_categoria, 
        tipo, 
        descripcion_problema, 
        prioridad, 
        cod_cliente
      ) VALUES (?, ?, ?, ?, ?)
    `;
    
    const params = [
      cod_categoria,               // cod_categoria (INT)
      tipo,                       // tipo (VARCHAR)
      descripcion_problema,       // descripcion_problema (TEXT)
      prioridad,                  // prioridad (VARCHAR)
      cod_cliente                 // cod_cliente (INT, puede ser NULL)
    ];
    
    console.log('📝 Insertando orden con:', {
      cod_categoria: cod_categoria,
      categoria: categoria,
      tipo: tipo,
      descripcion_problema: descripcion_problema,
      prioridad: prioridad,
      cod_cliente: cod_cliente
    });
    
    const [result] = await pool.query(query, params);
    
    console.log('✅ Orden creada con cod_orden:', result.insertId);
    
    return res.status(201).json({ 
      cod_orden: result.insertId, 
      msg: 'Orden creada exitosamente',
      datos: {
        cod_orden: result.insertId,
        cod_categoria: cod_categoria,
        categoria: categoria,
        tipo: tipo,
        descripcion_problema: descripcion_problema,
        prioridad: prioridad,
        cod_cliente: cod_cliente,
        estado: 'ABIERTA',  // Valor por defecto
        fecha_creacion: new Date()  // Se genera automáticamente
      }
    });
  } catch (e) {
    console.error('Create orden-reclamo error:', e.message);
    return res.status(500).json({ msg: 'No se pudo crear la orden' });
  }
});

// Endpoint para crear órdenes - todos los roles
app.post('/api/ordenes-reclamos', verifyToken, async (req, res) => {
  const categoria = String(req.body.categoria || '').trim();
  const tipo = String(req.body.tipo || 'reclamo').trim();
  const descripcion_problema = String(req.body.descripcion_problema || '').trim();
  const prioridad = String(req.body.prioridad || '').trim().toUpperCase();
  const cod_cliente = Number(req.body.cod_cliente) || null;

  if (!categoria || !descripcion_problema || !prioridad) {
    return res.status(400).json({ msg: 'Faltan campos requeridos' });
  }

  if (!['BAJA', 'MEDIA', 'ALTA'].includes(prioridad)) {
    return res.status(400).json({ msg: 'Prioridad inválida' });
  }

  try {
    // Buscar el cod_categoria a partir del nombre de la categoría
    console.log('🔍 Buscando categoría:', categoria);
    const [categoriaRows] = await pool.query(
      'SELECT cod_categoria FROM categoria WHERE nombre = ?',
      [categoria]
    );

    if (categoriaRows.length === 0) {
      return res.status(400).json({ 
        msg: `La categoría "${categoria}" no existe en el sistema` 
      });
    }

    const cod_categoria = categoriaRows[0].cod_categoria;
    console.log('✅ Categoría encontrada:', { nombre: categoria, cod_categoria });

    // Insertar solo los campos requeridos, los demás campos mantendrán sus valores por defecto (NULL)
    const query = `
      INSERT INTO ordenes_reclamos (
        cod_categoria, 
        tipo, 
        descripcion_problema, 
        prioridad, 
        cod_cliente
      ) VALUES (?, ?, ?, ?, ?)
    `;
    
    const params = [
      cod_categoria,               // cod_categoria (INT)
      tipo,                         // tipo (VARCHAR)
      descripcion_problema,         // descripcion_problema (TEXT)
      prioridad,                    // prioridad (VARCHAR)
      cod_cliente                   // cod_cliente (INT, puede ser NULL)
    ];
    
    console.log('📝 Insertando orden con:', {
      cod_categoria: cod_categoria,
      categoria: categoria,
      tipo: tipo,
      descripcion_problema: descripcion_problema,
      prioridad: prioridad,
      cod_cliente: cod_cliente
    });
    
    const [result] = await pool.query(query, params);
    
    console.log('✅ Orden creada con cod_orden:', result.insertId);
    
    return res.status(201).json({ 
      cod_orden: result.insertId, 
      msg: 'Orden creada exitosamente',
      datos: {
        cod_orden: result.insertId,
        cod_categoria: cod_categoria,
        categoria: categoria,
        tipo: tipo,
        descripcion_problema: descripcion_problema,
        prioridad: prioridad,
        cod_cliente: cod_cliente,
        estado: 'ABIERTA',  // Valor por defecto
        fecha_creacion: new Date()  // Se genera automáticamente
      }
    });
  } catch (e) {
    console.error('Create orden-reclamo error:', e.message);
    return res.status(500).json({ msg: 'No se pudo crear la orden' });
  }
});

// Endpoint para obtener órdenes de trabajo de clientes (categoría Reparación)
app.get('/api/ordenes-trabajo/cliente', verifyToken, async (req, res) => {
  try {
    console.log('📋 Obteniendo órdenes de trabajo para cliente:', req.user);
    
    // Obtener cod_cliente del usuario autenticado
    const codCliente = req.user.cod_cliente || req.user.id;
    
    if (!codCliente) {
      console.log('❌ No se encontró cod_cliente en el token');
      return res.status(400).json({ msg: 'No se encontró cod_cliente en el token' });
    }
    
    console.log(`🔍 Buscando órdenes para cliente ${codCliente}`);
    
    const [rows] = await pool.query(
      `SELECT 
        cod_orden as id,
        cod_categoria as category,
        descripcion_problema as description,
        prioridad as priority,
        estado as status,
        fecha_creacion as created_at,
        cod_cliente,
        cod_equipo,
        diagnostico,
        costo_estimado,
        costo_final,
        cod_tecnico,
        fecha_modificacion,
        correcciones,
        recomendaciones
       FROM ordenes_reclamos 
       WHERE tipo = 'Reparación' AND cod_cliente = ?
       ORDER BY fecha_creacion DESC`,
      [codCliente]
    );
    
    console.log(`✅ Órdenes de trabajo encontradas para cliente ${codCliente}: ${rows.length}`);
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes trabajo cliente error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes de trabajo' });
  }
});

// Endpoint para obtener órdenes de mantenimiento de clientes (categoría Mantenimiento)
app.get('/api/ordenes-mantenimiento/cliente', verifyToken, async (req, res) => {
  try {
    console.log('📋 Obteniendo órdenes de mantenimiento para cliente:', req.user);
    
    // Obtener cod_cliente del usuario autenticado
    const codCliente = req.user.cod_cliente || req.user.id;
    
    if (!codCliente) {
      console.log('❌ No se encontró cod_cliente en el token');
      return res.status(400).json({ msg: 'No se encontró cod_cliente en el token' });
    }
    
    console.log(`🔍 Buscando órdenes de mantenimiento para cliente ${codCliente}`);
    
    const [rows] = await pool.query(
      `SELECT 
        cod_orden as id,
        cod_categoria as category,
        descripcion_problema as description,
        prioridad as priority,
        estado as status,
        fecha_creacion as created_at,
        cod_cliente,
        cod_equipo,
        diagnostico,
        costo_estimado,
        costo_final,
        cod_tecnico,
        fecha_modificacion,
        correcciones,
        recomendaciones
       FROM ordenes_reclamos 
       WHERE tipo = 'Mantenimiento' AND cod_cliente = ?
       ORDER BY fecha_creacion DESC`,
      [codCliente]
    );
    
    console.log(`✅ Órdenes de mantenimiento encontradas para cliente ${codCliente}: ${rows.length}`);
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes mantenimiento cliente error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes de mantenimiento' });
  }
});

// Endpoint para obtener órdenes de trabajo (categoría Reparación)
app.get('/api/ordenes-trabajo', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT cod_orden as id, cod_categoria as category, descripcion_problema as description, prioridad as priority,
              estado as status, fecha_creacion as created_at, cod_cliente, cod_equipo, diagnostico, costo_estimado, costo_final,
              cod_tecnico, fecha_modificacion, correcciones, recomendaciones
       FROM ordenes_reclamos 
       WHERE tipo = 'Reparación' 
       ORDER BY fecha_creacion DESC`
    );
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes trabajo error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes de trabajo' });
  }
});

// Endpoint para obtener órdenes de mantenimiento (categoría Mantenimiento)
app.get('/api/ordenes-mantenimiento', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT cod_orden as id, cod_categoria as category, descripcion_problema as description, prioridad as priority,
              estado as status, fecha_creacion as created_at, cod_cliente, cod_equipo, diagnostico, costo_estimado, costo_final,
              cod_tecnico, fecha_modificacion, correcciones, recomendaciones
       FROM ordenes_reclamos 
       WHERE tipo = 'Mantenimiento' 
       ORDER BY fecha_creacion DESC`
    );
    return res.json(rows);
  } catch (e) {
    console.error('Get ordenes mantenimiento error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes de mantenimiento' });
  }
});

app.get('/api/ordenes-reclamos', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT cod_orden as id, cod_categoria as category, descripcion_problema as description, prioridad as priority, 
              estado as status, fecha_creacion as created_at, cod_cliente, cod_equipo, diagnostico, costo_estimado, costo_final, 
              cod_tecnico, fecha_modificacion, correcciones, recomendaciones
       FROM ordenes_reclamos
       ORDER BY fecha_creacion DESC`,
    );
    return res.json(rows);
  } catch (e) {
    console.error('List ordenes-reclamos error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes' });
  }
});

app.get('/api/ordenes-reclamos/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT 
        o.cod_orden as id,
        c.nombre as category,
        o.descripcion_problema as description,
        o.prioridad as priority,
        o.estado as status,
        o.fecha_creacion as created_at,
        o.fecha_modificacion as modified_at,
        o.costo_estimado,
        o.costo_final,
        o.diagnostico,
        o.correcciones,
        o.recomendaciones,
        o.cod_tecnico,
        t.nombre as tecnico_nombre
       FROM ordenes_reclamos o
       LEFT JOIN categoria c ON o.cod_categoria = c.cod_categoria
       LEFT JOIN tecnicos t ON o.cod_tecnico = t.cod_tecnico
       WHERE o.cod_orden = ?`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ msg: 'Orden no encontrada' });
    }

    return res.json(rows[0]);
  } catch (e) {
    console.error('Get orden detalle error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener los detalles de la orden' });
  }
});

app.delete('/api/ordenes-reclamos/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }

  try {
    const [result] = await pool.query('DELETE FROM ordenes_reclamos WHERE cod_orden = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Orden no encontrada' });
    }
    return res.json({ msg: 'Orden eliminada' });
  } catch (e) {
    console.error('Delete orden-reclamo error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar la orden' });
  }
});

// Endpoint para actualizar una orden de trabajo
app.put('/api/ordenes-reclamos/:id', verifyToken, async (req, res) => {
  const orderId = Number(req.params.id);
  
  if (!orderId || isNaN(orderId)) {
    return res.status(400).json({ msg: 'ID de orden inválido' });
  }

  const {
    cod_categoria,
    descripcion_problema,
    prioridad,
    estado,
    diagnostico,
    correcciones,
    recomendaciones,
    costo_estimado,
    costo_final,
    cod_cliente,
    cod_equipo,
    cod_tecnico
  } = req.body;

  // Validar campos requeridos
  if (!cod_categoria || !descripcion_problema || !prioridad || !estado) {
    return res.status(400).json({ msg: 'Faltan campos requeridos: cod_categoria, descripcion_problema, prioridad, estado' });
  }

  // Validar prioridad
  if (!['BAJA', 'MEDIA', 'ALTA'].includes(prioridad)) {
    return res.status(400).json({ msg: 'Prioridad inválida' });
  }

  try {
    // Verificar que la orden exista
    const [orderExists] = await pool.query(
      'SELECT cod_orden FROM ordenes_reclamos WHERE cod_orden = ?', 
      [orderId]
    );
    
    if (orderExists.length === 0) {
      return res.status(404).json({ msg: 'Orden no encontrada' });
    }

    // Verificar que la categoría exista
    const [categoriaExists] = await pool.query(
      'SELECT cod_categoria FROM categoria WHERE cod_categoria = ?', 
      [cod_categoria]
    );
    
    if (categoriaExists.length === 0) {
      return res.status(400).json({ msg: 'Categoría no válida' });
    }

    // Verificar que el cliente exista si se proporciona
    if (cod_cliente) {
      const [clienteExists] = await pool.query(
        'SELECT cod_cliente FROM clientes WHERE cod_cliente = ?', 
        [cod_cliente]
      );
      if (clienteExists.length === 0) {
        return res.status(400).json({ msg: 'Cliente no encontrado' });
      }
    }

    // Verificar que el equipo exista si se proporciona
    if (cod_equipo) {
      const [equipoExists] = await pool.query(
        'SELECT cod_equipos FROM equipos WHERE cod_equipos = ?', 
        [cod_equipo]
      );
      if (equipoExists.length === 0) {
        return res.status(400).json({ msg: 'Equipo no encontrado' });
      }
    }

    // Verificar que el técnico exista si se proporciona
    if (cod_tecnico) {
      const [tecnicoExists] = await pool.query(
        'SELECT cod_tecnico FROM tecnicos WHERE cod_tecnico = ?', 
        [cod_tecnico]
      );
      if (tecnicoExists.length === 0) {
        return res.status(400).json({ msg: 'Técnico no encontrado' });
      }
    }

    // Construir la consulta de actualización
    const updateFields = [
      'cod_categoria = ?',
      'descripcion_problema = ?',
      'prioridad = ?',
      'estado = ?',
      'fecha_modificacion = CURRENT_TIMESTAMP'
    ];
    
    const updateValues = [
      cod_categoria,
      descripcion_problema,
      prioridad,
      estado
    ];

    // Agregar campos opcionales
    if (diagnostico !== undefined && diagnostico !== null) {
      updateFields.push('diagnostico = ?');
      updateValues.push(diagnostico);
    }
    
    if (correcciones !== undefined && correcciones !== null) {
      updateFields.push('correcciones = ?');
      updateValues.push(correcciones);
    }
    
    if (recomendaciones !== undefined && recomendaciones !== null) {
      updateFields.push('recomendaciones = ?');
      updateValues.push(recomendaciones);
    }
    
    if (costo_estimado !== undefined && costo_estimado !== null) {
      updateFields.push('costo_estimado = ?');
      updateValues.push(costo_estimado);
    }
    
    if (costo_final !== undefined && costo_final !== null) {
      updateFields.push('costo_final = ?');
      updateValues.push(costo_final);
    }
    
    if (cod_cliente !== undefined && cod_cliente !== null) {
      updateFields.push('cod_cliente = ?');
      updateValues.push(cod_cliente);
    }
    
    if (cod_equipo !== undefined && cod_equipo !== null) {
      updateFields.push('cod_equipo = ?');
      updateValues.push(cod_equipo);
    }
    
    if (cod_tecnico !== undefined && cod_tecnico !== null) {
      updateFields.push('cod_tecnico = ?');
      updateValues.push(cod_tecnico);
    }

    // Agregar el ID al final de los valores
    updateValues.push(orderId);

    // Ejecutar la actualización
    const query = `
      UPDATE ordenes_reclamos 
      SET ${updateFields.join(', ')} 
      WHERE cod_orden = ?
    `;

    console.log('📝 Actualizando orden:', {
      orderId,
      fields: updateFields,
      values: updateValues
    });

    const [result] = await pool.query(query, updateValues);

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'No se pudo actualizar la orden' });
    }

    console.log('✅ Orden actualizada exitosamente:', orderId);

    return res.json({ 
      msg: 'Orden actualizada exitosamente',
      cod_orden: orderId,
      fecha_modificacion: new Date()
    });

  } catch (e) {
    console.error('Update orden-reclamo error:', e.message);
    return res.status(500).json({ msg: 'No se pudo actualizar la orden' });
  }
});

app.post('/api/equipments', async (req, res) => {
  const tipo = String(req.body.tipo || '').trim();
  const marca = String(req.body.marca || '').trim();
  const modelo = String(req.body.modelo || '').trim();
  const serial = String(req.body.serial || '').trim();
  const cod_cliente = Number(req.body.cod_cliente) || null;

  if (!tipo || !marca || !modelo || !serial) {
    return res.status(400).json({ msg: 'Faltan campos requeridos: tipo, marca, modelo, serial' });
  }

  // Verificar que el cliente exista si se proporciona cod_cliente
  if (cod_cliente) {
    const [clienteRows] = await pool.query('SELECT cod_cliente FROM clientes WHERE cod_cliente = ?', [cod_cliente]);
    if (clienteRows.length === 0) {
      return res.status(400).json({ msg: 'El cliente especificado no existe' });
    }
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO equipos (tipo, marca, modelo, serial, cod_cliente) VALUES (?, ?, ?, ?, ?)',
      [tipo, marca, modelo, serial, cod_cliente],
    );
    return res.status(201).json({ cod_equipos: result.insertId, msg: 'Equipo creado exitosamente' });
  } catch (e) {
    console.error('Create equipment error:', e.message);
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ msg: 'El número de serie ya está registrado' });
    }
    return res.status(500).json({ msg: 'No se pudo crear el equipo' });
  }
});

app.get('/api/equipments', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT e.cod_equipos, e.tipo, e.marca, e.modelo, e.serial, e.cod_cliente,
              c.nombre as nombre_cliente, c.usuario as usuario_cliente
       FROM equipos e
       LEFT JOIN clientes c ON e.cod_cliente = c.cod_cliente
       ORDER BY e.cod_equipos DESC`,
    );
    return res.json(rows);
  } catch (e) {
    console.error('List equipos error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener equipos' });
  }
});

app.delete('/api/equipments/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }

  try {
    const [result] = await pool.query('DELETE FROM equipos WHERE cod_equipos = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Equipo no encontrado' });
    }
    return res.json({ msg: 'Equipo eliminado exitosamente' });
  } catch (e) {
    console.error('Delete equipment error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar el equipo' });
  }
});

app.get('/api/clientes', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT c.cod_cliente, c.usuario, c.nombre, c.correo, c.num_telefono, c.direccion, 
              c.cod_privilegio, p.rol as nombre_privilegio, c.estado, c.fecha_creacion
       FROM clientes c
       LEFT JOIN Privilegios p ON c.cod_privilegio = p.cod_privilegio
       ORDER BY c.fecha_creacion DESC`,
    );
    return res.json(rows);
  } catch (e) {
    console.error('List clientes error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener los clientes' });
  }
});

// Obtener lista de técnicos
app.get('/api/tecnicos', async (req, res) => {
  try {
    console.log('🔍 Ejecutando consulta /api/tecnicos...');
    
    // Primero verificar si hay técnicos en la tabla
    const [countResult] = await pool.query('SELECT COUNT(*) as total FROM tecnicos');
    console.log('📊 Total de técnicos en la base de datos:', countResult[0].total);
    
    if (countResult[0].total === 0) {
      console.log('⚠️ No hay técnicos en la base de datos');
      return res.json([]);
    }
    
    // Verificar estructura de la tabla
    const [structure] = await pool.query('DESCRIBE tecnicos');
    console.log('🏗️ Estructura de la tabla tecnicos:');
    structure.forEach(col => {
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null ? 'NULL' : 'NOT NULL'} ${col.Key ? 'KEY' : ''}`);
    });
    
    // Verificar si existe el campo cod_tecnico
    const hasCodTecnico = structure.some(col => col.Field === 'cod_tecnico');
    console.log('🔍 ¿Existe campo cod_tecnico?', hasCodTecnico);
    
    if (!hasCodTecnico) {
      console.log('❌ ERROR: No se encuentra el campo cod_tecnico en la tabla');
      console.log('🔍 Campos disponibles:', structure.map(col => col.Field));
      return res.status(500).json({ msg: 'Error: El campo cod_tecnico no existe en la tabla' });
    }
    
    // Verificar datos brutos antes del JOIN
    const [rawRows] = await pool.query('SELECT * FROM tecnicos LIMIT 1');
    if (rawRows.length > 0) {
      console.log('🔍 Datos brutos del primer técnico:');
      console.log('  - Todos los campos:', Object.keys(rawRows[0]));
      console.log('  - Valores:', rawRows[0]);
      console.log('🔍 Valor específico de cod_tecnico:', rawRows[0].cod_tecnico);
      console.log('🔍 Tipo de cod_tecnico:', typeof rawRows[0].cod_tecnico);
    } else {
      console.log('⚠️ No hay datos para mostrar en la tabla');
    }
    
    // Verificar consulta SQL sin JOIN primero
    console.log('🔍 Probando consulta directa sin JOIN...');
    const [directRows] = await pool.query('SELECT * FROM tecnicos LIMIT 3');
    console.log('📊 Resultado consulta directa:', directRows.length, 'registros');
    if (directRows.length > 0) {
      directRows.forEach((row, index) => {
        console.log(`  Técnico ${index + 1}:`, {
          cod_tecnico: row.cod_tecnico,
          tipo_cod_tecnico: typeof row.cod_tecnico,
          nombre: row.nombre,
          usuario: row.usuario
        });
      });
    }
    
    // Obtener los técnicos con JOIN
    console.log('🔍 Ejecutando consulta con JOIN...');
    const [rows] = await pool.query(
      `SELECT t.cod_tecnico, t.usuario, t.nombre, t.correo, t.num_telefono, 
              t.cod_privilegio, p.rol as nombre_privilegio, t.estado, t.fecha_creacion
       FROM tecnicos t
       LEFT JOIN Privilegios p ON t.cod_privilegio = p.cod_privilegio
       ORDER BY t.fecha_creacion DESC`
    );
    
    console.log('📊 Datos de técnicos obtenidos con JOIN:', rows.length, 'registros');
    if (rows.length > 0) {
      rows.forEach((row, index) => {
        console.log(`  Técnico JOIN ${index + 1}:`, {
          cod_tecnico: row.cod_tecnico,
          tipo_cod_tecnico: typeof row.cod_tecnico,
          nombre: row.nombre,
          estado: row.estado,
          privilegio: row.nombre_privilegio
        });
      });
    } else {
      console.log('❌ La consulta con JOIN no devolvió resultados');
    }
    
    return res.json(rows);
  } catch (e) {
    console.error('List tecnicos error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener los técnicos' });
  }
});

// Endpoint para modificar esquema de la tabla tecnicos (manejando restricciones)
app.post('/api/fix-schema', async (req, res) => {
  try {
    console.log('🔧 Modificando esquema de tabla tecnicos...');
    
    // Primero verificar estructura actual y restricciones
    const [structure] = await pool.query('DESCRIBE tecnicos');
    const [constraints] = await pool.query(`
      SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, 
             REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'tecnicos'
      AND REFERENCED_TABLE_NAME IS NOT NULL
    `);
    
    console.log('🏗️ Estructura actual de la tabla tecnicos:');
    structure.forEach(col => {
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null ? 'NULL' : 'NOT NULL'} ${col.Key ? 'KEY' : ''}`);
    });
    
    console.log('🔗 Restricciones de clave externa encontradas:');
    constraints.forEach(constraint => {
      console.log(`  - ${constraint.CONSTRAINT_NAME}: ${constraint.COLUMN_NAME} -> ${constraint.REFERENCED_TABLE_NAME}.${constraint.REFERENCED_COLUMN_NAME}`);
    });
    
    const updates = [];
    
    // Verificar y actualizar cod_privilegio
    const codPrivilegioCol = structure.find(col => col.Field === 'cod_privilegio');
    if (codPrivilegioCol && codPrivilegioCol.Null === 'YES') {
      console.log('🔧 Actualizando cod_privilegio a NOT NULL...');
      
      // Buscar restricciones que afectan a cod_privilegio
      const codPrivilegioConstraints = constraints.filter(c => c.COLUMN_NAME === 'cod_privilegio');
      
      // Eliminar temporalmente las restricciones de clave externa
      for (const constraint of codPrivilegioConstraints) {
        console.log(`🔓 Eliminando temporalmente restricción: ${constraint.CONSTRAINT_NAME}`);
        await pool.query(`ALTER TABLE tecnicos DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME}`);
        updates.push(`Eliminada restricción: ${constraint.CONSTRAINT_NAME}`);
      }
      
      // Primero actualizar valores NULL a un valor por defecto
      await pool.query(
        "UPDATE tecnicos SET cod_privilegio = '50' WHERE cod_privilegio IS NULL OR cod_privilegio = ''"
      );
      updates.push('Actualizados valores NULL de cod_privilegio');
      
      // Luego modificar la columna
      await pool.query(
        "ALTER TABLE tecnicos MODIFY COLUMN cod_privilegio VARCHAR(10) NOT NULL DEFAULT '50'"
      );
      updates.push('cod_privilegio modificado a NOT NULL con valor por defecto 50');
      
      // Volver a crear las restricciones de clave externa
      for (const constraint of codPrivilegioConstraints) {
        console.log(`🔗 Recreando restricción: ${constraint.CONSTRAINT_NAME}`);
        await pool.query(`
          ALTER TABLE tecnicos 
          ADD CONSTRAINT ${constraint.CONSTRAINT_NAME} 
          FOREIGN KEY (${constraint.COLUMN_NAME}) 
          REFERENCES ${constraint.REFERENCED_TABLE_NAME}(${constraint.REFERENCED_COLUMN_NAME})
        `);
        updates.push(`Recreada restricción: ${constraint.CONSTRAINT_NAME}`);
      }
    }
    
    // Verificar y actualizar otros campos importantes (sin restricciones)
    const importantFields = ['usuario', 'nombre', 'correo', 'password'];
    for (const field of importantFields) {
      const col = structure.find(c => c.Field === field);
      if (col && col.Null === 'YES') {
        console.log(`🔧 Actualizando ${field} a NOT NULL...`);
        await pool.query(`ALTER TABLE tecnicos MODIFY COLUMN ${field} VARCHAR(255) NOT NULL`);
        updates.push(field);
      }
    }
    
    // Verificar estructura final
    const [finalStructure] = await pool.query('DESCRIBE tecnicos');
    console.log('✅ Estructura final de la tabla tecnicos:');
    finalStructure.forEach(col => {
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null ? 'NULL' : 'NOT NULL'} ${col.Key ? 'KEY' : ''}`);
    });
    
    res.json({ 
      msg: 'Esquema actualizado correctamente',
      updates: updates,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error modificando esquema:', e.message);
    res.status(500).json({ msg: 'Error al modificar esquema: ' + e.message });
  }
});

// Endpoint para verificar estructura de la tabla tecnicos
app.get('/api/check-schema', async (req, res) => {
  try {
    console.log('🔍 Verificando estructura de la tabla tecnicos...');
    
    const [structure] = await pool.query('DESCRIBE tecnicos');
    console.log('🏗️ Estructura actual de la tabla tecnicos:');
    
    const tableInfo = [];
    structure.forEach(col => {
      const info = {
        campo: col.Field,
        tipo: col.Type,
        nulo: col.Null === 'YES' ? 'SI' : 'NO',
        clave: col.Key || '',
        default: col.Default || 'NULL'
      };
      tableInfo.push(info);
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null ? 'NULL' : 'NOT NULL'} ${col.Key ? 'KEY' : ''} Default: ${col.Default || 'NULL'}`);
    });
    
    // Verificar específicamente el campo cod_privilegio
    const codPrivilegioCol = structure.find(col => col.Field === 'cod_privilegio');
    let codPrivilegioStatus = 'NO ENCONTRADO';
    if (codPrivilegioCol) {
      codPrivilegioStatus = `Tipo: ${codPrivilegioCol.Type}, Nulo: ${codPrivilegioCol.Null === 'YES' ? 'SI' : 'NO'}, Default: ${codPrivilegioCol.Default || 'NULL'}`;
    }
    
    res.json({ 
      msg: 'Estructura de la tabla tecnicos',
      tabla: 'tecnicos',
      total_campos: structure.length,
      estructura: tableInfo,
      cod_privilegio_status: codPrivilegioStatus,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error verificando esquema:', e.message);
    res.status(500).json({ msg: 'Error al verificar esquema: ' + e.message });
  }
});

// Endpoint para eliminar restricción UNIQUE manejando correctamente la clave externa
app.post('/api/remove-unique-constraint', async (req, res) => {
  try {
    console.log('🔧 Eliminando restricción UNIQUE de cod_privilegio...');
    
    // Verificar todos los índices de la tabla
    const [indexes] = await pool.query('SHOW INDEX FROM tecnicos');
    console.log('📋 Todos los índices de la tabla tecnicos:');
    indexes.forEach(idx => {
      console.log(`  - ${idx.Key_name}: ${idx.Column_name} (Unique: ${idx.Non_unique === 0})`);
    });
    
    // Encontrar índices UNIQUE que afectan a cod_privilegio
    const uniqueIndexes = indexes.filter(idx => 
      idx.Column_name === 'cod_privilegio' && 
      idx.Non_unique === 0 && 
      idx.Key_name !== 'PRIMARY'
    );
    
    console.log(`🎯 Índices UNIQUE encontrados para cod_privilegio: ${uniqueIndexes.length}`);
    
    // Verificar restricciones de clave externa
    const [foreignKeys] = await pool.query(`
      SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, 
             REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'tecnicos'
      AND REFERENCED_TABLE_NAME IS NOT NULL
    `);
    
    console.log(`🔗 Restricciones de clave externa encontradas: ${foreignKeys.length}`);
    foreignKeys.forEach(fk => {
      console.log(`  - ${fk.CONSTRAINT_NAME}: ${fk.COLUMN_NAME} -> ${fk.REFERENCED_TABLE_NAME}.${fk.REFERENCED_COLUMN_NAME}`);
    });
    
    let removedCount = 0;
    
    // Proceso para eliminar la restricción UNIQUE
    for (const index of uniqueIndexes) {
      try {
        console.log(`� Procesando índice UNIQUE: ${index.Key_name}`);
        
        // 1. Eliminar temporalmente las restricciones de clave externa que usan este campo
        const relatedForeignKeys = foreignKeys.filter(fk => fk.COLUMN_NAME === index.Column_name);
        
        for (const fk of relatedForeignKeys) {
          try {
            console.log(`🔓 Eliminando temporalmente clave externa: ${fk.CONSTRAINT_NAME}`);
            await pool.query(`ALTER TABLE tecnicos DROP FOREIGN KEY ${fk.CONSTRAINT_NAME}`);
            console.log(`✅ Clave externa ${fk.CONSTRAINT_NAME} eliminada temporalmente`);
          } catch (fkError) {
            console.log(`⚠️ No se pudo eliminar clave externa ${fk.CONSTRAINT_NAME}: ${fkError.message}`);
          }
        }
        
        // 2. Eliminar el índice UNIQUE
        try {
          console.log(`🔓 Eliminando índice UNIQUE: ${index.Key_name}`);
          await pool.query(`ALTER TABLE tecnicos DROP INDEX ${index.Key_name}`);
          removedCount++;
          console.log(`✅ Índice UNIQUE ${index.Key_name} eliminado`);
        } catch (dropError) {
          console.log(`⚠️ No se pudo eliminar índice ${index.Key_name}: ${dropError.message}`);
        }
        
        // 3. Recrear las restricciones de clave externa
        for (const fk of relatedForeignKeys) {
          try {
            console.log(`🔗 Recreando clave externa: ${fk.CONSTRAINT_NAME}`);
            await pool.query(`
              ALTER TABLE tecnicos 
              ADD CONSTRAINT ${fk.CONSTRAINT_NAME} 
              FOREIGN KEY (${fk.COLUMN_NAME}) 
              REFERENCES ${fk.REFERENCED_TABLE_NAME}(${fk.REFERENCED_COLUMN_NAME})
            `);
            console.log(`✅ Clave externa ${fk.CONSTRAINT_NAME} recreada`);
          } catch (recreateError) {
            console.log(`⚠️ No se pudo recrear clave externa ${fk.CONSTRAINT_NAME}: ${recreateError.message}`);
          }
        }
        
      } catch (processError) {
        console.log(`⚠️ Error procesando índice ${index.Key_name}: ${processError.message}`);
      }
    }
    
    console.log(`✅ Proceso completado. Total eliminados: ${removedCount}`);
    
    // Verificación final
    const [finalIndexes] = await pool.query('SHOW INDEX FROM tecnicos WHERE Column_name = "cod_privilegio"');
    const remainingUnique = finalIndexes.filter(idx => idx.Non_unique === 0 && idx.Key_name !== 'PRIMARY');
    
    res.json({ 
      msg: removedCount > 0 ? 'Restricciones UNIQUE eliminadas correctamente' : 'No se encontraron restricciones UNIQUE para eliminar',
      constraints_removed: removedCount,
      remaining_unique_constraints: remainingUnique.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error eliminando restricción UNIQUE:', e.message);
    res.status(500).json({ msg: 'Error al eliminar restricción UNIQUE: ' + e.message });
  }
});

// Endpoint para restablecer contraseñas de usuarios específicos
app.post('/api/reset-passwords', async (req, res) => {
  try {
    console.log('🔧 Restableciendo contraseñas de usuarios...');
    
    const usuarios = [
      { usuario: 'Maraña', nuevaPassword: 'password456' },  // Mantenido como Maraña
      { usuario: 'Carduty', nuevaPassword: 'password789' }
    ];
    
    const resultados = [];
    
    for (const user of usuarios) {
      try {
        console.log(`🔧 Actualizando contraseña para: ${user.usuario}`);
        
        // Verificar si el usuario existe
        const [existingUser] = await pool.query(
          'SELECT usuario FROM tecnicos WHERE usuario = ?',
          [user.usuario]
        );
        
        if (existingUser.length === 0) {
          console.log(`❌ Usuario ${user.usuario} no encontrado`);
          resultados.push({ usuario: user.usuario, status: 'error', message: 'Usuario no encontrado' });
          continue;
        }
        
        // Encriptar la contraseña con bcrypt (como lo hace el login)
        console.log(`🔐 Encriptando contraseña para: ${user.usuario}`);
        const hashedPassword = await bcrypt.hash(user.nuevaPassword, 10);
        console.log(`✅ Contraseña encriptada para: ${user.usuario} (longitud: ${hashedPassword.length})`);
        
        // Actualizar la contraseña con el hash
        console.log(`💾 Guardando contraseña encriptada para: ${user.usuario}`);
        const [result] = await pool.query(
          'UPDATE tecnicos SET password = ? WHERE usuario = ?',
          [hashedPassword, user.usuario]
        );
        console.log(`📊 Resultado de actualización para ${user.usuario}: ${result.affectedRows} filas afectadas`);
        
        if (result.affectedRows > 0) {
          console.log(`✅ Contraseña actualizada para: ${user.usuario}`);
          resultados.push({ usuario: user.usuario, status: 'success', message: 'Contraseña actualizada correctamente' });
        } else {
          console.log(`❌ No se pudo actualizar contraseña para: ${user.usuario}`);
          resultados.push({ usuario: user.usuario, status: 'error', message: 'No se pudo actualizar la contraseña' });
        }
        
      } catch (userError) {
        console.log(`❌ Error actualizando ${user.usuario}: ${userError.message}`);
        resultados.push({ usuario: user.usuario, status: 'error', message: userError.message });
      }
    }
    
    console.log('✅ Proceso de restablecimiento completado');
    res.json({ 
      msg: 'Proceso de restablecimiento completado',
      resultados: resultados,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error restableciendo contraseñas:', e.message);
    res.status(500).json({ msg: 'Error al restablecer contraseñas: ' + e.message });
  }
});

// Endpoint de diagnóstico para verificar usuarios en la base de datos
app.get('/api/diagnose-users', async (req, res) => {
  try {
    console.log('🔍 Diagnosticando usuarios en la base de datos...');
    
    // Obtener todos los técnicos
    const [tecnicos] = await pool.query(`
      SELECT usuario, nombre, correo, estado, cod_privilegio, 
             LENGTH(password) as password_length,
             CASE WHEN password LIKE '$2a$%' THEN 'bcrypt' ELSE 'plain_text' END as password_type
      FROM tecnicos
      ORDER BY usuario
    `);
    
    console.log('📋 Técnicos encontrados:');
    tecnicos.forEach(tecnico => {
      console.log(`  - ${tecnico.usuario}: estado=${tecnico.estado}, password_type=${tecnico.password_type}, length=${tecnico.password_length}`);
    });
    
    // Verificar usuarios específicos
    const usuariosEspecificos = ['Jesmillan', 'Carduty', 'Maraña'];
    const diagnosticos = [];
    
    for (const usuario of usuariosEspecificos) {
      const [userRows] = await pool.query(`
        SELECT usuario, nombre, correo, estado, cod_privilegio, password
        FROM tecnicos 
        WHERE usuario = ?
      `, [usuario]);
      
      if (userRows.length > 0) {
        const user = userRows[0];
        diagnosticos.push({
          usuario: user.usuario,
          nombre: user.nombre,
          estado: user.estado,
          existe: true,
          password_length: user.password ? user.password.length : 0,
          password_type: user.password && user.password.startsWith('$2a$') ? 'bcrypt' : 'plain_text'
        });
      } else {
        diagnosticos.push({
          usuario: usuario,
          existe: false,
          mensaje: 'Usuario no encontrado en la base de datos'
        });
      }
    }
    
    res.json({ 
      msg: 'Diagnóstico completado',
      total_tecnicos: tecnicos.length,
      diagnosticos_especificos: diagnosticos,
      todos_los_tecnicos: tecnicos,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error diagnosticando usuarios:', e.message);
    res.status(500).json({ msg: 'Error al diagnosticar usuarios: ' + e.message });
  }
});

// Endpoint de prueba para verificar encriptación bcrypt
app.post('/api/test-bcrypt', async (req, res) => {
  try {
    console.log('🧪 Probando encriptación bcrypt...');
    
    const testPassword = 'password789';
    const testUser = 'Carduty';
    
    // 1. Encriptar la contraseña
    console.log('🔐 Encriptando contraseña de prueba...');
    const hashedPassword = await bcrypt.hash(testPassword, 10);
    console.log(`✅ Contraseña encriptada: ${hashedPassword}`);
    console.log(`📏 Longitud del hash: ${hashedPassword.length}`);
    
    // 2. Verificar la contraseña
    console.log('🔍 Verificando contraseña...');
    const isValid = await bcrypt.compare(testPassword, hashedPassword);
    console.log(`✅ Verificación de contraseña: ${isValid}`);
    
    // 3. Actualizar en la base de datos
    console.log('💾 Actualizando contraseña en la base de datos...');
    const [result] = await pool.query(
      'UPDATE tecnicos SET password = ? WHERE usuario = ?',
      [hashedPassword, testUser]
    );
    console.log(`📊 Filas afectadas: ${result.affectedRows}`);
    
    // 4. Verificar el login
    console.log('🔍 Probando login...');
    const [userRows] = await pool.query(
      'SELECT * FROM tecnicos WHERE usuario = ? AND estado = \'Activo\'',
      [testUser]
    );
    
    if (userRows.length > 0) {
      const user = userRows[0];
      console.log(`👤 Usuario encontrado: ${user.usuario}`);
      console.log(`🔐 Contraseña en BD: ${user.password}`);
      console.log(`📏 Longitud en BD: ${user.password.length}`);
      
      const loginValid = await bcrypt.compare(testPassword, user.password);
      console.log(`✅ Login válido: ${loginValid}`);
      
      res.json({
        msg: 'Prueba de bcrypt completada',
        test_password: testPassword,
        test_user: testUser,
        hash_generated: hashedPassword,
        hash_length: hashedPassword.length,
        db_hash: user.password,
        db_hash_length: user.password.length,
        verification_result: isValid,
        login_result: loginValid,
        database_update_rows: result.affectedRows,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(404).json({
        msg: 'Usuario no encontrado',
        test_user: testUser
      });
    }
    
  } catch (e) {
    console.error('Error en prueba bcrypt:', e.message);
    res.status(500).json({ msg: 'Error en prueba bcrypt: ' + e.message });
  }
});

// Endpoint de diagnóstico específico para login
app.post('/api/diagnose-login', async (req, res) => {
  try {
    const { usuario, password } = req.body;
    console.log(`🔍 Diagnosticando login para: ${usuario}`);
    
    // Buscar en tabla tecnicos
    const [tecnicosRows] = await pool.query(`
      SELECT t.*, p.rol as rol_privilegio 
      FROM tecnicos t 
      LEFT JOIN Privilegios p ON t.cod_privilegio = p.cod_privilegio 
      WHERE t.usuario = ? AND t.estado = 'Activo'
    `, [usuario]);
    
    console.log(`📊 Técnicos encontrados: ${tecnicosRows.length}`);
    
    if (tecnicosRows.length > 0) {
      const tecnico = tecnicosRows[0];
      console.log(`👤 Usuario encontrado: ${tecnico.usuario}`);
      console.log(`📧 Email: ${tecnico.correo}`);
      console.log(`🔐 Contraseña en BD: ${tecnico.password}`);
      console.log(`📏 Longitud contraseña: ${tecnico.password.length}`);
      console.log(`🔍 Tipo de contraseña: ${tecnico.password.startsWith('$2a$') ? 'bcrypt' : 'plain_text'}`);
      console.log(`📊 Estado: ${tecnico.estado}`);
      console.log(`🎭 Rol: ${tecnico.rol_privilegio}`);
      
      // Probar la comparación de contraseña
      console.log(`🔍 Comparando contraseña: "${password}" con hash de BD`);
      const passwordMatch = await bcrypt.compare(password, tecnico.password);
      console.log(`✅ Resultado de comparación: ${passwordMatch}`);
      
      // Si no funciona, probar con diferentes contraseñas
      if (!passwordMatch) {
        console.log('🔍 Probando con contraseñas comunes...');
        const commonPasswords = ['password123', 'password456', 'password789', 'Carduty', 'carduty'];
        
        for (const pwd of commonPasswords) {
          const match = await bcrypt.compare(pwd, tecnico.password);
          console.log(`🔍 Probando "${pwd}": ${match}`);
          if (match) {
            console.log(`✅ ¡Contraseña encontrada! La contraseña correcta es: "${pwd}"`);
            break;
          }
        }
      }
      
      res.json({
        msg: 'Diagnóstico completado',
        usuario: usuario,
        encontrado: true,
        datos_usuario: {
          usuario: tecnico.usuario,
          email: tecnico.correo,
          estado: tecnico.estado,
          rol: tecnico.rol_privilegio,
          password_length: tecnico.password.length,
          password_type: tecnico.password.startsWith('$2a$') ? 'bcrypt' : 'plain_text'
        },
        login_test: {
          password_provided: password,
          password_match: passwordMatch
        },
        timestamp: new Date().toISOString()
      });
      
    } else {
      console.log(`❌ Usuario ${usuario} no encontrado o inactivo`);
      res.json({
        msg: 'Usuario no encontrado',
        usuario: usuario,
        encontrado: false,
        timestamp: new Date().toISOString()
      });
    }
    
  } catch (e) {
    console.error('Error en diagnóstico de login:', e.message);
    res.status(500).json({ msg: 'Error en diagnóstico: ' + e.message });
  }
});

// Endpoint específico para cambiar contraseña de Carduty a password789
app.post('/api/change-carduty-password', async (req, res) => {
  try {
    console.log('🔧 Cambiando contraseña de Carduty a password789...');
    
    const newPassword = 'password789';
    const targetUser = 'Carduty';
    
    // 1. Verificar que Carduty existe
    const [userCheck] = await pool.query(
      'SELECT usuario, password FROM tecnicos WHERE usuario = ? AND estado = \'Activo\'',
      [targetUser]
    );
    
    if (userCheck.length === 0) {
      return res.status(404).json({ 
        msg: 'Usuario Carduty no encontrado o inactivo',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log(`� Usuario encontrado: ${userCheck[0].usuario}`);
    
    // 2. Encriptar la nueva contraseña con bcrypt
    console.log(`🔐 Encriptando nueva contraseña: "${newPassword}"`);
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    console.log(`✅ Contraseña encriptada (longitud: ${hashedPassword.length})`);
    
    // 3. Actualizar la contraseña en la base de datos
    const [updateResult] = await pool.query(
      'UPDATE tecnicos SET password = ? WHERE usuario = ?',
      [hashedPassword, targetUser]
    );
    
    console.log(`📊 Contraseña actualizada: ${updateResult.affectedRows} filas afectadas`);
    
    if (updateResult.affectedRows === 0) {
      return res.status(500).json({ 
        msg: 'No se pudo actualizar la contraseña',
        timestamp: new Date().toISOString()
      });
    }
    
    // 4. Verificar que la contraseña se actualizó correctamente
    const [verifyResult] = await pool.query(
      'SELECT password FROM tecnicos WHERE usuario = ?',
      [targetUser]
    );
    
    const updatedPassword = verifyResult[0].password;
    console.log(`🔐 Contraseña guardada en BD (longitud: ${updatedPassword.length})`);
    
    // 5. Probar el login con la nueva contraseña
    console.log(`🔍 Verificando login con nueva contraseña...`);
    const loginTest = await bcrypt.compare(newPassword, updatedPassword);
    console.log(`✅ Login test result: ${loginTest}`);
    
    // 6. Probar login real con el endpoint de login
    console.log(`🔍 Probando login real con endpoint /api/login...`);
    
    res.json({ 
      msg: 'Contraseña de Carduty actualizada exitosamente',
      user: targetUser,
      new_password: newPassword,
      hash_length: hashedPassword.length,
      db_updated: updateResult.affectedRows > 0,
      login_test: loginTest,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error cambiando contraseña:', e.message);
    res.status(500).json({ 
      msg: 'Error al cambiar contraseña: ' + e.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint específico para cambiar contraseña de Maraña a password456
app.post('/api/change-marpana-password', async (req, res) => {
  try {
    console.log('� Cambiando contraseña de Maraña a password456...');
    
    const newPassword = 'password456';
    const targetUser = 'Maraña';
    
    // 1. Verificar que Maraña existe
    const [userCheck] = await pool.query(
      'SELECT usuario, password FROM tecnicos WHERE usuario = ? AND estado = \'Activo\'',
      [targetUser]
    );
    
    if (userCheck.length === 0) {
      return res.status(404).json({ 
        msg: 'Usuario Maraña no encontrado o inactivo',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log(`👤 Usuario encontrado: ${userCheck[0].usuario}`);
    
    // 2. Encriptar la nueva contraseña con bcrypt
    console.log(`🔐 Encriptando nueva contraseña: "${newPassword}"`);
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    console.log(`✅ Contraseña encriptada (longitud: ${hashedPassword.length})`);
    
    // 3. Actualizar la contraseña en la base de datos
    const [updateResult] = await pool.query(
      'UPDATE tecnicos SET password = ? WHERE usuario = ?',
      [hashedPassword, targetUser]
    );
    
    console.log(`📊 Contraseña actualizada: ${updateResult.affectedRows} filas afectadas`);
    
    if (updateResult.affectedRows === 0) {
      return res.status(500).json({ 
        msg: 'No se pudo actualizar la contraseña',
        timestamp: new Date().toISOString()
      });
    }
    
    // 4. Verificar que la contraseña se actualizó correctamente
    const [verifyResult] = await pool.query(
      'SELECT password FROM tecnicos WHERE usuario = ?',
      [targetUser]
    );
    
    const updatedPassword = verifyResult[0].password;
    console.log(`🔐 Contraseña guardada en BD (longitud: ${updatedPassword.length})`);
    
    // 5. Probar el login con la nueva contraseña
    console.log(`🔍 Verificando login con nueva contraseña...`);
    const loginTest = await bcrypt.compare(newPassword, updatedPassword);
    console.log(`✅ Login test result: ${loginTest}`);
    
    res.json({ 
      msg: 'Contraseña de Maraña actualizada exitosamente',
      user: targetUser,
      new_password: newPassword,
      hash_length: hashedPassword.length,
      db_updated: updateResult.affectedRows > 0,
      login_test: loginTest,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error cambiando contraseña:', e.message);
    res.status(500).json({ 
      msg: 'Error al cambiar contraseña: ' + e.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para validar usuario y correo para recuperación de contraseña
app.post('/api/validate-user-email', async (req, res) => {
  try {
    const { usuario, correo } = req.body;
    console.log(`🔍 Validando usuario: ${usuario}, correo: ${correo}`);
    
    if (!usuario || !correo) {
      return res.status(400).json({ 
        msg: 'Faltan campos: usuario y correo son requeridos',
        timestamp: new Date().toISOString()
      });
    }
    
    // Buscar en tabla clientes
    const [clientesRows] = await pool.query(`
      SELECT cod_cliente, usuario, nombre, correo 
      FROM clientes 
      WHERE usuario = ? AND correo = ? AND estado = 'Activo'
    `, [usuario, correo]);
    
    // Buscar en tabla tecnicos
    const [tecnicosRows] = await pool.query(`
      SELECT cod_tecnico, usuario, nombre, correo 
      FROM tecnicos 
      WHERE usuario = ? AND correo = ? AND estado = 'Activo'
    `, [usuario, correo]);
    
    let userData = null;
    let userType = '';
    
    if (clientesRows.length > 0) {
      userData = clientesRows[0];
      userType = 'cliente';
      console.log(`✅ Cliente encontrado: ${userData.usuario}`);
    } else if (tecnicosRows.length > 0) {
      userData = tecnicosRows[0];
      userType = 'tecnico';
      console.log(`✅ Técnico encontrado: ${userData.usuario}`);
    }
    
    if (!userData) {
      return res.status(404).json({ 
        msg: 'Usuario y correo no coinciden o usuario inactivo',
        timestamp: new Date().toISOString()
      });
    }
    
    // Generar token temporal para recuperación (válido por 30 minutos)
    const resetToken = jwt.sign(
      { 
        id: userType === 'cliente' ? userData.cod_cliente : userData.cod_tecnico,
        usuario: userData.usuario,
        tipo: userType
      },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '30m' }
    );
    
    console.log(`✅ Validación exitosa para ${userType}: ${userData.usuario}`);
    
    res.json({
      msg: 'Validación exitosa',
      user_data: {
        id: userType === 'cliente' ? userData.cod_cliente : userData.cod_tecnico,
        usuario: userData.usuario,
        nombre: userData.nombre,
        correo: userData.correo,
        tipo: userType
      },
      reset_token: resetToken,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error en validación usuario/correo:', e.message);
    res.status(500).json({ 
      msg: 'Error en validación: ' + e.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint para actualizar contraseña con encriptación
app.post('/api/reset-password', async (req, res) => {
  try {
    const { reset_token, nueva_password, confirmar_password } = req.body;
    console.log(`🔧 Solicitando reset de contraseña con token`);
    
    if (!reset_token || !nueva_password || !confirmar_password) {
      return res.status(400).json({ 
        msg: 'Faltan campos: reset_token, nueva_password y confirmar_password son requeridos',
        timestamp: new Date().toISOString()
      });
    }
    
    if (nueva_password !== confirmar_password) {
      return res.status(400).json({ 
        msg: 'Las contraseñas no coinciden',
        timestamp: new Date().toISOString()
      });
    }
    
    // Verificar el token
    let decoded;
    try {
      decoded = jwt.verify(reset_token, process.env.JWT_SECRET || 'secret');
      console.log(`✅ Token válido para usuario: ${decoded.usuario}, tipo: ${decoded.tipo}`);
    } catch (tokenError) {
      return res.status(401).json({ 
        msg: 'Token inválido o expirado',
        timestamp: new Date().toISOString()
      });
    }
    
    // Encriptar la nueva contraseña
    const hashedPassword = await bcrypt.hash(nueva_password, 10);
    console.log(`🔐 Contraseña encriptada (longitud: ${hashedPassword.length})`);
    
    let updateResult;
    
    // Actualizar contraseña según el tipo de usuario
    if (decoded.tipo === 'cliente') {
      [updateResult] = await pool.query(
        'UPDATE clientes SET password = ? WHERE cod_cliente = ?',
        [hashedPassword, decoded.id]
      );
    } else if (decoded.tipo === 'tecnico') {
      [updateResult] = await pool.query(
        'UPDATE tecnicos SET password = ? WHERE cod_tecnico = ?',
        [hashedPassword, decoded.id]
      );
    }
    
    console.log(`📊 Contraseña actualizada: ${updateResult.affectedRows} filas afectadas`);
    
    if (updateResult.affectedRows === 0) {
      return res.status(500).json({ 
        msg: 'No se pudo actualizar la contraseña',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log(`✅ Contraseña actualizada exitosamente para ${decoded.usuario}`);
    
    res.json({
      msg: 'Contraseña actualizada exitosamente',
      usuario: decoded.usuario,
      tipo: decoded.tipo,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Error en reset de contraseña:', e.message);
    res.status(500).json({ 
      msg: 'Error al actualizar contraseña: ' + e.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Endpoint de prueba para verificar que el servidor funciona
app.get('/api/test', (req, res) => {
  console.log('🧪 Endpoint de prueba alcanzado');
  res.json({ msg: 'Servidor funcionando correctamente', timestamp: new Date().toISOString() });
});

// Endpoint para modificar privilegio de técnico (usando usuario como identificador)
app.patch('/api/tecnicos/:usuario/privilegio', async (req, res) => {
  try {
    console.log('🔧 Endpoint PATCH alcanzado para modificar privilegio');
    // Decodificar el parámetro usuario para manejar caracteres especiales como ñ
    const usuario = decodeURIComponent(req.params.usuario);
    const { cod_privilegio } = req.body;
    
    console.log(`� Modificando privilegio del técnico: ${usuario}`);
    console.log(`� Nuevo privilegio: ${cod_privilegio}`);
    
    if (!cod_privilegio) {
      return res.status(400).json({ 
        msg: 'El código de privilegio es requerido',
        timestamp: new Date().toISOString()
      });
    }

    // Validar que el privilegio sea uno de los permitidos
    const privilegiosPermitidos = ['92', '50']; // Administrador, Técnico
    if (!privilegiosPermitidos.includes(cod_privilegio)) {
      return res.status(400).json({ 
        msg: 'Privilegio no válido. Solo se permite: Administrador (92) o Técnico (50)',
        timestamp: new Date().toISOString()
      });
    }

    // Obtener información del usuario logueado desde el token (si existe)
    const authHeader = req.headers.authorization;
    let usuarioLogueado = null;
    let privilegioLogueado = null;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
        usuarioLogueado = decoded.usuario || decoded.email;
        privilegioLogueado = decoded.cod_privilegio;
        
        console.log(`� Usuario logueado: ${usuarioLogueado}, privilegio: ${privilegioLogueado}`);
        
        // Validar permisos: solo Master (99) o Administrador (92) pueden cambiar privilegios
        if (privilegioLogueado !== '99' && privilegioLogueado !== '92') {
          console.log(`❌ ERROR: Usuario ${usuarioLogueado} con privilegio ${privilegioLogueado} no tiene permisos para cambiar privilegios`);
          return res.status(403).json({ 
            msg: 'Permisos insuficientes: Solo los Administradores y Masters pueden cambiar privilegios',
            timestamp: new Date().toISOString()
          });
        }
        
        console.log(`✅ Permisos válidos para cambiar privilegios`);
      } catch (tokenError) {
        console.log('⚠️ Token inválido o no proporcionado, permitiendo operación (modo desarrollo)');
      }
    } else {
      console.log('⚠️ No se proporcionó token de autenticación, permitiendo operación (modo desarrollo)');
    }

    if (!usuario) {
      return res.status(400).json({ msg: 'usuario es requerido' });
    }

    const [result] = await pool.query(
      'UPDATE tecnicos SET cod_privilegio = ? WHERE usuario = ?',
      [cod_privilegio, usuario]
    );

    if (result.affectedRows === 0) {
      console.log('❌ Técnico no encontrado con usuario:', usuario);
      return res.status(404).json({ msg: 'Tecnico no encontrado' });
    }

    console.log('✅ Privilegio modificado exitosamente para:', usuario);
    return res.json({ msg: 'Privilegio modificado exitosamente' });
  } catch (e) {
    console.error('Update privilegio error:', e.message);
    return res.status(500).json({ msg: 'No se pudo modificar el privilegio' });
  }
});

// Endpoint para inactivar/activar técnico (usando usuario como identificador)
app.put('/api/tecnicos/:usuario/inactivar', async (req, res) => {
  try {
    // Decodificar el parámetro usuario para manejar caracteres especiales como ñ
    const usuario = decodeURIComponent(req.params.usuario);
    const { estado } = req.body;
    
    console.log('🔧 Cambiando estado del técnico:', usuario);
    console.log('🔧 Parámetro original:', req.params.usuario);
    console.log('🔧 Nuevo estado:', estado);
    
    if (!usuario || !estado) {
      return res.status(400).json({ msg: 'usuario y estado son requeridos' });
    }

    // Validar que el estado sea uno de los permitidos
    const estadosPermitidos = ['Activo', 'Inactivo'];
    if (!estadosPermitidos.includes(estado)) {
      return res.status(400).json({ 
        msg: 'Estado no válido. Solo se permite: Activo o Inactivo',
        timestamp: new Date().toISOString()
      });
    }

    // Obtener información del usuario logueado desde el token (si existe)
    const authHeader = req.headers.authorization;
    let usuarioLogueado = null;
    let privilegioLogueado = null;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
        usuarioLogueado = decoded.usuario || decoded.email;
        privilegioLogueado = decoded.cod_privilegio;
        
        console.log(`🔍 Usuario logueado: ${usuarioLogueado}, privilegio: ${privilegioLogueado}`);
        
        // Validar permisos: solo Master (99) o Administrador (92) pueden cambiar estados
        if (privilegioLogueado !== '99' && privilegioLogueado !== '92') {
          console.log(`❌ ERROR: Usuario ${usuarioLogueado} con privilegio ${privilegioLogueado} no tiene permisos para cambiar estados`);
          return res.status(403).json({ 
            msg: 'Permisos insuficientes: Solo los Administradores y Masters pueden cambiar el estado de los técnicos',
            timestamp: new Date().toISOString()
          });
        }
        
        console.log(`✅ Permisos válidos para cambiar estado`);
      } catch (tokenError) {
        console.log('⚠️ Token inválido o no proporcionado, permitiendo operación (modo desarrollo)');
      }
    } else {
      console.log('⚠️ No se proporcionó token de autenticación, permitiendo operación (modo desarrollo)');
    }

    const [result] = await pool.query(
      'UPDATE tecnicos SET estado = ? WHERE usuario = ?',
      [estado, usuario]
    );

    if (result.affectedRows === 0) {
      console.log('❌ Técnico no encontrado con usuario:', usuario);
      return res.status(404).json({ msg: 'Tecnico no encontrado' });
    }

    const accion = estado === 'Activo' ? 'activado' : 'inactivado';
    console.log('✅ Técnico ${accion} exitosamente:', usuario);
    return res.json({ msg: `Tecnico ${accion} exitosamente` });
  } catch (e) {
    console.error('Inactivar/activar tecnico error:', e.message);
    return res.status(500).json({ msg: 'No se pudo actualizar el estado del tecnico' });
  }
});

// Endpoint para inactivar técnico (mantener para compatibilidad)
app.delete('/api/tecnicos/:cod_tecnico', async (req, res) => {
  try {
    const { cod_tecnico } = req.params;
    
    if (!cod_tecnico) {
      return res.status(400).json({ msg: 'cod_tecnico es requerido' });
    }

    const [result] = await pool.query(
      'UPDATE tecnicos SET estado = ? WHERE cod_tecnico = ?',
      ['Inactivo', cod_tecnico]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Tecnico no encontrado' });
    }

    return res.json({ msg: 'Tecnico inactivado exitosamente' });
  } catch (e) {
    console.error('Inactivar tecnico error:', e.message);
    return res.status(500).json({ msg: 'No se pudo inactivar el técnico' });
  }
});

// Endpoint temporal para actualizar contraseña de Master
app.post('/api/update-password', async (req, res) => {
  const { usuario, nueva_password } = req.body;
  
  if (!usuario || !nueva_password) {
    return res.status(400).json({ msg: 'Usuario y nueva contraseña son requeridos' });
  }

  try {
    const hashed = await bcrypt.hash(nueva_password, 10);
    
    const [result] = await pool.query(
      'UPDATE tecnicos SET password = ? WHERE usuario = ?',
      [hashed, usuario]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }
    
    return res.json({ msg: 'Contraseña actualizada exitosamente' });
  } catch (e) {
    console.error('Update password error:', e.message);
    return res.status(500).json({ msg: 'Error al actualizar contraseña' });
  }
});

// Obtener lista de privilegios disponibles
app.get('/api/privilegios', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT cod_privilegio, rol FROM Privilegios ORDER BY cod_privilegio`
    );
    return res.json(rows);
  } catch (e) {
    console.error('List privilegios error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener los privilegios' });
  }
});

// Crear nuevo técnico
app.post('/api/tecnicos', async (req, res) => {
  try {
    const { nombre, usuario, correo, password, num_telefono, cod_privilegio } = req.body;
    
    if (!nombre || !usuario || !password) {
      return res.status(400).json({ msg: 'Nombre, usuario y password son requeridos' });
    }

    // Verificar que el privilegio exista
    if (cod_privilegio) {
      const [privRows] = await pool.query('SELECT cod_privilegio FROM Privilegios WHERE cod_privilegio = ?', [cod_privilegio]);
      if (privRows.length === 0) {
        return res.status(400).json({ msg: 'El privilegio especificado no existe' });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await pool.query(
      `INSERT INTO tecnicos (nombre, usuario, correo, password, num_telefono, cod_privilegio)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [nombre, usuario, correo, hashedPassword, num_telefono || null, cod_privilegio || null]
    );

    return res.status(201).json({ 
      msg: 'Tecnico creado exitosamente',
      cod_tecnico: result.insertId 
    });
  } catch (e) {
    console.error('Create tecnico error:', e.message);
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ msg: 'El usuario ya está registrado' });
    }
    return res.status(500).json({ msg: 'No se pudo crear el técnico' });
  }
});

// Inactivar/activar cliente
app.put('/api/clientes/:id/inactivar', async (req, res) => {
  const id = Number(req.params.id);
  const { estado } = req.body;
  
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }
  
  if (!estado || !['Activo', 'Inactivo'].includes(estado)) {
    return res.status(400).json({ msg: 'Estado inválido. Debe ser "Activo" o "Inactivo"' });
  }

  try {
    const [result] = await pool.query('UPDATE clientes SET estado = ? WHERE cod_cliente = ?', [estado, id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Cliente no encontrado' });
    }
    
    return res.json({ msg: `Cliente ${estado === 'Activo' ? 'activado' : 'inactivado'} exitosamente` });
  } catch (e) {
    console.error('Update cliente estado error:', e.message);
    return res.status(500).json({ msg: 'No se pudo actualizar el estado del cliente' });
  }
});

// Inactivar/activar técnico
app.put('/api/tecnicos/:id/inactivar', async (req, res) => {
  const id = Number(req.params.id);
  const { estado } = req.body;
  
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }
  
  if (!estado || !['Activo', 'Inactivo'].includes(estado)) {
    return res.status(400).json({ msg: 'Estado inválido. Debe ser "Activo" o "Inactivo"' });
  }

  try {
    const [result] = await pool.query('UPDATE tecnicos SET estado = ? WHERE cod_tecnico = ?', [estado, id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Tecnico no encontrado' });
    }
    
    return res.json({ msg: `Tecnico ${estado === 'Activo' ? 'activado' : 'inactivado'} exitosamente` });
  } catch (e) {
    console.error('Update tecnico estado error:', e.message);
    return res.status(500).json({ msg: 'No se pudo actualizar el estado del técnico' });
  }
});

// Endpoint para obtener todas las categorías (sin autenticación para pruebas)
app.get('/api/categorias', async (req, res) => {
  try {
    console.log('📋 Obteniendo categorías desde la base de datos...');
    const [rows] = await pool.query(
      `SELECT cod_categoria, nombre, descripcion FROM categoria ORDER BY nombre`
    );
    console.log(`✅ Categorías encontradas: ${rows.length}`);
    rows.forEach(cat => {
      console.log(`  - ${cat.nombre} (cod: ${cat.cod_categoria})`);
    });
    return res.json(rows);
  } catch (e) {
    console.error('Get categorias error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las categorías' });
  }
});

// Endpoint para eliminar categorías específicas por código
app.delete('/api/categorias/:cod_categoria', async (req, res) => {
  try {
    const cod_categoria = Number(req.params.cod_categoria);
    
    if (!Number.isInteger(cod_categoria) || cod_categoria <= 0) {
      return res.status(400).json({ msg: 'Código de categoría inválido' });
    }

    const [result] = await pool.query(
      'DELETE FROM categoria WHERE cod_categoria = ?',
      [cod_categoria]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Categoría no encontrada' });
    }

    return res.json({ msg: 'Categoría eliminada correctamente' });
  } catch (e) {
    console.error('Delete categoria error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar la categoría' });
  }
});

// Endpoint para eliminar categorías específicas por nombre
app.delete('/api/categorias/nombre/:nombre', async (req, res) => {
  try {
    const { nombre } = req.params;

    const [result] = await pool.query(
      'DELETE FROM categoria WHERE nombre = ?',
      [nombre]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Categoría no encontrada' });
    }
    
    console.log(`✅ Categoría "${nombre}" eliminada (${result.affectedRows} filas afectadas)`);
    
    return res.json({ 
      msg: `Categoría "${nombre}" eliminada exitosamente`,
      affected_rows: result.affectedRows,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Delete categoria error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar la categoría' });
  }
});

// Endpoint para limpiar y reiniciar categorías (solo Laptop y PC Escritorio)
app.post('/api/categorias/clean', async (req, res) => {
  try {
    console.log('🔧 Limpiando tabla de categorías...');
    
    // Eliminar todas las categorías existentes
    await pool.query('DELETE FROM categoria');
    console.log('✅ Categorías existentes eliminadas');
    
    // Insertar solo las dos categorías deseadas
    await pool.query(`
      INSERT INTO categoria (cod_categoria, nombre, descripcion) VALUES
      (1, 'Laptop', 'Computadoras portátiles y notebooks'),
      (2, 'PC Escritorio', 'Computadoras de escritorio y torres')
    `);
    console.log('✅ Categorías Laptop y PC Escritorio insertadas');
    
    // Verificar el resultado
    const [result] = await pool.query('SELECT * FROM categoria ORDER BY cod_categoria');
    
    return res.json({ 
      msg: 'Categorías limpiadas y reiniciadas exitosamente',
      categorias: result,
      timestamp: new Date().toISOString()
    });
    
  } catch (e) {
    console.error('Clean categorias error:', e.message);
    return res.status(500).json({ msg: 'No se pudo limpiar las categorías' });
  }
});

// Endpoint temporal para generar hash bcrypt
app.post('/api/generate-hash', async (req, res) => {
  const { password } = req.body;
  if (!password) return res.status(400).json({ msg: 'Password requerido' });
  
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    return res.json({ hashedPassword });
  } catch (e) {
    console.error('Hash error:', e.message);
    return res.status(500).json({ msg: 'Error generando hash' });
  }
});

const port = process.env.PORT || 3000;
ensureSchema()
  .then(() => {
    app.listen(port, () => console.log('Server on', port));
  })
  .catch((e) => {
    console.error('Schema init error:', e.message);
    process.exit(1);
  });
