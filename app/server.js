const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

// root route
app.get('/', (req, res) => {
  res.json({
    message: 'App is running',
    hostname: os.hostname(),
    platform: os.platform(),
    uptime: Math.floor(os.uptime()) + ' seconds'
  });
});

// health check - ALB uses this to check if instance is healthy
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// returns system info - useful to see which instance is responding
app.get('/info', (req, res) => {
  res.json({
    hostname: os.hostname(),
    cpus: os.cpus().length,
    totalMemory: (os.totalmem() / 1024 / 1024).toFixed(0) + ' MB',
    freeMemory: (os.freemem() / 1024 / 1024).toFixed(0) + ' MB',
    nodeVersion: process.version
  });
});

// simulates CPU load for testing auto scaling
app.get('/load', (req, res) => {
  const duration = parseInt(req.query.seconds) || 10;
  const end = Date.now() + duration * 1000;

  // burn CPU for the specified duration
  while (Date.now() < end) {
    Math.sqrt(Math.random() * 999999);
  }

  res.json({
    message: `CPU stress ran for ${duration} seconds`,
    hostname: os.hostname()
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
