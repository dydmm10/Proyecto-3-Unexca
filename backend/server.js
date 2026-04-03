require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'flutter_login',
  waitForConnections: true,
  connectionLimit: 10,
});

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS work_orders (
      id INT AUTO_INCREMENT PRIMARY KEY,
      category VARCHAR(100) NOT NULL,
      description TEXT NOT NULL,
      priority VARCHAR(20) NOT NULL,
      status VARCHAR(30) NOT NULL DEFAULT 'ABIERTA',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS equipments (
      id INT AUTO_INCREMENT PRIMARY KEY,
      type VARCHAR(40) NOT NULL,
      brand VARCHAR(120) NOT NULL,
      model VARCHAR(120) NOT NULL,
      serial VARCHAR(120) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

app.get('/api/users/exists', async (req, res) => {
  const email = String(req.query.email || '').trim();
  if (!email) return res.status(400).json({ msg: 'Email requerido' });

  try {
    const [rows] = await pool.query('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);
    return res.json({ exists: rows.length > 0 });
  } catch (e) {
    console.error('Exists error:', e.message);
    return res.status(500).json({ msg: 'Error verificando email' });
  }
});

app.post('/api/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ msg: 'Faltan campos' });
  const hashed = await bcrypt.hash(password, 10);
  try {
    await pool.query('INSERT INTO users (email, password) VALUES (?, ?)', [email, hashed]);
    res.json({ msg: 'Usuario creado' });
  } catch (e) {
    console.error('Register error:', e.message);
    return res.status(400).json({ msg: 'Email ya registrado' });
  }
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ msg: 'Faltan campos' });
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  const user = rows[0];
  if (!user) return res.status(401).json({ msg: 'Credenciales inválidas' });
  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ msg: 'Credenciales inválidas' });
  const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
  res.json({ token });
});

app.get('/api/protected', async (req, res) => {
  const auth = req.headers.authorization;
  if (!auth) return res.status(401).json({ msg: 'No autorizado' });
  const parts = auth.split(' ');
  if (parts.length !== 2) return res.status(401).json({ msg: 'No autorizado' });
  const token = parts[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    res.json({ msg: 'Acceso concedido', payload });
  } catch (e) {
    res.status(401).json({ msg: 'Token inválido' });
  }
});

app.post('/api/work-orders', async (req, res) => {
  const category = String(req.body.category || '').trim();
  const description = String(req.body.description || '').trim();
  const priority = String(req.body.priority || '').trim().toUpperCase();

  if (!category || !description || !priority) {
    return res.status(400).json({ msg: 'Faltan campos requeridos' });
  }

  if (!['BAJA', 'MEDIA', 'ALTA'].includes(priority)) {
    return res.status(400).json({ msg: 'Prioridad inválida' });
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO work_orders (category, description, priority) VALUES (?, ?, ?)',
      [category, description, priority],
    );
    return res.status(201).json({ id: result.insertId, msg: 'Orden creada' });
  } catch (e) {
    console.error('Create work-order error:', e.message);
    return res.status(500).json({ msg: 'No se pudo crear la orden' });
  }
});

app.get('/api/work-orders', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, category, description, priority, status, created_at
       FROM work_orders
       ORDER BY created_at DESC`,
    );
    return res.json(rows);
  } catch (e) {
    console.error('List work-orders error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener las órdenes' });
  }
});

app.delete('/api/work-orders/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }

  try {
    const [result] = await pool.query('DELETE FROM work_orders WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Orden no encontrada' });
    }
    return res.json({ msg: 'Orden eliminada' });
  } catch (e) {
    console.error('Delete work-order error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar la orden' });
  }
});

app.post('/api/equipments', async (req, res) => {
  const type = String(req.body.type || '').trim();
  const brand = String(req.body.brand || '').trim();
  const model = String(req.body.model || '').trim();
  const serial = String(req.body.serial || '').trim();

  if (!type || !brand || !model || !serial) {
    return res.status(400).json({ msg: 'Faltan campos requeridos' });
  }

  try {
    const [result] = await pool.query(
      'INSERT INTO equipments (type, brand, model, serial) VALUES (?, ?, ?, ?)',
      [type, brand, model, serial],
    );
    return res.status(201).json({ id: result.insertId, msg: 'Equipo creado' });
  } catch (e) {
    console.error('Create equipment error:', e.message);
    return res.status(500).json({ msg: 'No se pudo crear el equipo' });
  }
});

app.get('/api/equipments', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, type, brand, model, serial, created_at
       FROM equipments
       ORDER BY created_at DESC`,
    );
    return res.json(rows);
  } catch (e) {
    console.error('List equipments error:', e.message);
    return res.status(500).json({ msg: 'No se pudo obtener equipos' });
  }
});

app.delete('/api/equipments/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ msg: 'Id inválido' });
  }

  try {
    const [result] = await pool.query('DELETE FROM equipments WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ msg: 'Equipo no encontrado' });
    }
    return res.json({ msg: 'Equipo eliminado' });
  } catch (e) {
    console.error('Delete equipment error:', e.message);
    return res.status(500).json({ msg: 'No se pudo eliminar el equipo' });
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
