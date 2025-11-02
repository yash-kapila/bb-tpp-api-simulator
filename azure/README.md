# Azure Deployment

Infrastructure as Code for deploying BB TPP API Simulator to Azure App Service with Key Vault.

## Files

- **main.bicep** - Azure Bicep template for infrastructure
- **parameters.example.json** - Example parameters file
- **../deploy-azure.sh** - One-command deployment script

## Resources Created

1. **App Service Plan** - Linux-based hosting plan
2. **App Service** - Node.js 18 web app with managed identity
3. **Key Vault** - Secure storage for private key and secrets

## Architecture

```
┌─────────────────────────────────────────┐
│   Azure App Service                      │
│   (bb-tpp-api-sim-dev-xxxxx)            │
│                                          │
│   - Node.js 18 runtime                  │
│   - Managed Identity enabled            │
│   - HTTPS only                          │
│   - Auto-deploy from ZIP                │
└────────────┬────────────────────────────┘
             │
             │ Reads secrets via
             │ System Managed Identity
             ↓
┌─────────────────────────────────────────┐
│   Azure Key Vault                        │
│   (bb-tpp-api-sim-kv-xxxxx)             │
│                                          │
│   Secrets:                               │
│   - tpp-private-key (RSA key)           │
│   - ob-software-id (SaltEdge ID)        │
└─────────────────────────────────────────┘
```

## Prerequisites

- Azure CLI installed and logged in
- Node.js 18+
- Private key file at `./docs/client_private.key`
- `.env` file with `OB_SOFTWARE_ID`

## Quick Deploy

```bash
./deploy-azure.sh
```

That's it! Everything else is automatic.

## Custom Deployment

```bash
# Development environment
./deploy-azure.sh --env dev --sku F1

# Production environment with more resources
./deploy-azure.sh --env prod --sku P1v2 --location westeurope

# Specific resource group
./deploy-azure.sh --rg my-custom-rg --name my-tpp-app
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--name` | Application name prefix | `bb-tpp-api-sim` |
| `--env` | Environment (dev/test/prod) | `dev` |
| `--location` | Azure region | `eastus` |
| `--sku` | App Service SKU (F1/B1/S1/P1v2) | `B1` |
| `--rg` | Resource group name | `{name}-rg-{env}` |
| `--skip-build` | Skip npm install | `false` |

## Cost Estimates

| SKU | Monthly Cost | Use Case |
|-----|--------------|----------|
| F1 | Free | Testing only |
| B1 | ~$13 | Development |
| S1 | ~$70 | Staging/UAT |
| P1v2 | ~$140 | Production |

## Post-Deployment

### View Logs
```bash
az webapp log tail --name {app-name} --resource-group {rg}
```

### Update Configuration
```bash
az webapp config appsettings set \
  --name {app-name} \
  --resource-group {rg} \
  --settings KEY=VALUE
```

### Redeploy Code
```bash
./deploy-azure.sh --skip-build
```

### Delete Everything
```bash
az group delete --name {rg} --yes
```

## Key Vault Integration

The deployment automatically:
1. Creates Key Vault with restricted access
2. Enables managed identity on App Service
3. Grants App Service access to Key Vault secrets
4. Uploads private key and software ID
5. Configures App Service to reference Key Vault secrets

Secrets are accessed as environment variables:
```javascript
// In your code
const privateKey = process.env.OB_PRIVATE_KEY; // ← Injected from Key Vault
const softwareId = process.env.OB_SOFTWARE_ID; // ← Injected from Key Vault
```

## Troubleshooting

### Deployment fails
```bash
# Check deployment logs
az deployment group list --resource-group {rg}
az deployment group show --resource-group {rg} --name {deployment-name}
```

### App not starting
```bash
# View live logs
az webapp log tail --name {app-name} --resource-group {rg}

# Restart app
az webapp restart --name {app-name} --resource-group {rg}
```

### Key Vault access denied
```bash
# Verify managed identity has access
az keyvault show --name {kv-name} --query properties.accessPolicies

# Verify Key Vault reference in app settings
az webapp config appsettings list --name {app-name} --resource-group {rg}
```

## Security Notes

- All traffic is HTTPS only
- Private key stored in Key Vault (encrypted at rest)
- Managed identity (no passwords/keys to manage)
- Soft delete enabled on Key Vault (7-day recovery)
- FTP disabled
- TLS 1.2 minimum

## Advanced: Manual Bicep Deployment

If you prefer manual control:

```bash
# Create resource group
az group create --name my-rg --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group my-rg \
  --template-file azure/main.bicep \
  --parameters azure/parameters.example.json

# Get outputs
az deployment group show \
  --resource-group my-rg \
  --name main \
  --query properties.outputs
```

