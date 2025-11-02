#!/bin/bash

##############################################################################
# BB TPP API Simulator - Azure Deployment Script
# 
# One-command deployment to Azure App Service with Key Vault integration
#
# Usage: ./deploy-azure.sh [options]
#
# Options:
#   --name         Application name (default: bb-tpp-api-sim)
#   --env          Environment: dev|test|prod (default: dev)
#   --location     Azure region (default: eastus)
#   --sku          App Service SKU: F1|B1|S1|P1v2 (default: B1)
#   --rg           Resource group name (default: bb-tpp-api-simulator-rg)
#   --skip-build   Skip npm install (use if already done)
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
APP_NAME="bb-tpp-api-sim"
ENVIRONMENT="dev"
LOCATION="eastus"
SKU="B1"
RESOURCE_GROUP=""
SKIP_BUILD=false
PRIVATE_KEY_PATH="./docs/client_private.key"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      APP_NAME="$2"
      shift 2
      ;;
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --sku)
      SKU="$2"
      shift 2
      ;;
    --rg)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --help)
      grep "^#" "$0" | grep -v "#!/bin/bash" | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Set resource group name if not provided
if [ -z "$RESOURCE_GROUP" ]; then
  RESOURCE_GROUP="${APP_NAME}-rg-${ENVIRONMENT}"
fi

echo ""
echo "=========================================================================="
echo -e "${BLUE}BB TPP API Simulator - Azure Deployment${NC}"
echo "=========================================================================="
echo ""
echo "Configuration:"
echo "  App Name:        $APP_NAME"
echo "  Environment:     $ENVIRONMENT"
echo "  Location:        $LOCATION"
echo "  Resource Group:  $RESOURCE_GROUP"
echo "  App Service SKU: $SKU"
echo ""
echo "=========================================================================="
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI not found${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI installed${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠ jq not found (optional but recommended)${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
fi

# Check Azure login
if ! az account show &> /dev/null; then
    echo -e "${RED}✗ Not logged in to Azure${NC}"
    echo "Run: az login"
    exit 1
fi
echo -e "${GREEN}✓ Logged in to Azure${NC}"

SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Using subscription: $SUBSCRIPTION${NC}"

# Check for private key
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}✗ Private key not found at: $PRIVATE_KEY_PATH${NC}"
    echo "Please ensure your private key exists before deploying"
    exit 1
fi
echo -e "${GREEN}✓ Private key found${NC}"

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ No .env file found. Using defaults.${NC}"
fi

echo ""

# Build application
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${BLUE}Installing dependencies...${NC}"
    npm install --production
    echo -e "${GREEN}✓ Dependencies installed${NC}"
    echo ""
fi

# Step 1: Create Resource Group
echo -e "${BLUE}Step 1: Creating resource group...${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

echo -e "${GREEN}✓ Resource group created: $RESOURCE_GROUP${NC}"
echo ""

# Step 2: Deploy infrastructure
echo -e "${BLUE}Step 2: Deploying infrastructure (App Service + Key Vault)...${NC}"
echo "This may take 2-3 minutes..."
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file azure/main.bicep \
  --parameters \
    appName="$APP_NAME" \
    environment="$ENVIRONMENT" \
    location="$LOCATION" \
    appServicePlanSku="$SKU" \
  --query 'properties.outputs' \
  --output json)

# Extract outputs
APP_SERVICE_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.appServiceName.value')
APP_SERVICE_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.appServiceUrl.value')
KEY_VAULT_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.keyVaultName.value')
KEY_VAULT_URI=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.keyVaultUri.value')

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
echo "  App Service: $APP_SERVICE_NAME"
echo "  Key Vault:   $KEY_VAULT_NAME"
echo ""

# Step 3: Upload secrets to Key Vault
echo -e "${BLUE}Step 3: Uploading secrets to Key Vault...${NC}"

# Upload private key
az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "tpp-private-key" \
  --file "$PRIVATE_KEY_PATH" \
  --output none

echo -e "${GREEN}✓ Private key uploaded to Key Vault${NC}"

# Upload software ID from .env if exists
if [ -f ".env" ]; then
  SOFTWARE_ID=$(grep "^OB_SOFTWARE_ID=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
  if [ -n "$SOFTWARE_ID" ]; then
    az keyvault secret set \
      --vault-name "$KEY_VAULT_NAME" \
      --name "ob-software-id" \
      --value "$SOFTWARE_ID" \
      --output none
    echo -e "${GREEN}✓ Software ID uploaded to Key Vault${NC}"
  fi
fi

echo ""

# Step 4: Configure App Service settings with Key Vault references
echo -e "${BLUE}Step 4: Configuring App Service with Key Vault references...${NC}"

az webapp config appsettings set \
  --name "$APP_SERVICE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    "OB_PRIVATE_KEY=@Microsoft.KeyVault(SecretUri=${KEY_VAULT_URI}secrets/tpp-private-key/)" \
    "OB_SOFTWARE_ID=@Microsoft.KeyVault(SecretUri=${KEY_VAULT_URI}secrets/ob-software-id/)" \
  --output none

echo -e "${GREEN}✓ Key Vault references configured${NC}"
echo ""

# Step 5: Deploy application code
echo -e "${BLUE}Step 5: Deploying application code...${NC}"
echo "Creating deployment package..."

# Create deployment package (excluding node_modules, .env, etc.)
zip -r deploy.zip . \
  -x "*.git*" \
  -x "node_modules/*" \
  -x ".env" \
  -x "*.log" \
  -x "docs/*" \
  -x "azure/*" \
  -x "*.sh" \
  -x "deploy.zip" \
  > /dev/null 2>&1

echo "Uploading to Azure..."

az webapp deploy \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_SERVICE_NAME" \
  --src-path deploy.zip \
  --type zip \
  --async false \
  --output none

# Cleanup
rm deploy.zip

echo -e "${GREEN}✓ Application deployed${NC}"
echo ""

# Step 6: Wait for app to start
echo -e "${BLUE}Step 6: Waiting for application to start...${NC}"
sleep 10

# Test health endpoint
HEALTH_URL="${APP_SERVICE_URL}/api/health"
echo "Testing: $HEALTH_URL"

if curl -s -f "$HEALTH_URL" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Application is running!${NC}"
else
  echo -e "${YELLOW}⚠ Application may still be starting...${NC}"
  echo "Check logs with: az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
fi

echo ""
echo "=========================================================================="
echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL!${NC}"
echo "=========================================================================="
echo ""
echo "Application URL:"
echo -e "${BLUE}$APP_SERVICE_URL${NC}"
echo ""
echo "Endpoints:"
echo "  Health:        $APP_SERVICE_URL/api/health"
echo "  Create Consent: $APP_SERVICE_URL/api/ais/consent"
echo "  Get Consent:    $APP_SERVICE_URL/api/ais/consent/:id"
echo ""
echo "Useful commands:"
echo "  View logs:     az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "  Stop app:      az webapp stop --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "  Start app:     az webapp start --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "  Delete all:    az group delete --name $RESOURCE_GROUP --yes"
echo ""
echo "=========================================================================="
echo ""

