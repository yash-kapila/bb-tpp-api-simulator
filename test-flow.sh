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
echo ""
read -p "Press Enter when authorization is complete..."

# Summary
echo ""
echo "========================================================================="
echo -e "${GREEN}✅ AIS Consent Flow Complete!${NC}"
echo "========================================================================="
echo ""
echo "Summary:"
echo "  ✅ Consent created: $CONSENT_ID"
echo "  ✅ Authorization URL provided"
echo ""
echo "Next steps (if needed):"
echo "  - Extract authorization code from redirect URL"
echo "  - Use exchangeCodeForToken() from saltedge-extended.js to get access token"
echo "  - Use access token for account operations (see saltedge-extended.js)"
echo ""
echo "========================================================================="
echo ""

