# curl Command Reference

Quick reference for all API endpoints with copy-paste ready curl commands.

## 📋 Prerequisites

Set these environment variables for easier testing:

```bash
export BASE_URL="http://localhost:3002"
export PROVIDER="backbase_dev_uk"
export REDIRECT_URI="https://backbase-dev.com/callback"
```

---

## 1️⃣ Health Check

```bash
curl $BASE_URL/api/health
```

---

## 2️⃣ Create AIS Consent

### Basic (uses defaults from .env)
```bash
curl -X POST $BASE_URL/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'
```

### With custom provider and redirect URI
```bash
curl -X POST $BASE_URL/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://your-app.com/callback"
  }'
```

### With custom permissions
```bash
curl -X POST $BASE_URL/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://your-app.com/callback",
    "permissions": [
      "ReadAccountsBasic",
      "ReadAccountsDetail",
      "ReadBalances",
      "ReadTransactionsDetail"
    ]
  }'
```

**Response includes:**
- `consentId`: The consent identifier
- `authorizationUrl`: URL to open in browser for authorization
- `status`: Current status (usually "AwaitingAuthorisation")

---

## 3️⃣ Exchange Authorization Code for Token

After authorizing in the browser, you'll get a redirect with a `code` parameter.

```bash
curl -X POST $BASE_URL/api/ais/token \
  -H "Content-Type: application/json" \
  -d '{
    "code": "YOUR_AUTHORIZATION_CODE",
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://backbase-dev.com/callback"
  }'
```

**Response includes:**
- `accessToken`: Bearer token for API calls (format: "Bearer eyJhbGc...")
- `expiresIn`: Token expiration time in seconds

---

## 4️⃣ Get Accounts

```bash
# Set the access token (from step 3)
export ACCESS_TOKEN="Bearer eyJhbGc..."

# Fetch accounts
curl "$BASE_URL/api/ais/accounts?accessToken=$ACCESS_TOKEN&providerCode=$PROVIDER"
```

**Alternative with URL-encoded token:**
```bash
curl "$BASE_URL/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN&providerCode=backbase_dev_uk"
```

---

## 5️⃣ Get Account Transactions

```bash
# Set account ID (from step 4)
export ACCOUNT_ID="account-123"

# Fetch transactions
curl "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/transactions?accessToken=$ACCESS_TOKEN&providerCode=$PROVIDER"
```

---

## 6️⃣ Get Account Balances

```bash
curl "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/balances?accessToken=$ACCESS_TOKEN&providerCode=$PROVIDER"
```

---

## 7️⃣ Get Account Standing Orders

```bash
curl "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/standing-orders?accessToken=$ACCESS_TOKEN&providerCode=$PROVIDER"
```

---

## 8️⃣ Refresh Accounts

```bash
curl -X POST $BASE_URL/api/ais/accounts/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"accessToken\": \"$ACCESS_TOKEN\",
    \"providerCode\": \"$PROVIDER\"
  }"
```

---

## 9️⃣ Get Refresh Status

```bash
curl "$BASE_URL/api/ais/accounts/refresh/status?accessToken=$ACCESS_TOKEN&providerCode=$PROVIDER"
```

---

## 🔟 Get Consent Details

```bash
# Set consent ID (from step 2)
export CONSENT_ID="aaaj-..."

# Fetch consent details
curl "$BASE_URL/api/ais/consent/$CONSENT_ID?providerCode=$PROVIDER"
```

---

## 🎯 Complete Flow (One Script)

```bash
#!/bin/bash

# 1. Create consent
RESPONSE=$(curl -s -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" -d '{}')

AUTH_URL=$(echo $RESPONSE | grep -o '"authorizationUrl":"[^"]*"' | cut -d'"' -f4)
echo "Authorize here: $AUTH_URL"

# 2. After authorization, paste code
read -p "Enter authorization code: " AUTH_CODE

# 3. Get token
TOKEN_RESPONSE=$(curl -s -X POST http://localhost:3002/api/ais/token \
  -H "Content-Type: application/json" \
  -d "{\"code\":\"$AUTH_CODE\"}")

ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

# 4. Get accounts
curl "http://localhost:3002/api/ais/accounts?accessToken=$ACCESS_TOKEN"
```

---

## 🔧 Useful Tips

### Pretty Print with jq
```bash
curl -s $BASE_URL/api/ais/consent -X POST -H "Content-Type: application/json" -d '{}' | jq .
```

### Save Response to File
```bash
curl -s $BASE_URL/api/ais/consent -X POST \
  -H "Content-Type: application/json" -d '{}' \
  -o consent-response.json
```

### Extract Specific Field
```bash
# Extract consent ID
curl -s $BASE_URL/api/ais/consent -X POST \
  -H "Content-Type: application/json" -d '{}' | \
  jq -r '.data.consentId'

# Extract authorization URL
curl -s $BASE_URL/api/ais/consent -X POST \
  -H "Content-Type: application/json" -d '{}' | \
  jq -r '.data.authorizationUrl'
```

### Verbose Output (Debug)
```bash
curl -v $BASE_URL/api/health
```

### Include Response Headers
```bash
curl -i $BASE_URL/api/health
```

---

## ⚡ Quick Test Commands

### Test server is running
```bash
curl http://localhost:3002/api/health && echo "✅ Server is running!"
```

### Test with timeout
```bash
curl --max-time 10 http://localhost:3002/api/health
```

### Test and follow redirects
```bash
curl -L http://localhost:3002/api/health
```

---

## 🐛 Troubleshooting

### URL encoding issues?
```bash
# Use quotes around the URL
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer YOUR_TOKEN"

# Or manually encode (space = %20)
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN"
```

### Connection refused?
```bash
# Check if server is running
curl http://localhost:3002/api/health

# Check what's listening on port 3002
lsof -i :3002  # macOS/Linux
netstat -an | grep 3002  # Windows
```

### Invalid JSON?
```bash
# Validate your JSON first
echo '{"code":"test"}' | jq .

# Use single quotes for outer shell, double quotes in JSON
curl -X POST http://localhost:3002/api/ais/token \
  -H "Content-Type: application/json" \
  -d '{"code":"YOUR_CODE"}'
```

---

## 📚 Additional Resources

- Full documentation: See README.md
- Interactive test: Run `./test-flow.sh`
- API documentation: `curl http://localhost:3002`


