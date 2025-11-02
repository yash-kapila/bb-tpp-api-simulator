# BB TPP API Simulator

A curl-friendly API simulator for UK Open Banking testing with SaltEdge. **No UI** - pure REST API interface designed for automation, testing, and command-line workflows.

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- SaltEdge account with TPP registered
- Private key file (`.pem`)
- Client ID (Software ID) from SaltEdge

### Setup (3 minutes)

```bash
# 1. Install dependencies
cd bb-tpp-api-simulator
npm install

# 2. Configure environment
cp env.example .env
nano .env  # Add your OB_SOFTWARE_ID and configure settings

# 3. Add your private key
cp /path/to/your/key.pem ./private_key.pem

# 4. Start the server
npm start
```

Server will start on **http://localhost:3002**

---

## 📋 Complete AIS Flow with curl

### Step 1: Create Consent & Get Authorization URL

```bash
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Response:**
```json
{
  "success": true,
  "message": "Consent created successfully. Open the authorizationUrl in your browser to authorize.",
  "data": {
    "consentId": "aaaj-...",
    "authorizationUrl": "https://priora.saltedge.com/auth/...",
    "status": "AwaitingAuthorisation",
    "permissions": [...],
    "expirationDateTime": "2025-12-02T10:30:00.000Z"
  }
}
```

**Optional parameters:**
```bash
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://your-app.com/callback",
    "permissions": ["ReadAccountsBasic", "ReadBalances", "ReadTransactionsDetail"]
  }'
```

### Step 2: Authorize in Browser

1. Copy the `authorizationUrl` from the response
2. Open it in your browser
3. Complete the authorization flow at the ASPSP
4. You'll be redirected to your `redirectUri` with a `code` parameter
5. Extract the `code` from the URL: `https://your-redirect-uri?code=AUTHORIZATION_CODE`

### Step 3: Exchange Code for Access Token

```bash
curl -X POST http://localhost:3002/api/ais/token \
  -H "Content-Type: application/json" \
  -d '{
    "code": "AUTHORIZATION_CODE_FROM_STEP_2"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Access token obtained. Use it to access account data.",
  "data": {
    "accessToken": "Bearer eyJhbGc...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "scope": "openid accounts payments"
  }
}
```

### Step 4: Fetch Accounts

```bash
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_ACCESS_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "Data": {
      "Account": [
        {
          "AccountId": "account-123",
          "Currency": "GBP",
          "AccountType": "Personal",
          "AccountSubType": "CurrentAccount",
          "Nickname": "My Current Account"
        }
      ]
    }
  }
}
```

### Step 5: Get Transactions

```bash
curl "http://localhost:3002/api/ais/accounts/account-123/transactions?accessToken=Bearer%20YOUR_ACCESS_TOKEN"
```

### Step 6: Get Balances

```bash
curl "http://localhost:3002/api/ais/accounts/account-123/balances?accessToken=Bearer%20YOUR_ACCESS_TOKEN"
```

---

## 🔧 All Available Endpoints

### Health Check
```bash
curl http://localhost:3002/api/health
```

### Create AIS Consent
```bash
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://backbase-dev.com/callback"
  }'
```

### Exchange Authorization Code for Token
```bash
curl -X POST http://localhost:3002/api/ais/token \
  -H "Content-Type: application/json" \
  -d '{
    "code": "YOUR_AUTH_CODE",
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://backbase-dev.com/callback"
  }'
```

### Get Accounts
```bash
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN&providerCode=backbase_dev_uk"
```

### Get Account Transactions
```bash
curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/transactions?accessToken=Bearer%20YOUR_TOKEN"
```

### Get Account Balances
```bash
curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/balances?accessToken=Bearer%20YOUR_TOKEN"
```

### Get Account Standing Orders
```bash
curl "http://localhost:3002/api/ais/accounts/ACCOUNT_ID/standing-orders?accessToken=Bearer%20YOUR_TOKEN"
```

### Refresh Accounts
```bash
curl -X POST http://localhost:3002/api/ais/accounts/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "accessToken": "Bearer YOUR_TOKEN"
  }'
```

### Get Refresh Status
```bash
curl "http://localhost:3002/api/ais/accounts/refresh/status?accessToken=Bearer%20YOUR_TOKEN"
```

