#!/usr/bin/env node
/**
 * BB TPP API Simulator - Main Server
 * 
 * A curl-friendly API simulator for testing UK Open Banking flows with SaltEdge.
 * No UI - pure REST API interface for automation and testing.
 */

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import aisRouter from './routes/ais.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// API Routes
app.use('/api/ais', aisRouter);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    service: 'bb-tpp-api-simulator'
  });
});

// Root endpoint with API documentation
app.get('/', (req, res) => {
  res.json({
    name: 'BB TPP API Simulator',
    description: 'curl-friendly API simulator for UK Open Banking testing with SaltEdge',
    version: '1.0.0',
    endpoints: {
      health: {
        method: 'GET',
        path: '/api/health',
        description: 'Health check endpoint'
      },
      createConsent: {
        method: 'POST',
        path: '/api/ais/consent',
        description: 'Create AIS consent and get authorization URL',
        example: 'curl -X POST http://localhost:3002/api/ais/consent -H "Content-Type: application/json" -d "{}"'
      },
      exchangeToken: {
        method: 'POST',
        path: '/api/ais/token',
        description: 'Exchange authorization code for access token',
        example: 'curl -X POST http://localhost:3002/api/ais/token -H "Content-Type: application/json" -d \'{"code":"YOUR_AUTH_CODE"}\''
      },
      getAccounts: {
        method: 'GET',
        path: '/api/ais/accounts',
        description: 'Fetch all accounts',
        example: 'curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN"'
      },
      getTransactions: {
        method: 'GET',
        path: '/api/ais/accounts/:accountId/transactions',
        description: 'Fetch transactions for an account',
        example: 'curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/transactions?accessToken=Bearer%20YOUR_TOKEN"'
      },
      getBalances: {
        method: 'GET',
        path: '/api/ais/accounts/:accountId/balances',
        description: 'Fetch balances for an account',
        example: 'curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/balances?accessToken=Bearer%20YOUR_TOKEN"'
      },
      getStandingOrders: {
        method: 'GET',
        path: '/api/ais/accounts/:accountId/standing-orders',
        description: 'Fetch standing orders for an account',
        example: 'curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/standing-orders?accessToken=Bearer%20YOUR_TOKEN"'
      },
      refreshAccounts: {
        method: 'POST',
        path: '/api/ais/accounts/refresh',
        description: 'Trigger account data refresh',
        example: 'curl -X POST http://localhost:3002/api/ais/accounts/refresh -H "Content-Type: application/json" -d \'{"accessToken":"Bearer YOUR_TOKEN"}\''
      },
      getRefreshStatus: {
        method: 'GET',
        path: '/api/ais/accounts/refresh/status',
        description: 'Check refresh status',
        example: 'curl "http://localhost:3002/api/ais/accounts/refresh/status?accessToken=Bearer%20YOUR_TOKEN"'
      },
      getConsent: {
        method: 'GET',
        path: '/api/ais/consent/:consentId',
        description: 'Get consent details by ID',
        example: 'curl "http://localhost:3002/api/ais/consent/CONSENT_ID"'
      }
    },
    documentation: 'See README.md for detailed examples and workflow'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Endpoint ${req.method} ${req.path} does not exist`,
    availableEndpoints: 'Visit / for API documentation'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error',
    details: err.response?.data || err.details || null
  });
});

// Start server
app.listen(PORT, () => {
  console.log('\n' + '='.repeat(70));
  console.log('🚀 Backbase TPP API Simulator');
  console.log('='.repeat(70));
  console.log(`\n   Server:        http://localhost:${PORT}`);
  console.log(`   Provider:      ${process.env.OB_PROVIDER_CODE || 'Not configured'}`);
  console.log(`   SaltEdge:      ${process.env.PROTOCOL || 'https'}://${process.env.PRIORA_URL || 'priora.saltedge.com'}`);
  console.log(`   Redirect URI:  ${process.env.REDIRECT_URI || 'Not configured'}`);
  console.log(`\n   Documentation: http://localhost:${PORT}`);
  console.log(`   Health Check:  http://localhost:${PORT}/api/health`);
  console.log('\n' + '='.repeat(70));
  console.log('\n✨ Ready to accept curl commands!\n');
  console.log('Quick Start:');
  console.log(`   curl -X POST http://localhost:${PORT}/api/ais/consent -H "Content-Type: application/json" -d "{}"\n`);
});

export default app;

