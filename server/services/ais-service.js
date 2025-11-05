/**
 * SaltEdge AIS Service - Account Information Services
 * 
 * Handles all communication with SaltEdge Priora API for Account Information Services.
 * This module provides functions for:
 * - Creating AIS consents (account-access-consents)
 * - Retrieving consent details
 * 
 * NOTE: PIS (Payment Initiation Services) is NOT implemented in this module.
 *       All functions here are specific to AIS/AISP operations.
 */

import axios from 'axios';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Load private key from file or environment variable
 */
function getPrivateKey() {
  const keyPath = process.env.OB_PRIVATE_KEY_PATH;
  const keyValue = process.env.OB_PRIVATE_KEY;

  if (keyValue && keyValue.includes('BEGIN')) {
    // Replace escaped newlines with actual newlines
    // This handles Azure Key Vault secrets that come as single-line strings
    return keyValue.replace(/\\n/g, '\n');
  }

  if (keyPath) {
    const fullPath = path.isAbsolute(keyPath) 
      ? keyPath 
      : path.join(__dirname, '..', '..', keyPath);
    
    if (fs.existsSync(fullPath)) {
      return fs.readFileSync(fullPath, 'utf8');
    }

  }

  throw new Error('Private key not configured. Set OB_PRIVATE_KEY or OB_PRIVATE_KEY_PATH in .env');
}

/**
 * Get base URL for SaltEdge Priora
 */
function getBaseUrl() {
  const protocol = process.env.PROTOCOL || 'https';
  const prioraUrl = process.env.PRIORA_URL || 'priora.saltedge.com';
  return `${protocol}://${prioraUrl}`;
}

/**
 * Get client ID (software ID)
 */
function getClientId() {
  const clientId = process.env.OB_SOFTWARE_ID;
  if (!clientId) {
    throw new Error('OB_SOFTWARE_ID not configured in .env');
  }
  return clientId;
}

/**
 * Generate a random UUID
 */
function generateUuid() {
  if (crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback for older Node versions
  const rnd = () => Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, '0');
  return `${rnd()}-${rnd().slice(0,4)}-${rnd().slice(0,4)}-${rnd().slice(0,4)}-${rnd()}${rnd()}`;
}

/**
 * Discover OIDC endpoints for a provider
 */
async function discoverOidc(providerCode) {
  const baseUrl = getBaseUrl();
  const url = `${baseUrl}/.well-known/openid-configuration/${encodeURIComponent(providerCode)}`;
  
  try {
    const { data } = await axios.get(url);
    
    if (!data.authorization_endpoint || !data.token_endpoint) {
      throw new Error('OIDC discovery missing required endpoints');
    }
    
    return {
      authorizationEndpoint: data.authorization_endpoint,
      tokenEndpoint: data.token_endpoint
    };
  } catch (error) {
    throw new Error(`OIDC discovery failed: ${error.message}`);
  }
}

/**
 * Get client credentials access token (client grant)
 * This is used to get an access token for initiating a consent flow
 */
export async function getClientGrantToken(providerCode, redirectUri) {
  const baseUrl = getBaseUrl();
  const clientId = getClientId();
  const privateKey = getPrivateKey();
  
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 600; // 10 minutes
  
  const header = { alg: 'RS256', typ: 'JWT' };
  const aud = `${baseUrl}/api/oidc/${encodeURIComponent(providerCode)}/tokens`;
  
  const payload = {
    iss: clientId,
    sub: clientId,
    aud,
    jti: generateUuid(),
    exp,
    iat: now
  };
  
  const clientAssertion = jwt.sign(payload, privateKey, { 
    algorithm: 'RS256', 
    header 
  });
  
  const body = {
    provider_code: providerCode,
    grant_type: 'client_credentials',
    client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
    client_assertion: clientAssertion,
    redirect_uri: redirectUri,
    client_id: clientId
  };
  
  try {
    const { data } = await axios.post(aud, body, {
      headers: { 'Content-Type': 'application/json' }
    });
    
    if (!data.access_token) {
      throw new Error('No access_token in response');
    }
    
    return `Bearer ${data.access_token}`;
  } catch (error) {
    console.error('Client grant token failed:');
    console.error('Status:', error.response?.status);
    console.error('Response data:', JSON.stringify(error.response?.data, null, 2));
    
    const errorMessage = error.response?.data?.error 
      || error.response?.data?.message 
      || JSON.stringify(error.response?.data)
      || error.message;
    throw new Error(`Failed to get client grant token: ${errorMessage}`);
  }
}

/**
 * Build request object JWT for authorization
 */
function buildRequestObjectJwt({ tokenEndpoint, consentId, redirectUri, scope }) {
  const clientId = getClientId();
  const privateKey = getPrivateKey();
  
  const issuedAt = Math.floor(Date.now() / 1000) - 1;
  const expiresAt = issuedAt + 60;
  
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    claims: {
      id_token: {
        openbanking_intent_id: { 
          essential: true, 
          value: consentId 
        }
      }
    },
    client_id: clientId,
    iss: clientId,
    sub: clientId,
    aud: tokenEndpoint,
    jti: generateUuid(),
    redirect_uri: redirectUri,
    scope,
    response_type: 'code',
    exp: expiresAt,
    iat: issuedAt
  };
  
  return jwt.sign(payload, privateKey, { algorithm: 'RS256', header });
}

/**
 * Build authorization URL
 */
