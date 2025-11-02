#!/bin/bash

# Setup Script - Copy configuration from existing bb-tpp-simulator
# This script helps migrate configuration from the UI-based simulator

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "========================================================================="
echo "  BB TPP API Simulator - Setup from Existing Configuration"
echo "========================================================================="
echo ""

# Check if bb-tpp-simulator exists
EXISTING_SIMULATOR="../bb-tpp-simulator"

if [ ! -d "$EXISTING_SIMULATOR" ]; then
    echo -e "${RED}❌ Could not find existing bb-tpp-simulator at: $EXISTING_SIMULATOR${NC}"
    echo ""
    echo "Please set up manually:"
    echo "  1. cp env.example .env"
    echo "  2. Edit .env with your configuration"
    echo "  3. Copy your private key file"
    echo ""
    exit 1
fi

echo -e "${BLUE}Found existing bb-tpp-simulator${NC}"
echo ""

# Copy .env file if it exists
if [ -f "$EXISTING_SIMULATOR/.env" ]; then
    echo -e "${YELLOW}Copying .env file...${NC}"
    cp "$EXISTING_SIMULATOR/.env" ./.env
    
    # Update PORT to 3002 (to avoid conflict with existing simulator on 3001)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's/PORT=3001/PORT=3002/' ./.env 2>/dev/null || true
    else
        # Linux
        sed -i 's/PORT=3001/PORT=3002/' ./.env 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ .env file copied and PORT updated to 3002${NC}"
else
    echo -e "${YELLOW}⚠️  No .env file found in existing simulator${NC}"
    echo "Creating from env.example..."
    cp env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env and add your configuration${NC}"
fi

# Copy private key if it exists
PRIVATE_KEY_PATH=$(grep "OB_PRIVATE_KEY_PATH" ./.env 2>/dev/null | cut -d'=' -f2 || echo "")

if [ -n "$PRIVATE_KEY_PATH" ]; then
    # Remove any quotes
    PRIVATE_KEY_PATH=$(echo "$PRIVATE_KEY_PATH" | tr -d '"' | tr -d "'")
    
    # If it's a relative path, look in the existing simulator directory
    if [[ ! "$PRIVATE_KEY_PATH" = /* ]]; then
        SOURCE_KEY="$EXISTING_SIMULATOR/$PRIVATE_KEY_PATH"
    else
        SOURCE_KEY="$PRIVATE_KEY_PATH"
    fi
    
    if [ -f "$SOURCE_KEY" ]; then
        echo -e "${YELLOW}Copying private key...${NC}"
        
        # Get just the filename
        KEY_FILENAME=$(basename "$PRIVATE_KEY_PATH")
        
        cp "$SOURCE_KEY" "./$KEY_FILENAME"
        chmod 600 "./$KEY_FILENAME"
        
        # Update .env to point to the copied key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|OB_PRIVATE_KEY_PATH=.*|OB_PRIVATE_KEY_PATH=./$KEY_FILENAME|" ./.env
        else
            sed -i "s|OB_PRIVATE_KEY_PATH=.*|OB_PRIVATE_KEY_PATH=./$KEY_FILENAME|" ./.env
        fi
        
        echo -e "${GREEN}✅ Private key copied: $KEY_FILENAME${NC}"
    else
        echo -e "${YELLOW}⚠️  Private key not found at: $SOURCE_KEY${NC}"
        echo "   Please copy your private key manually"
    fi
else
    echo -e "${YELLOW}⚠️  No OB_PRIVATE_KEY_PATH found in .env${NC}"
    echo "   Please add your private key and update .env"
fi

echo ""
echo "========================================================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "========================================================================="
echo ""

# Display configuration summary
if [ -f ./.env ]; then
    echo "Configuration Summary:"
    echo "  Software ID:  $(grep OB_SOFTWARE_ID .env | cut -d'=' -f2)"
    echo "  Provider:     $(grep OB_PROVIDER_CODE .env | cut -d'=' -f2)"
    echo "  Port:         $(grep PORT .env | cut -d'=' -f2)"
    echo "  Private Key:  $(grep OB_PRIVATE_KEY_PATH .env | cut -d'=' -f2)"
    echo ""
fi

echo "Next Steps:"
echo "  1. Review .env file and update if needed"
echo "  2. Start the server: npm start"
echo "  3. Test with: curl http://localhost:3002/api/health"
echo "  4. Try the full flow: ./test-flow.sh"
echo ""
echo "Documentation:"
echo "  - README.md         - Complete guide"
echo "  - CURL_EXAMPLES.md  - Quick curl reference"
echo "  - test-flow.sh      - Interactive test script"
echo ""
echo "========================================================================="
echo ""

