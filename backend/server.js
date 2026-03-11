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

const port = process.env.PORT || 3000;
app.listen(port, () => console.log('Server on', port));