function buildAuthorizationUrl(authorizationEndpoint, { redirectUri, scope, requestJwt }) {
  const clientId = getClientId();
  const u = new URL(authorizationEndpoint);
  u.searchParams.set('client_id', clientId);
  u.searchParams.set('response_type', 'code');
  u.searchParams.set('scope', scope);
  u.searchParams.set('request', requestJwt);
  u.searchParams.set('redirect_uri', redirectUri);
  return u.toString();
}

/**
 * Create AIS (Account Information Service) consent and return authorization URL
 * This creates an account-access-consent for reading account information
 * 
 * @param {string} providerCode - Open Banking provider code
 * @param {string} redirectUri - OAuth redirect URI
 * @param {Array<string>} permissions - AIS permissions (ReadAccounts, ReadBalances, etc.)
 * @param {string} expirationDateTime - Consent expiration date
 * @returns {Object} Consent details with authorization URL
 */
export async function createAISConsent({
  providerCode,
  redirectUri,
  permissions,
  expirationDateTime
}) {
  const baseUrl = getBaseUrl();
  const scope = 'openid accounts payments'; // AIS scope includes accounts
  
  // Default AIS permissions for account information access
  // Only include permissions valid for UK Open Banking v3.1
  const defaultAISPermissions = [
    'ReadAccountsBasic', 'ReadAccountsDetail', 'ReadBalances', 
    'ReadBeneficiariesBasic', 'ReadBeneficiariesDetail',
    'ReadTransactionsBasic', 'ReadTransactionsCredits',
    'ReadTransactionsDebits', 'ReadTransactionsDetail',
    'ReadPAN', 'ReadParty', 'ReadDirectDebits',
    'ReadStandingOrdersBasic', 'ReadStandingOrdersDetail'
  ];
  
  const isoNowPlusMinutes = (minutes) => {
    return new Date(Date.now() + minutes * 60000).toISOString();
  };
  
  const consentBody = {
    Data: {
      ExpirationDateTime: expirationDateTime || isoNowPlusMinutes(60 * 24 * 30),
      Permissions: permissions || defaultAISPermissions
    }
  };
  
  console.log(`🔄 Creating AIS consent for provider: ${providerCode}...`);
  
  // Discover OIDC endpoints
  const { authorizationEndpoint, tokenEndpoint } = await discoverOidc(providerCode);
  
  // Get client grant token
  const clientGrantAuthorization = await getClientGrantToken(providerCode, redirectUri);
  
  // Create AIS account-access-consent (AISP endpoint)
  const consentUrl = `${baseUrl}/api/${encodeURIComponent(providerCode)}/open-banking/v3.1/aisp/account-access-consents`;
  
  try {
    const { data } = await axios.post(consentUrl, consentBody, {
      headers: {
        'Authorization': clientGrantAuthorization,
        'Content-Type': 'application/json'
      }
    });
    
    const consentId = data?.Data?.ConsentId;
    if (!consentId) {
      throw new Error('No ConsentId in response');
    }
    
    console.log(`✅ AIS Consent created: ${consentId}`);
    
    // Build request JWT for AIS authorization
    const requestJwt = buildRequestObjectJwt({
      tokenEndpoint,
      consentId,
      redirectUri,
      scope
    });
    
    // Build AIS authorization URL
    const authorizationUrl = buildAuthorizationUrl(authorizationEndpoint, {
      redirectUri,
      scope,
      requestJwt
    });
    
    console.log(`🔗 AIS Authorization URL generated`);
    
    return {
      consentId,
      authorizationUrl,
      status: data?.Data?.Status,
    };
  } catch (error) {
    console.error('❌ AIS Consent creation failed:');
    console.error('Status:', error.response?.status);
    console.error('Response data:', JSON.stringify(error.response?.data, null, 2));
    
    const errorMessage = error.response?.data?.error 
      || error.response?.data?.message 
      || JSON.stringify(error.response?.data)
      || error.message;
    throw new Error(`Failed to create AIS consent: ${errorMessage}`);
  }
}

/**
 * Get AIS consent details by consent ID
 * A TPP may optionally retrieve an account-access-consent resource that they have created to check its status.
 * This is an AIS-specific operation for account-access-consents (not payment consents).
 * 
 * @param {string} providerCode - Open Banking provider code
 * @param {string} consentId - AIS consent identifier
 * @returns {Object} AIS consent details including status, permissions, and expiration
 */
export async function getConsentDetails(providerCode, consentId) {  
  const baseUrl = getBaseUrl();
  const url = `${baseUrl}/api/${encodeURIComponent(providerCode)}/open-banking/v3.1/aisp/account-access-consents/${encodeURIComponent(consentId)}`;
  
  // Get client credentials token for the request
  const defaultRedirectUri = process.env.REDIRECT_URI || 'https://backbase-dev.com/callback';
  const clientGrantToken = await getClientGrantToken(providerCode, defaultRedirectUri);
  
  try {
    const { data } = await axios.get(url, {
      headers: {
        'Authorization': clientGrantToken
      }
    });
    
    return data;
  } catch (error) {
    console.error('Failed to fetch AIS consent details:');
    console.error('Status:', error.response?.status);
    console.error('Response data:', JSON.stringify(error.response?.data, null, 2));
    
    const errorMessage = error.response?.data?.error 
      || error.response?.data?.message 
      || JSON.stringify(error.response?.data)
      || error.message;
    throw new Error(`Failed to fetch AIS consent details: ${errorMessage}`);
  }
}


