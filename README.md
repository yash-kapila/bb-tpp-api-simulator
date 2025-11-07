# BB TPP API Simulator

curl-friendly API simulator for UK Open Banking AIS consent flow with SaltEdge.

## Table of Contents

- [Setup](#setup)
- [API Endpoints](#api-endpoints)
  - [1. Health Check](#1-health-check)
  - [2. API Documentation](#2-api-documentation)
  - [3. Create AIS Consent](#3-create-ais-consent)
  - [4. Get Consent Details](#4-get-consent-details)
  - [5. Revoke AIS Consent](#5-revoke-ais-consent)
- [Configuration (.env)](#configuration-env)

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

**Base URL Placeholder:** `{BASE_URL}`
- **Local:** `http://localhost:3002`

Replace `{BASE_URL}` with the appropriate URL in all examples below.

---

### 1. Health Check
Check if the service is running.

```bash
curl {BASE_URL}/api/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-06T08:49:11.608Z",
  "version": "1.0.0",
  "service": "bb-tpp-api-simulator"
}
```

---

### 2. API Documentation
Get list of all available endpoints.

```bash
curl {BASE_URL}/
```

---

### 3. Create AIS Consent
Create an Account Information Services consent and get the authorization URL.

```bash
curl -X POST {BASE_URL}/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Request Body (all fields optional):**
| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `providerCode` | string | Open Banking provider code | `backbase_dev_uk` (from env) |
| `redirectUri` | string | OAuth callback URL | Value from env `REDIRECT_URI` |
| `permissions` | array | List of AIS permissions | All 14 standard permissions |
| `expirationDateTime` | string | ISO 8601 date when consent expires | 30 days from now |

**Example with custom parameters:**
```bash
curl -X POST {BASE_URL}/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://your-app.com/callback",
    "permissions": ["ReadAccountsBasic", "ReadBalances", "ReadTransactionsBasic"],
    "expirationDateTime": "2025-12-31T23:59:59Z"
  }'
```

**Response:**
```json
{
  "consentId": "urn-backbase_dev_uk-intent-12345",
  "authorizationUrl": "https://business-universal.dev.oblm.azure.backbaseservices.com/...",
  "status": "Pending"
}
```

➡️ Open `authorizationUrl` in a browser to authorize the consent.

---

### 4. Get Consent Details
Retrieve details of an existing AIS consent by ID.

```bash
curl "{BASE_URL}/api/ais/consent/{CONSENT_ID}"
```

**Path Parameters:**
| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `consentId` | string | The consent ID returned from create consent | Yes |

**Query Parameters (optional):**
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `providerCode` | string | Open Banking provider code | `backbase_dev_uk` (from env) |

**Example:**
```bash
curl "{BASE_URL}/api/ais/consent/urn-backbase_dev_uk-intent-12345?providerCode=backbase_dev_uk"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "Data": {
      "ConsentId": "urn-backbase_dev_uk-intent-12345",
      "Status": "AwaitingAuthorisation",
      "Permissions": ["ReadAccountsBasic", "ReadBalances", ...],
      "ExpirationDateTime": "2025-12-06T08:49:11Z"
    }
  }
}
```

---

### 5. Revoke AIS Consent
Revoke/Delete an existing AIS consent by ID. This permanently removes the consent and prevents further use.

```bash
curl -X DELETE "{BASE_URL}/api/ais/consent/{CONSENT_ID}"
```

**Path Parameters:**
| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `consentId` | string | The consent ID to revoke | Yes |

**Query Parameters (optional):**
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `providerCode` | string | Open Banking provider code | `backbase_dev_uk` (from env) |

**Example:**
```bash
curl -X DELETE "{BASE_URL}/api/ais/consent/urn-backbase_dev_uk-intent-12345?providerCode=backbase_dev_uk"
```

**Response:**
```json
{
  "success": true,
  "message": "Consent revoked successfully",
  "consentId": "urn-backbase_dev_uk-intent-12345"
}
```

---

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
