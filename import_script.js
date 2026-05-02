// Script para importar datos a Railway
const fs = require('fs');
const path = require('path');

// Agregar este endpoint a tu server.js
app.post('/api/import-database', async (req, res) => {
  try {
    const sqlFiles = [
      'database/categoria.sql',
      'database/clientes.sql', 
      'database/equipos.sql',
      'database/privilegios.sql',
      'database/tecnicos.sql',
      'database/ordenes_reclamos.sql'
    ];

    for (const file of sqlFiles) {
      const filePath = path.join(__dirname, file);
      if (fs.existsSync(filePath)) {
        const sql = fs.readFileSync(filePath, 'utf8');
        await pool.query(sql);
        console.log(`✅ Importado: ${file}`);
      }
    }

    res.json({ message: 'Base de datos importada exitosamente' });
  } catch (error) {
    console.error('Error importando:', error);
    res.status(500).json({ error: error.message });
  }
});
