require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
require('./config/firebase'); // Firebase se inicializa aquí


const app = express();
const server = http.createServer(app); // Crear servidor HTTP
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'

app.use(cors());
app.use(express.json());

// Cargar rutas automáticamente desde `routes/index.js`
app.use('/api/1.0', require('./app/routes'));

server.listen(PORT, HOST, () => {
  console.log(`Servidor corriendo en http://${HOST}:${PORT}`);
});