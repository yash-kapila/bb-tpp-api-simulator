# Changelog

All notable changes to bb-tpp-api-simulator will be documented in this file.

---

## [1.0.0] - 2025-11-02

### 🎉 Initial Release

A brand new curl-friendly API-only TPP simulator for UK Open Banking testing.

### ✨ Features

#### Core Functionality
- **AIS Consent Flow**: Complete Account Information Services flow
- **SaltEdge Integration**: Full integration with SaltEdge Priora
- **REST API**: Clean, curl-friendly endpoints
- **No UI**: Pure API interface for automation

#### API Endpoints
- `POST /api/ais/consent` - Create AIS consent and get authorization URL
- `POST /api/ais/token` - Exchange authorization code for access token
- `GET /api/ais/accounts` - Fetch all accounts
- `GET /api/ais/accounts/:id/transactions` - Get account transactions
- `GET /api/ais/accounts/:id/balances` - Get account balances
- `GET /api/ais/accounts/:id/standing-orders` - Get standing orders
- `POST /api/ais/accounts/refresh` - Trigger account data refresh
- `GET /api/ais/accounts/refresh/status` - Check refresh status
- `GET /api/ais/consent/:id` - Get consent details
- `GET /api/health` - Health check endpoint

#### Configuration
- Environment-based configuration via `.env`
- Default values for simplified testing
- Support for multiple providers (UK & EU)
- Flexible private key configuration

#### Documentation
- `README.md` - Comprehensive guide with examples
- `QUICKSTART.md` - 5-minute setup guide
- `CURL_EXAMPLES.md` - Quick reference for all curl commands
- `COMPARISON.md` - Compare with UI version
- Inline API documentation at root endpoint

#### Testing & Automation
- `test-flow.sh` - Interactive test script for complete flow
- `setup-from-existing.sh` - Helper to migrate from UI version
- Example integration scripts (Bash, Python, Node.js)

#### Deployment
- `Dockerfile` - Optimized Docker image
- `docker-compose.yml` - Easy container deployment
- `.dockerignore` - Minimal image size
- Health checks included

#### Developer Experience
- Colored console output
- Helpful error messages
- Request logging
- Auto-reload in dev mode (`npm run dev`)
- No build step required

### 🏗️ Architecture

**Technology Stack:**
- Node.js 18+
- Express.js
- axios for HTTP requests
- jsonwebtoken for JWT handling
- dotenv for configuration

**Project Structure:**
```
bb-tpp-api-simulator/
├── server/
│   ├── index.js              # Main server
│   ├── routes/
│   │   └── ais.js            # AIS endpoints
│   └── services/
│       └── saltedge.js       # SaltEdge integration
├── Documentation files
├── Helper scripts
└── Docker files
```

### 📊 Statistics

- **Dependencies**: 95 packages (vs 1000+ in UI version)
- **Memory usage**: ~50MB (vs ~200MB UI version)
- **Disk space**: ~150MB (vs ~500MB UI version)
- **Startup time**: ~1 second (vs ~30+ seconds with build)
- **Docker image**: ~150MB (vs ~500MB+ with UI)

### 🎯 Design Principles

1. **Simplicity**: One curl command to get started
2. **Automation-first**: Designed for CI/CD and scripting
3. **Defaults everywhere**: Minimal required parameters
4. **Helpful output**: Clear console logging
5. **Developer-friendly**: Easy to understand and extend

### 🔒 Security

- Private key stored separately (not in code)
- Environment variables for sensitive data
- `.gitignore` prevents committing secrets
- File permissions recommended (600 for private key)

### 🤝 Compatibility

**Providers Supported:**
- Backbase DEV UK (`backbase_dev_uk`)
- Backbase UAT UK (`backbase_uat_uk`)
- Backbase DEV EU (`backbase_dev_eu`)
- Backbase UAT EU (`backbase_uat_eu`)

**Protocols:**
- UK Open Banking v3.1
- OAuth 2.0 with JWT authentication
- OIDC discovery

### 📝 Known Limitations

1. **No UI**: By design - use bb-tpp-simulator for visual testing
2. **AIS only**: PIS (Payment Initiation) not yet implemented
3. **Manual authorization step**: Browser interaction still required
4. **No datastore**: Stateless design, doesn't persist consent data

### 🚀 Migration from bb-tpp-simulator

Use the included setup script:
```bash
./setup-from-existing.sh
```

This automatically:
- Copies `.env` configuration
- Copies private key
- Updates port to 3002
- Preserves all settings

### 🙏 Credits

Based on bb-tpp-simulator by the Backbase Open Banking team.
Refactored for API-only use case and automation.

---

## Future Plans

### [1.1.0] - Planned
- [ ] Payment Initiation Services (PIS) support
- [ ] Batch operations endpoint
- [ ] WebSocket support for real-time updates
- [ ] Built-in token caching

### [1.2.0] - Planned
- [ ] Multiple provider parallel requests
- [ ] Consent management dashboard (minimal)
- [ ] OpenAPI/Swagger documentation
- [ ] Metrics endpoint

### [2.0.0] - Planned
- [ ] Multi-tenancy support
- [ ] Database persistence (optional)
- [ ] Advanced error handling
- [ ] Retry logic and circuit breakers

---

## Support

For issues, feature requests, or questions:
- Contact the Backbase Open Banking team
- Check `README.md` for troubleshooting
- Review `CURL_EXAMPLES.md` for usage examples