### Get Consent Details
```bash
curl "http://localhost:3002/api/ais/consent/CONSENT_ID?providerCode=backbase_dev_uk"
```

---

## ⚙️ Configuration

### Environment Variables (.env)

```bash
# SaltEdge Priora Configuration
PRIORA_URL=priora.saltedge.com
PROTOCOL=https

# Open Banking Provider Code
OB_PROVIDER_CODE=backbase_dev_uk

# TPP Credentials (from SaltEdge)
OB_SOFTWARE_ID=your-software-id-here
OB_PRIVATE_KEY_PATH=./private_key.pem

# Default Redirect URI
REDIRECT_URI=https://backbase-dev.com/callback

# Server Port
PORT=3002
```

### Available Providers

| Code | Description |
|------|-------------|
| `backbase_dev_uk` | Backbase DEV UK |
| `backbase_uat_uk` | Backbase UAT UK |
| `backbase_dev_eu` | Backbase DEV EU |
| `backbase_uat_eu` | Backbase UAT EU |

### Default Permissions

If you don't specify permissions, the following are used:
- `ReadAccountsBasic`, `ReadAccountsDetail`
- `ReadBalances`
- `ReadBeneficiariesDetail`
- `ReadTransactionsBasic`, `ReadTransactionsCredits`, `ReadTransactionsDebits`, `ReadTransactionsDetail`
- `ReadOffers`, `ReadPAN`
- `ReadParty`, `ReadPartyPSU`
- `ReadProducts`
- `ReadStandingOrdersDetail`
- `ReadScheduledPaymentsDetail`
- `ReadStatementsDetail`
- `ReadDirectDebits`

---

## 🎯 Example Workflow Script

Here's a complete bash script example:

```bash
#!/bin/bash

# Configuration
BASE_URL="http://localhost:3002"
PROVIDER="backbase_dev_uk"
REDIRECT_URI="https://backbase-dev.com/callback"

echo "=== Step 1: Create Consent ==="
CONSENT_RESPONSE=$(curl -s -X POST $BASE_URL/api/ais/consent \
  -H "Content-Type: application/json" \
  -d "{\"providerCode\":\"$PROVIDER\",\"redirectUri\":\"$REDIRECT_URI\"}")

echo "$CONSENT_RESPONSE" | jq .

CONSENT_ID=$(echo "$CONSENT_RESPONSE" | jq -r '.data.consentId')
AUTH_URL=$(echo "$CONSENT_RESPONSE" | jq -r '.data.authorizationUrl')

echo ""
echo "=== Step 2: Authorize ==="
echo "Open this URL in your browser:"
echo "$AUTH_URL"
echo ""
echo "After authorization, paste the 'code' parameter from the redirect URL:"
read -r AUTH_CODE

echo ""
echo "=== Step 3: Exchange Code for Token ==="
TOKEN_RESPONSE=$(curl -s -X POST $BASE_URL/api/ais/token \
  -H "Content-Type: application/json" \
  -d "{\"code\":\"$AUTH_CODE\",\"providerCode\":\"$PROVIDER\",\"redirectUri\":\"$REDIRECT_URI\"}")

echo "$TOKEN_RESPONSE" | jq .

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.data.accessToken')

echo ""
echo "=== Step 4: Fetch Accounts ==="
ACCOUNTS=$(curl -s "$BASE_URL/api/ais/accounts?accessToken=$(echo $ACCESS_TOKEN | sed 's/ /%20/g')&providerCode=$PROVIDER")

echo "$ACCOUNTS" | jq .

# Extract first account ID
ACCOUNT_ID=$(echo "$ACCOUNTS" | jq -r '.data.Data.Account[0].AccountId')

echo ""
echo "=== Step 5: Fetch Transactions ==="
curl -s "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/transactions?accessToken=$(echo $ACCESS_TOKEN | sed 's/ /%20/g')" | jq .

echo ""
echo "=== Step 6: Fetch Balances ==="
curl -s "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/balances?accessToken=$(echo $ACCESS_TOKEN | sed 's/ /%20/g')" | jq .

echo ""
echo "✅ Complete!"
```

