# BB TPP API Simulator

curl-friendly API simulator for UK Open Banking AIS consent flow with SaltEdge.

## Setup

```bash
# 1. Install dependencies
npm install

# 2. Configure
cp env.example .env
# Edit .env: set OB_SOFTWARE_ID and OB_PRIVATE_KEY_PATH

# 3. Add private key
cp /path/to/your/key.pem ./private_key.pem

# 4. Start
npm start
```

Server runs on **http://localhost:3002**

## API Endpoints

### 1. Create Consent
```bash
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'
```

Returns `authorizationUrl` - open in browser to authorize.

**Optional parameters:**
```json
{
  "providerCode": "backbase_dev_uk",
  "redirectUri": "https://your-app.com/callback",
  "permissions": ["ReadAccountsBasic", "ReadBalances"]
}
```

### 2. Get Consent Details
```bash
curl "http://localhost:3002/api/ais/consent/CONSENT_ID?providerCode=backbase_dev_uk"
```

## Configuration (.env)

```bash
# Required
OB_SOFTWARE_ID=your-software-id
OB_PRIVATE_KEY_PATH=./private_key.pem

# Optional
OB_PROVIDER_CODE=backbase_dev_uk
REDIRECT_URI=https://backbase-dev.com/callback
PRIORA_URL=priora.saltedge.com
PORT=3002
```

## Service Architecture

- **`server/services/ais-service.js`** - Core AIS consent operations (create, retrieve)
- **`server/services/saltedge-extended.js`** - Archived post-authorization functions (token exchange, accounts, transactions, balances, etc.) - not exposed via API

