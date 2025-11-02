# Quick Start Guide

Get started with bb-tpp-api-simulator in under 5 minutes.

---

## Option 1: Copy from Existing Simulator (Fastest)

If you already have bb-tpp-simulator set up:

```bash
cd bb-tpp-api-simulator
./setup-from-existing.sh
npm start
```

✅ Done! Server running on http://localhost:3002

---

## Option 2: Manual Setup

### Step 1: Configure

```bash
cd bb-tpp-api-simulator
cp env.example .env
```

Edit `.env` and set:
```bash
OB_SOFTWARE_ID=your-software-id-here
OB_PRIVATE_KEY_PATH=./private_key.pem
```

### Step 2: Add Private Key

```bash
cp /path/to/your/key.pem ./private_key.pem
chmod 600 ./private_key.pem
```

### Step 3: Start Server

```bash
npm start
```

✅ Server running on http://localhost:3002

---

## Quick Test

### 1. Health Check
```bash
curl http://localhost:3002/api/health
```

### 2. Create Consent
```bash
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 3. Run Full Flow
```bash
./test-flow.sh
```

---

## Next Steps

📖 **Documentation:**
- `README.md` - Complete guide with detailed examples
- `CURL_EXAMPLES.md` - Quick curl command reference
- `COMPARISON.md` - Compare with UI version

🧪 **Testing:**
- `./test-flow.sh` - Interactive test script
- `curl http://localhost:3002` - API documentation

🐳 **Docker:**
```bash
docker-compose up
```

---

## Common Issues

### "Private key not configured"
Make sure `.env` has `OB_PRIVATE_KEY_PATH` set and the file exists.

### "OB_SOFTWARE_ID not configured"
Edit `.env` and add your SaltEdge software ID.

### Port already in use
Change `PORT=3002` in `.env` to another port.

---

## Example Flow

```bash
# 1. Create consent
curl -X POST http://localhost:3002/api/ais/consent -H "Content-Type: application/json" -d '{}'

# 2. Open authorizationUrl in browser (from response above)

# 3. After authorization, exchange code for token
curl -X POST http://localhost:3002/api/ais/token \
  -H "Content-Type: application/json" \
  -d '{"code":"YOUR_AUTH_CODE"}'

# 4. Get accounts
curl "http://localhost:3002/api/ais/accounts?accessToken=Bearer%20YOUR_TOKEN"
```

---

That's it! You're ready to test UK Open Banking flows with curl commands.

For detailed documentation, see `README.md`.