Save this as `test-flow.sh`, make it executable (`chmod +x test-flow.sh`), and run it (`./test-flow.sh`).

---

## 🐛 Troubleshooting

### "Private key not configured"
```bash
# Check .env file
cat .env | grep PRIVATE_KEY

# Verify key exists
ls -la private_key.pem

# Check permissions
chmod 600 private_key.pem
```

### "Failed to create consent"
- Verify `OB_SOFTWARE_ID` is correct
- Ensure private key matches what's registered with SaltEdge
- Check SaltEdge Priora is accessible:
  ```bash
  curl https://priora.saltedge.com/.well-known/openid-configuration/backbase_dev_uk
  ```

### "No access_token in response"
- Make sure the authorization code is fresh (they expire quickly)
- Verify the `redirectUri` matches exactly what was used during consent creation
- Check that you completed the authorization flow successfully

### URL Encoding Issues
When passing Bearer tokens in URLs, remember to encode spaces:
```bash
# Good
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN"

# Or use quotes and let curl handle it
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer YOUR_TOKEN"
```

---

## 📁 Project Structure

```
bb-tpp-api-simulator/
├── server/
│   ├── index.js              # Main server file
│   ├── routes/
│   │   └── ais.js            # AIS API routes
│   └── services/
│       └── saltedge.js       # SaltEdge integration
├── .env                      # Configuration (create from env.example)
├── env.example               # Example configuration
├── package.json              # Dependencies
├── .gitignore               # Git ignore rules
├── private_key.pem          # Your TPP private key (not in git)
└── README.md                # This file
```

---

## 🔄 Development Mode

Run with auto-reload on file changes:

```bash
npm run dev
```

---

## 🚦 Testing

### Basic Health Check
```bash
curl http://localhost:3002/api/health
```

### API Documentation
```bash
curl http://localhost:3002
```

### Full Flow Test
Use the example workflow script above, or integrate into your CI/CD pipeline.

---

## 📊 Comparison with Original bb-tpp-simulator

| Feature | bb-tpp-simulator | bb-tpp-api-simulator |
|---------|------------------|----------------------|
| **UI** | ✅ React frontend | ❌ No UI |
| **API** | ✅ Backend APIs | ✅ curl-friendly APIs |
| **Use Case** | Manual testing | Automation & scripting |
| **Setup** | Build frontend | Just npm install |
| **Port** | 3001 | 3002 |
| **Best For** | Visual testing | CI/CD, scripts, automation |

---

## 🤝 Integration Examples

### Shell Script
See "Example Workflow Script" above.

### Python
```python
import requests

# Create consent
response = requests.post('http://localhost:3002/api/ais/consent', json={
    'providerCode': 'backbase_dev_uk'
})
data = response.json()
auth_url = data['data']['authorizationUrl']

print(f"Authorize here: {auth_url}")

# After manual authorization...
auth_code = input("Enter authorization code: ")

# Exchange for token
token_response = requests.post('http://localhost:3002/api/ais/token', json={
    'code': auth_code,
    'providerCode': 'backbase_dev_uk'
})
access_token = token_response.json()['data']['accessToken']

# Fetch accounts
accounts = requests.get(
    'http://localhost:3002/api/ais/accounts',
    params={'accessToken': access_token}
).json()

print(accounts)
```

### Node.js
```javascript
import axios from 'axios';

const baseUrl = 'http://localhost:3002';

// Create consent
const { data } = await axios.post(`${baseUrl}/api/ais/consent`, {
  providerCode: 'backbase_dev_uk'
});

console.log('Authorize here:', data.data.authorizationUrl);

// After authorization, exchange code
const authCode = 'YOUR_CODE_FROM_REDIRECT';
const tokenResponse = await axios.post(`${baseUrl}/api/ais/token`, {
  code: authCode,
  providerCode: 'backbase_dev_uk'
});

const accessToken = tokenResponse.data.data.accessToken;

// Fetch accounts
const accounts = await axios.get(`${baseUrl}/api/ais/accounts`, {
  params: { accessToken }
});

console.log(accounts.data);
```

---

## 🆘 Support

Contact the Backbase Open Banking team.

---

## 📝 License

Internal use only - Backbase

