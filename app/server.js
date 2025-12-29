const express = require('express');
const { Pool } = require('pg');
const multer = require('multer');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const app = express();
const port = 3000;

// S3 conf
const s3 = new S3Client({ region: process.env.AWS_REGION });
const upload = multer({ storage: multer.memoryStorage() });

// DB conf
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD, // THIS WILL COME FROM SECRETS MANAGER
  port: 5432,
  ssl: { rejectUnauthorized: false }
});

app.use(express.json());

// Health Check
app.get('/health', (req, res) => res.status(200).send('OK - Container is healthy'));

// Inicializar Tabla (Endpoint temporal para crear la tabla)
app.get('/init-db', async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        price DECIMAL(10,2),
        image_url TEXT
      );
    `);
    res.send('Tabla products lista.');
  } catch (err) {
    console.error(err);
    res.status(500).send(err.message);
  }
});

// GET: Get all products
app.get('/products', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error DB');
  }
});

// POST: Create product with image upload
app.post('/products', upload.single('image'), async (req, res) => {
  const { name, price } = req.body;
  const file = req.file;

  if (!name || !price) return res.status(400).send('Missing data');

  let imageUrl = null;

  try {
    // A. Upload image to S3
    if (file) {
      const fileName = `${Date.now()}-${file.originalname}`;
      await s3.send(new PutObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: fileName,
        Body: file.buffer,
        ContentType: file.mimetype
      }));
      imageUrl = `https://${process.env.S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;
    }

    // B. Save in RDS
    const result = await pool.query(
      'INSERT INTO products (name, price, image_url) VALUES ($1, $2, $3) RETURNING *',
      [name, price, imageUrl]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send(err.message);
  }
});

app.listen(port, () => {
  console.log(`App v2 corriendo en puerto ${port}`);
});