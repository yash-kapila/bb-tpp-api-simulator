# bb-tpp-api-simulator vs bb-tpp-simulator

A comparison guide to help you choose the right TPP simulator for your use case.

---

## 📊 Quick Comparison

| Feature | bb-tpp-simulator | bb-tpp-api-simulator |
|---------|------------------|----------------------|
| **User Interface** | ✅ React Web UI | ❌ No UI (API-only) |
| **Backend API** | ✅ Express REST API | ✅ Express REST API |
| **Ideal For** | Manual testing, demos | Automation, CI/CD, scripting |
| **Setup Complexity** | Medium (build client) | Low (just npm install) |
| **Port** | 3001 | 3002 |
| **Client Dependencies** | React, build tools | None |
| **Documentation** | README with UI guide | README with curl examples |
| **Test Scripts** | Manual workflow | Automated test scripts |
| **Docker Support** | ✅ Yes | ✅ Yes |
| **Azure Deployment** | ✅ Yes (with infra) | ✅ Yes (simpler) |

---

## 🎯 When to Use bb-tpp-simulator (UI Version)

### ✅ Best For:
- **Manual Testing**: Interactive UI for creating consents and viewing results
- **Demonstrations**: Showing the flow to stakeholders
- **Training**: Teaching team members about Open Banking flows
- **Development**: Visual debugging and exploration
- **Ad-hoc Testing**: Quick one-off tests without scripting

### 📋 Example Use Cases:
1. QA team doing exploratory testing
2. Product demos to clients
3. Training new developers
4. Visual verification of account data
5. Manual integration testing

---

## 🚀 When to Use bb-tpp-api-simulator (API-only Version)

### ✅ Best For:
- **Automation**: CI/CD pipelines, automated testing
- **Scripting**: Bash, Python, Node.js integration scripts
- **Load Testing**: Performance testing without UI overhead
- **Integration Testing**: Automated test suites
- **Containerized Environments**: Smaller Docker images
- **Headless Servers**: No need for build tools or frontend assets

### 📋 Example Use Cases:
1. CI/CD pipeline integration tests
2. Automated regression testing
3. Performance/load testing
4. Integration with test frameworks (Playwright, Selenium)
5. Scheduled consent renewal tests
6. Monitoring and health checks
7. Backend service integration tests

---

## 🔀 Use Both Together

You can run both simulators simultaneously for different purposes:

```bash
# Terminal 1 - UI version for manual testing
cd bb-tpp-simulator
npm start  # Runs on port 3001

# Terminal 2 - API version for automation
cd bb-tpp-api-simulator
npm start  # Runs on port 3002
```

---

## 💻 API Interface Comparison

### bb-tpp-simulator
The UI version has the same backend APIs, but they're designed to be consumed by the React frontend:

```bash
# Works, but responses are frontend-oriented
curl -X POST http://localhost:3001/api/ais/create-consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://example.com/callback",
    "permissions": [...],
    "transactionFromDateTime": "...",
    "transactionToDateTime": "...",
    "expirationDateTime": "..."
  }'
```

### bb-tpp-api-simulator
API-only version with simplified curl-friendly endpoints:

```bash
# Simplified - uses defaults from .env
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{}'

# All parameters optional, helpful console output
curl -X POST http://localhost:3002/api/ais/consent \
  -H "Content-Type: application/json" \
  -d '{
    "providerCode": "backbase_dev_uk",
    "redirectUri": "https://example.com/callback"
  }'
```

### Key Differences:
1. **Simplified endpoints**: `/api/ais/consent` vs `/api/ais/create-consent`
2. **Default values**: Uses .env defaults when parameters not provided
3. **Response format**: More automation-friendly with `success` flag
4. **Console output**: Helpful logging for curl usage
5. **Token exchange**: Dedicated `/api/ais/token` endpoint

---

## 📦 Setup Comparison

### bb-tpp-simulator Setup
```bash
npm install
cd client && npm install && cd ..
npm run build:client
npm start
```

**Dependencies:**
- Backend: Express, axios, dotenv, jsonwebtoken
- Frontend: React, build tools, webpack
- Total packages: ~1000+

### bb-tpp-api-simulator Setup
```bash
npm install
npm start
```

**Dependencies:**
- Backend only: Express, axios, dotenv, jsonwebtoken
- Total packages: ~95

**Startup time:** ~50% faster (no client build)

---

## 🐳 Docker Comparison

### bb-tpp-simulator Docker
```bash
# Multi-stage build for React app
docker build -t bb-tpp-simulator .  # ~500MB+
docker run -p 3001:3001 bb-tpp-simulator
```

