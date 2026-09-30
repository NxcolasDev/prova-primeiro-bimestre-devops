const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS reservas (
      id     SERIAL PRIMARY KEY,
      cliente VARCHAR(255) NOT NULL,
      data    TIMESTAMP   NOT NULL,
      status  VARCHAR(50)  NOT NULL
    )
  `);
}

// GET /health
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// POST /reservas
app.post('/reservas', async (req, res) => {
  const { cliente, data, status } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO reservas (cliente, data, status) VALUES ($1, $2, $3) RETURNING *',
      [cliente, data, status]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /reservas
app.get('/reservas', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM reservas ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /reservas/:id
app.get('/reservas/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM reservas WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Reserva não encontrada' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /reservas/:id
app.put('/reservas/:id', async (req, res) => {
  const { cliente, data, status } = req.body;
  try {
    const result = await pool.query(
      'UPDATE reservas SET cliente = $1, data = $2, status = $3 WHERE id = $4 RETURNING *',
      [cliente, data, status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Reserva não encontrada' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /reservas/:id
app.delete('/reservas/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM reservas WHERE id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Reserva não encontrada' });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;

initDb()
  .then(() => {
    app.listen(PORT, () => console.log(`API rodando na porta ${PORT}`));
  })
  .catch((err) => {
    console.error('Erro ao inicializar o banco de dados:', err);
    process.exit(1);
  });
