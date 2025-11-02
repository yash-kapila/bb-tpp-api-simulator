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

## Complete Flow

```bash
# 1. Create consent
RESPONSE=$(curl -s -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" -d '{}')

# 2. Extract and open authorization URL (from response)
# Complete authorization in browser

# 3. Use authorization code (see saltedge-extended.js for token exchange)
```

Use `./test-flow.sh` for interactive testing.

## Azure Deployment

Deploy to Azure App Service with Key Vault integration:

```bash
./deploy-azure.sh
```

This provisions:
- Azure App Service (Node.js 18)
- Azure Key Vault (for private key storage)
- Managed Identity (secure access)
- HTTPS endpoint

See `azure/README.md` for detailed deployment options.

## Archived Functions

Post-authorization functions (token exchange, accounts, transactions, balances, etc.) are preserved in `server/services/saltedge-extended.js` but not exposed via API. Import from that file if needed.