### bb-tpp-api-simulator Docker
```bash
# Simple Node.js image
docker build -t bb-tpp-api-simulator .  # ~150MB
docker run -p 3002:3002 bb-tpp-api-simulator
```

**Image size:** ~70% smaller

---

## 🔄 Migration Guide

### From UI to API Version

If you're already using bb-tpp-simulator and want to add API-only testing:

1. **Copy configuration:**
   ```bash
   cd bb-tpp-api-simulator
   ./setup-from-existing.sh
   ```

2. **Start API simulator:**
   ```bash
   npm start
   ```

3. **Test it works:**
   ```bash
   curl http://localhost:3002/api/health
   ```

4. **Update your scripts:**
   - Change port from `3001` to `3002`
   - Update endpoint paths (e.g., `/api/ais/create-consent` → `/api/ais/consent`)
   - Remove UI dependencies

### From API to UI Version

If you need to add visual testing:

1. **Copy configuration to UI version:**
   ```bash
   cd bb-tpp-simulator
   cp ../bb-tpp-api-simulator/.env ./.env
   cp ../bb-tpp-api-simulator/private_key.pem ./private_key.pem
   ```

2. **Install and build:**
   ```bash
   npm install
   cd client && npm install && cd ..
   npm run build:client
   ```

3. **Start UI simulator:**
   ```bash
   npm start
   ```

4. **Access at:** http://localhost:3001

---

## 🧪 Testing Workflow Comparison

### Manual Testing (UI Version)
1. Open browser → http://localhost:3001
2. Select provider from dropdown
3. Click "Create Consent"
4. Click authorization URL
5. Complete flow in browser
6. View accounts in UI
7. Click through transactions, balances

**Time per test:** ~2-3 minutes

### Automated Testing (API Version)
```bash
./test-flow.sh
# Runs complete flow in ~30 seconds
```

Or integrate into test suite:
```javascript
describe('AIS Flow', () => {
  it('should create consent and fetch accounts', async () => {
    const consent = await createConsent();
    const authUrl = consent.data.authorizationUrl;
    // ... automated flow
  });
});
```

**Time per test:** ~30 seconds (automated)

---

## 📈 Resource Usage

### bb-tpp-simulator (UI)
- **Memory:** ~200MB
- **CPU:** Medium (React rendering)
- **Disk:** ~500MB (node_modules + build)
- **Build time:** ~30-60 seconds

### bb-tpp-api-simulator (API-only)
- **Memory:** ~50MB
- **CPU:** Low
- **Disk:** ~150MB (node_modules only)
- **Build time:** 0 seconds (no build)

---

## 🎓 Learning Curve

### bb-tpp-simulator
- ✅ Easy to understand visually
- ✅ Self-explanatory UI
- ⚠️ Requires React knowledge for modifications
- ⚠️ Build process complexity

### bb-tpp-api-simulator
- ✅ Simple API structure
- ✅ Easy to integrate
- ✅ Straightforward curl commands
- ⚠️ No visual feedback (logs only)
- ⚠️ Requires basic curl/API knowledge

---

## 🏆 Recommendations

### Use bb-tpp-simulator when:
- 👥 You're doing manual testing
- 🎨 You need visual feedback
- 📊 You're demoing to non-technical stakeholders
- 🎓 You're training team members
- 🔍 You're exploring/debugging interactively

### Use bb-tpp-api-simulator when:
- 🤖 You're automating tests
- 🚀 You're building CI/CD pipelines
- 📈 You're doing load/performance testing
- 🔧 You're integrating with other services
- 🐳 You're deploying to containers
- ⚡ You want faster startup times
- 💾 You want smaller resource footprint

### Use Both when:
- 🔄 You need both manual and automated testing
- 👥 You have QA team (UI) and automation team (API)
- 🎯 You want best of both worlds

---

## 🚦 Quick Decision Guide

```
Do you need a user interface?
├─ Yes → Use bb-tpp-simulator
└─ No → Use bb-tpp-api-simulator

Is this for automation?
├─ Yes → Use bb-tpp-api-simulator
└─ No → Use bb-tpp-simulator

Is this for CI/CD?
└─ Use bb-tpp-api-simulator

Is this for demos?
└─ Use bb-tpp-simulator

Do you have limited resources?
└─ Use bb-tpp-api-simulator

Do you need visual debugging?
└─ Use bb-tpp-simulator
```

---

## 📞 Support

For questions about which version to use, contact the Backbase Open Banking team.


