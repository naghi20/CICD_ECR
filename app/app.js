// app.js - Simple Express.js application
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from containerized app!',
    environment: process.env.NODE_ENV || 'development',
    version: process.env.APP_VERSION || '1.0.0',
    hostname: require('os').hostname()
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    app: 'ECS Fargate Demo',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    platform: process.platform,
    nodeVersion: process.version
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App running on port ${port}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
