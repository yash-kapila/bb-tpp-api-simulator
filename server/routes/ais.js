/**
 * AIS (Account Information Services) Routes
 * Simplified API routes designed for curl access
 */

import express from 'express';
import { 
  createAISConsent,
  exchangeCodeForToken,
  getAccounts, 
  getAccountTransactions, 
  getAccountBalances, 
  getAccountStandingOrders,
  refreshAccounts,
  getRefreshStatus,
  getConsentDetails
} from '../services/saltedge.js';

const router = express.Router();

/**
 * POST /api/ais/consent
 * Creates an AIS consent and returns the authorization URL
 * This is the main entry point - one curl command to get started
 * 
 * Body:
 * - providerCode (optional, defaults to env)
 * - redirectUri (optional, defaults to env)
 * - permissions (optional, uses defaults)
 */
router.post('/consent', async (req, res, next) => {
  try {
    const {
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk',
      redirectUri = process.env.REDIRECT_URI || 'https://backbase-dev.com/callback',
      permissions,
      transactionFromDateTime,
      transactionToDateTime,
      expirationDateTime
    } = req.body;

    console.log(`\n📝 Creating AIS consent...`);
    console.log(`   Provider: ${providerCode}`);
    console.log(`   Redirect URI: ${redirectUri}`);

    const result = await createAISConsent({
      providerCode,
      redirectUri,
      permissions,
      transactionFromDateTime,
      transactionToDateTime,
      expirationDateTime
    });

    console.log(`\n✅ SUCCESS! Consent ID: ${result.consentId}`);
    console.log(`\n📋 Next Steps:`);
    console.log(`   1. Copy the authorization URL below and open it in your browser`);
    console.log(`   2. Complete the authorization flow`);
    console.log(`   3. Extract the 'code' parameter from the redirect URL`);
    console.log(`   4. Use the code to exchange for access token\n`);

    res.json({
      success: true,
      message: 'Consent created successfully. Open the authorizationUrl in your browser to authorize.',
      data: result
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * POST /api/ais/token
 * Exchange authorization code for access token
 * 
 * Body:
 * - code (required) - authorization code from redirect
 * - providerCode (optional, defaults to env)
 * - redirectUri (optional, defaults to env, must match consent creation)
 */
router.post('/token', async (req, res, next) => {
  try {
    const {
      code,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk',
      redirectUri = process.env.REDIRECT_URI || 'https://backbase-dev.com/callback'
    } = req.body;

    if (!code) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required field: code (authorization code from redirect)' 
      });
    }

    console.log(`\n🔄 Exchanging authorization code for access token...`);
    console.log(`   Provider: ${providerCode}`);

    const result = await exchangeCodeForToken(providerCode, code, redirectUri);

    console.log(`\n✅ SUCCESS! Access token obtained`);
    console.log(`\n📋 Next Steps:`);
    console.log(`   Use the accessToken to fetch accounts, transactions, balances, etc.\n`);

    res.json({
      success: true,
      message: 'Access token obtained. Use it to access account data.',
      data: result
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/accounts
 * Fetches all accounts
 * 
 * Query params:
 * - accessToken (required) - Bearer token from token exchange
 * - providerCode (optional, defaults to env)
 */
router.get('/accounts', async (req, res, next) => {
  try {
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required query param: accessToken' 
      });
    }

    console.log(`\n📊 Fetching accounts...`);
    const accounts = await getAccounts(providerCode, accessToken);
    
    console.log(`✅ Retrieved ${accounts?.Data?.Account?.length || 0} accounts\n`);

    res.json({
      success: true,
      data: accounts
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * POST /api/ais/accounts/refresh
 * Triggers account data refresh
 * 
 * Body:
 * - accessToken (required)
 * - providerCode (optional, defaults to env)
 */
router.post('/accounts/refresh', async (req, res, next) => {
  try {
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.body;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required field: accessToken' 
      });
    }

    console.log(`\n🔄 Triggering account refresh...`);
    const result = await refreshAccounts(providerCode, accessToken);
    
    console.log(`✅ Refresh initiated\n`);

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/accounts/refresh/status
 * Gets the status of account data refresh
 * 
 * Query params:
 * - accessToken (required)
 * - providerCode (optional, defaults to env)
 */
router.get('/accounts/refresh/status', async (req, res, next) => {
  try {
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required query param: accessToken' 
      });
    }

    console.log(`\n📊 Checking refresh status...`);
    const status = await getRefreshStatus(providerCode, accessToken);
    
    console.log(`✅ Status retrieved\n`);

    res.json({
      success: true,
      data: status
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/accounts/:accountId/transactions
 * Fetches transactions for a specific account
 * 
 * Path params:
 * - accountId (required)
 * 
 * Query params:
 * - accessToken (required)
 * - providerCode (optional, defaults to env)
 */
router.get('/accounts/:accountId/transactions', async (req, res, next) => {
  try {
    const { accountId } = req.params;
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required query param: accessToken' 
      });
    }

    console.log(`\n💳 Fetching transactions for account: ${accountId}...`);
    const transactions = await getAccountTransactions(providerCode, accountId, accessToken);
    
    console.log(`✅ Retrieved ${transactions?.Data?.Transaction?.length || 0} transactions\n`);

    res.json({
      success: true,
      data: transactions
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/accounts/:accountId/balances
 * Fetches balances for a specific account
 * 
 * Path params:
 * - accountId (required)
 * 
 * Query params:
 * - accessToken (required)
 * - providerCode (optional, defaults to env)
 */
router.get('/accounts/:accountId/balances', async (req, res, next) => {
  try {
    const { accountId } = req.params;
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required query param: accessToken' 
      });
    }

    console.log(`\n💰 Fetching balances for account: ${accountId}...`);
    const balances = await getAccountBalances(providerCode, accountId, accessToken);
    
    console.log(`✅ Retrieved balances\n`);

    res.json({
      success: true,
      data: balances
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/accounts/:accountId/standing-orders
 * Fetches standing orders for a specific account
 * 
 * Path params:
 * - accountId (required)
 * 
 * Query params:
 * - accessToken (required)
 * - providerCode (optional, defaults to env)
 */
router.get('/accounts/:accountId/standing-orders', async (req, res, next) => {
  try {
    const { accountId } = req.params;
    const { 
      accessToken,
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    if (!accessToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Missing required query param: accessToken' 
      });
    }

    console.log(`\n📅 Fetching standing orders for account: ${accountId}...`);
    const standingOrders = await getAccountStandingOrders(providerCode, accountId, accessToken);
    
    console.log(`✅ Retrieved standing orders\n`);

    res.json({
      success: true,
      data: standingOrders
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

/**
 * GET /api/ais/consent/:consentId
 * Get consent details by consent ID
 * 
 * Path params:
 * - consentId (required)
 * 
 * Query params:
 * - providerCode (optional, defaults to env)
 */
router.get('/consent/:consentId', async (req, res, next) => {
  try {
    const { consentId } = req.params;
    const { 
      providerCode = process.env.OB_PROVIDER_CODE || 'backbase_dev_uk'
    } = req.query;

    console.log(`\n🔍 Fetching consent details: ${consentId}...`);
    const consent = await getConsentDetails(providerCode, consentId);
    
    console.log(`✅ Consent details retrieved\n`);

    res.json({
      success: true,
      data: consent
    });
  } catch (error) {
    console.error(`\n❌ ERROR: ${error.message}\n`);
    next(error);
  }
});

export default router;
