const express = require('express');
const app = express();
const port = 3000;

// ALB health check
app.get('/health', (req, res) => {
  res.status(200).send('OK - Container is healthy');
});

// dummy endpoint
app.get('/', (req, res) => {
  res.send('Product Inventory API v1');
});

app.listen(port, () => {
  console.log(`App escuchando en el puerto ${port}`);
});