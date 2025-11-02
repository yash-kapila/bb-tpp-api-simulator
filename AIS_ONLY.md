# AIS-Only Implementation Notice

⚠️ **This TPP API Simulator currently implements ONLY AIS (Account Information Services)**

PIS (Payment Initiation Services) is **NOT** implemented.

---

## What's Implemented (AIS)

### Service Functions (`server/services/saltedge.js`)

All functions are explicitly AIS-specific:

1. **`createAISConsent()`** - Creates account-access-consent
   - Endpoint: `/aisp/account-access-consents`
   - Purpose: Request permission to read account information
   - Returns: Authorization URL for user consent

2. **`exchangeCodeForToken()`** - Gets AIS access token
   - After user authorizes AIS consent
   - Returns: Bearer token for account information access

3. **`getAccounts()`** - Fetch authorized accounts
   - Uses AIS access token
   - Endpoint: `/aisp/accounts`

4. **`getAccountTransactions()`** - Fetch account transactions
   - Uses AIS access token
   - Endpoint: `/aisp/accounts/{id}/transactions`

5. **`getAccountBalances()`** - Fetch account balances
   - Uses AIS access token
   - Endpoint: `/aisp/accounts/{id}/balances`

6. **`getAccountStandingOrders()`** - Fetch standing orders
   - Uses AIS access token
   - Endpoint: `/aisp/accounts/{id}/standing-orders`

7. **`refreshAccounts()`** - Trigger account data refresh
   - Uses AIS access token
   - Endpoint: `/aisp/accounts/refresh`

8. **`getRefreshStatus()`** - Check refresh status
   - Uses AIS access token
   - Endpoint: `/aisp/accounts/refresh/status`

9. **`getConsentDetails()`** - Get AIS consent details
   - Retrieves account-access-consent status
   - Endpoint: `/aisp/account-access-consents/{id}`

### API Routes (`server/routes/ais.js`)

All routes under `/api/ais/*` are AIS-specific:

- `POST /api/ais/consent` - Create AIS consent
- `POST /api/ais/token` - Exchange code for AIS token
- `GET /api/ais/accounts` - Get accounts
- `GET /api/ais/accounts/:id/transactions` - Get transactions
- `GET /api/ais/accounts/:id/balances` - Get balances
- `GET /api/ais/accounts/:id/standing-orders` - Get standing orders
- `POST /api/ais/accounts/refresh` - Refresh accounts
- `GET /api/ais/accounts/refresh/status` - Check refresh status
- `GET /api/ais/consent/:id` - Get consent details

---

## What's NOT Implemented (PIS)

### Payment Initiation Services (Future)

The following would be needed for PIS support:

1. **Payment Consent Creation**
   - Function: `createPISConsent()`
   - Endpoint: `/pisp/domestic-payment-consents`
   - Body includes: `Initiation` (payment details), `Risk` assessment

2. **Payment Execution**
   - Function: `submitPayment()`
   - Endpoint: `/pisp/domestic-payments`
   - Requires: Payment consent ID and authorization

3. **Payment Status**
   - Function: `getPaymentStatus()`
   - Endpoint: `/pisp/domestic-payments/{id}`

4. **Different OAuth Scope**
   - AIS uses: `openid accounts payments`
   - PIS should use: `openid payments`

### Key Differences: AIS vs PIS

| Aspect | AIS (Implemented) | PIS (Not Implemented) |
|--------|-------------------|----------------------|
| **Purpose** | Read account information | Initiate payments |
| **Endpoint Base** | `/aisp/*` | `/pisp/*` |
| **Consent Type** | `account-access-consents` | `domestic-payment-consents` |
| **OAuth Scope** | `openid accounts payments` | `openid payments` |
| **Reusable** | Yes (until expiration) | No (one-time use) |
| **Permissions** | Read* permissions | Not applicable |
| **Payment Details** | Not required | Required (Initiation, Risk) |
| **Access Token** | Can fetch multiple resources | Single payment execution |

---

## Function Naming Convention

To make it explicit that functions are AIS-specific:

- ✅ **`createAISConsent()`** - Clear it's for AIS
- ✅ All functions documented with "AIS" in comments
- ✅ All endpoints use `/aisp/` path
- ✅ Console logs mention "AIS" explicitly

When PIS is implemented, functions should follow similar pattern:
- `createPISConsent()`
- `submitPayment()`
- `getPISConsentDetails()`

---

## Adding PIS Support (Future Roadmap)

To add PIS support, you would need:

1. **New Service Functions** (`server/services/saltedge.js`)
   ```javascript
   export async function createPISConsent({ ... }) {
     // Create domestic-payment-consent
     // Use /pisp/ endpoint
   }
   
   export async function submitPayment({ ... }) {
     // Submit domestic-payment
   }
   
   export async function getPaymentStatus({ ... }) {
     // Check payment status
   }
   ```

2. **New API Routes** (`server/routes/pis.js`)
   ```javascript
   router.post('/payment-consent', ...);
   router.post('/payment', ...);
   router.get('/payment/:paymentId', ...);
   ```

3. **Register Routes** (`server/index.js`)
   ```javascript
   import pisRouter from './routes/pis.js';
   app.use('/api/pis', pisRouter);
   ```

4. **Update Documentation**
   - Add PIS examples to README
   - Add PIS curl commands
   - Update COMPARISON.md

---

## Why AIS Only?

This implementation focuses on AIS because:

1. **Most common use case** - Reading account information
2. **Simpler flow** - No payment risk assessment needed
3. **Reusable tokens** - One consent for multiple API calls
4. **Testing focus** - Most integration testing is for AIS

PIS can be added later if payment testing is needed.

---

## Verification

To verify this is AIS-only:

1. **Check endpoints**: All use `/aisp/` (not `/pisp/`)
2. **Check function names**: All mention AIS or account operations
3. **Check consent type**: Creates `account-access-consents`
4. **Check permissions**: Uses Read* permissions (not payment permissions)
5. **Check file header**: `saltedge.js` explicitly states "AIS Only"

---

## Questions?

- Why are there no payment functions? → AIS-only implementation
- How to initiate payments? → Not supported yet (PIS not implemented)
- Can I use this for payment testing? → No, only account information
- When will PIS be added? → See CHANGELOG.md roadmap

---

**Last Updated**: 2025-11-02  
**Version**: 1.0.0 (AIS Only)


