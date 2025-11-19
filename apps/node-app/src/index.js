const express = require('express');
const { Pool } = require('pg');
const redis = require('redis');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Redis connection
let redisClient;
(async () => {
  try {
    redisClient = redis.createClient({
      url: process.env.REDIS_URL,
    });
    
    redisClient.on('error', (err) => console.error('Redis Client Error', err));
    redisClient.on('connect', () => console.log('✅ Connected to Redis'));
    
    await redisClient.connect();
  } catch (err) {
    console.error('Failed to connect to Redis:', err);
  }
})();

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Database connection error:', err);
  } else {
    console.log('✅ Connected to PostgreSQL at', res.rows[0].now);
  }
});

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    service: 'node-app',
    timestamp: new Date().toISOString()
  });
});

// Home endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Node.js App on Raspberry Pi!',
    endpoints: {
      health: '/health',
      users: '/users',
      posts: '/posts',
      cache: '/cache/:key',
    }
  });
});

// Get all users
app.get('/users', async (req, res) => {
  try {
    // Try to get from cache first
    if (redisClient && redisClient.isOpen) {
      const cached = await redisClient.get('users:all');
      if (cached) {
        console.log('📦 Cache hit for users');
        return res.json({
          source: 'cache',
          data: JSON.parse(cached)
        });
      }
    }

    // Get from database
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    
    // Cache the result
    if (redisClient && redisClient.isOpen) {
      await redisClient.setEx('users:all', 60, JSON.stringify(result.rows));
    }
    
    res.json({
      source: 'database',
      data: result.rows
    });
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get user by ID
app.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching user:', err);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// Create user
app.post('/users', async (req, res) => {
  try {
    const { username, email } = req.body;
    
    if (!username || !email) {
      return res.status(400).json({ error: 'Username and email required' });
    }
    
    const result = await pool.query(
      'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING *',
      [username, email]
    );
    
    // Invalidate cache
    if (redisClient && redisClient.isOpen) {
      await redisClient.del('users:all');
    }
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating user:', err);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Get all posts
app.get('/posts', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT p.*, u.username, u.email 
      FROM posts p 
      JOIN users u ON p.user_id = u.id 
      ORDER BY p.created_at DESC
    `);
    
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching posts:', err);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

// Create post
app.post('/posts', async (req, res) => {
  try {
    const { user_id, title, content } = req.body;
    
    if (!user_id || !title) {
      return res.status(400).json({ error: 'user_id and title required' });
    }
    
    const result = await pool.query(
      'INSERT INTO posts (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
      [user_id, title, content]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating post:', err);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Cache operations
app.get('/cache/:key', async (req, res) => {
  try {
    if (!redisClient || !redisClient.isOpen) {
      return res.status(503).json({ error: 'Redis not available' });
    }
    
    const { key } = req.params;
    const value = await redisClient.get(key);
    
    if (value === null) {
      return res.status(404).json({ error: 'Key not found' });
    }
    
    res.json({ key, value });
  } catch (err) {
    console.error('Error getting cache:', err);
    res.status(500).json({ error: 'Failed to get cache' });
  }
});

app.post('/cache/:key', async (req, res) => {
  try {
    if (!redisClient || !redisClient.isOpen) {
      return res.status(503).json({ error: 'Redis not available' });
    }
    
    const { key } = req.params;
    const { value, ttl } = req.body;
    
    if (value === undefined) {
      return res.status(400).json({ error: 'value required' });
    }
    
    if (ttl) {
      await redisClient.setEx(key, ttl, String(value));
    } else {
      await redisClient.set(key, String(value));
    }
    
    res.json({ key, value, ttl: ttl || 'no expiry' });
  } catch (err) {
    console.error('Error setting cache:', err);
    res.status(500).json({ error: 'Failed to set cache' });
  }
});

// Stats endpoint
app.get('/stats', async (req, res) => {
  try {
    const userCount = await pool.query('SELECT COUNT(*) FROM users');
    const postCount = await pool.query('SELECT COUNT(*) FROM posts');
    
    res.json({
      users: parseInt(userCount.rows[0].count),
      posts: parseInt(postCount.rows[0].count),
      redis_connected: redisClient && redisClient.isOpen,
      database_connected: true,
      uptime: process.uptime(),
      memory: process.memoryUsage()
    });
  } catch (err) {
    console.error('Error fetching stats:', err);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  if (redisClient && redisClient.isOpen) {
    await redisClient.quit();
  }
  await pool.end();
  process.exit(0);
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Node.js app listening on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.DATABASE_URL ? 'Configured' : 'Not configured'}`);
  console.log(`💾 Redis: ${process.env.REDIS_URL ? 'Configured' : 'Not configured'}`);
});
