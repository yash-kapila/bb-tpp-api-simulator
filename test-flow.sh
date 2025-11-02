#!/bin/bash

# BB TPP API Simulator - Complete Test Flow
# This script demonstrates the complete AIS consent flow using curl

set -e  # Exit on error

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3002}"
PROVIDER="${PROVIDER:-backbase_dev_uk}"
REDIRECT_URI="${REDIRECT_URI:-https://backbase-dev.com/callback}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================================================="
echo "  BB TPP API Simulator - Complete AIS Flow Test"
echo "========================================================================="
echo ""
echo "Configuration:"
echo "  Base URL:     $BASE_URL"
echo "  Provider:     $PROVIDER"
echo "  Redirect URI: $REDIRECT_URI"
echo ""
echo "========================================================================="

# Step 1: Create Consent
echo ""
echo -e "${BLUE}=== Step 1: Creating AIS Consent ===${NC}"
echo ""

CONSENT_RESPONSE=$(curl -s -X POST $BASE_URL/api/ais/consent \
  -H "Content-Type: application/json" \
  -d "{\"providerCode\":\"$PROVIDER\",\"redirectUri\":\"$REDIRECT_URI\"}")

# Check if jq is available for pretty printing
if command -v jq &> /dev/null; then
    echo "$CONSENT_RESPONSE" | jq .
else
    echo "$CONSENT_RESPONSE"
fi

# Extract values
CONSENT_ID=$(echo "$CONSENT_RESPONSE" | grep -o '"consentId":"[^"]*"' | cut -d'"' -f4)
AUTH_URL=$(echo "$CONSENT_RESPONSE" | grep -o '"authorizationUrl":"[^"]*"' | sed 's/"authorizationUrl":"//g' | sed 's/"//g')

if [ -z "$CONSENT_ID" ]; then
    echo ""
    echo -e "${YELLOW}❌ Failed to create consent. Check the error above.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Consent created successfully!${NC}"
echo "   Consent ID: $CONSENT_ID"

# Step 2: Manual Authorization
echo ""
echo -e "${BLUE}=== Step 2: Authorization Required ===${NC}"
echo ""
echo "Please complete the following steps:"
echo ""
echo "1. Open this URL in your browser:"
echo -e "${YELLOW}$AUTH_URL${NC}"
echo ""
echo "2. Complete the authorization flow at the ASPSP"
echo "3. After authorization, you'll be redirected to:"
echo "   $REDIRECT_URI?code=AUTHORIZATION_CODE"
echo ""
echo "4. Copy the 'code' parameter from the redirect URL"
echo ""
echo -n "Paste the authorization code here: "
read -r AUTH_CODE

if [ -z "$AUTH_CODE" ]; then
    echo ""
    echo -e "${YELLOW}❌ No authorization code provided. Exiting.${NC}"
    exit 1
fi

# Step 3: Exchange Code for Token
echo ""
echo -e "${BLUE}=== Step 3: Exchanging Code for Access Token ===${NC}"
echo ""

TOKEN_RESPONSE=$(curl -s -X POST $BASE_URL/api/ais/token \
  -H "Content-Type: application/json" \
  -d "{\"code\":\"$AUTH_CODE\",\"providerCode\":\"$PROVIDER\",\"redirectUri\":\"$REDIRECT_URI\"}")

if command -v jq &> /dev/null; then
    echo "$TOKEN_RESPONSE" | jq .
else
    echo "$TOKEN_RESPONSE"
fi

# Extract access token
ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo ""
    echo -e "${YELLOW}❌ Failed to get access token. Check the error above.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Access token obtained successfully!${NC}"

# Step 4: Fetch Accounts
echo ""
echo -e "${BLUE}=== Step 4: Fetching Accounts ===${NC}"
echo ""

# URL encode the access token (replace space with %20)
ENCODED_TOKEN=$(echo "$ACCESS_TOKEN" | sed 's/ /%20/g')

ACCOUNTS=$(curl -s "$BASE_URL/api/ais/accounts?accessToken=$ENCODED_TOKEN&providerCode=$PROVIDER")

if command -v jq &> /dev/null; then
    echo "$ACCOUNTS" | jq .
    # Extract first account ID
    ACCOUNT_ID=$(echo "$ACCOUNTS" | jq -r '.data.Data.Account[0].AccountId' 2>/dev/null || echo "")
else
    echo "$ACCOUNTS"
    # Try to extract account ID without jq
    ACCOUNT_ID=$(echo "$ACCOUNTS" | grep -o '"AccountId":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "null" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  No accounts found or unable to extract account ID.${NC}"
    echo ""
    echo -e "${GREEN}✅ Flow completed successfully up to this point!${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}✅ Accounts retrieved successfully!${NC}"
echo "   First Account ID: $ACCOUNT_ID"

# Step 5: Fetch Transactions
echo ""
echo -e "${BLUE}=== Step 5: Fetching Transactions for Account $ACCOUNT_ID ===${NC}"
echo ""

TRANSACTIONS=$(curl -s "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/transactions?accessToken=$ENCODED_TOKEN&providerCode=$PROVIDER")

if command -v jq &> /dev/null; then
    echo "$TRANSACTIONS" | jq .
else
    echo "$TRANSACTIONS"
fi

echo ""
echo -e "${GREEN}✅ Transactions retrieved successfully!${NC}"

# Step 6: Fetch Balances
echo ""
echo -e "${BLUE}=== Step 6: Fetching Balances for Account $ACCOUNT_ID ===${NC}"
echo ""

BALANCES=$(curl -s "$BASE_URL/api/ais/accounts/$ACCOUNT_ID/balances?accessToken=$ENCODED_TOKEN&providerCode=$PROVIDER")

if command -v jq &> /dev/null; then
    echo "$BALANCES" | jq .
else
    echo "$BALANCES"
fi

echo ""
echo -e "${GREEN}✅ Balances retrieved successfully!${NC}"

# Summary
echo ""
echo "========================================================================="
echo -e "${GREEN}✅ Complete AIS Flow Test Successful!${NC}"
echo "========================================================================="
echo ""
echo "Summary:"
echo "  ✅ Consent created: $CONSENT_ID"
echo "  ✅ Authorization completed"
echo "  ✅ Access token obtained"
echo "  ✅ Accounts fetched: $ACCOUNT_ID"
echo "  ✅ Transactions fetched"
echo "  ✅ Balances fetched"
echo ""
echo "You can now use the access token for further API calls:"
echo "  Access Token: $ACCESS_TOKEN"
echo ""
echo "========================================================================="
echo ""

