# Nexus Investment Service (Funding Requests)

## 1. Overview
The Nexus Investment Service allows a product funder (creator/owner) on the Nexus platform to raise capital for a product or business initiative that requires additional funds. A funder creates a Funding Request specifying:
- Title & description
- Required principal (total capital needed)
- Deadline for raising funds
- Committed return amount (total extra amount funder promises to distribute back to investors when the product succeeds)

Investors can contribute funds until the required amount is reached. When fully funded, the funder's wallet is credited with the raised principal. Later, when the funder decides to distribute returns, the service debits the funder's wallet with (principal + committed return) and credits each investor proportionally (principal they invested + their pro‑rata share of the committed return).

## 2. Core Concepts
| Concept | Description |
|---------|-------------|
| Funding Request | Aggregate representing a capital raise event initiated by a funder. |
| Required Amount | Total principal needed. Investors can collectively invest up to this cap. |
| Current Funded | Running total of investments accepted so far. |
| Committed Return Amount | Total gross return (extra over principal) promised to investors (distributed later). |
| Investor Amounts Map | Maintains cumulative principal invested per investor (supports multiple partial investments). |
| Status | Lifecycle state: OPEN -> FUNDED -> (optionally) CLOSED. Returns can only be distributed after FUNDED. |
| Return Distribution | Single irreversible operation crediting investors and debiting funder. Marks `returnDistributed=true`. |

## 3. Status Lifecycle
1. OPEN (initial): Accepts investments and updates.
2. FUNDED: Triggered automatically when `currentFunded >= requiredAmount`. No further updates or investments allowed.
3. CLOSED: (Reserved for future flow; not currently set by service logic.)

Return distribution only allowed when:
- Status == FUNDED
- Returns not already distributed
- At least one investor exists

## 4. Data Model (`FundingRequest`)
```
FundingRequest {
  id: String
  title: String
  description: String
  funderId: String
  requiredAmount: double
  currentFunded: double
  committedReturnAmount: double
  status: OPEN | FUNDED | CLOSED
  createdAt: LocalDateTime
  deadline: LocalDateTime
  investorAmounts: Map<investorId, Double> // cumulative principal
  returnDistributed: boolean // once returns paid
}
```

### Derived Ratios During Distribution
For each investor: `ratio = investedPrincipal / totalPrincipalRaised`.
Their payout = `investedPrincipal + (ratio * committedReturnAmount)`.

## 5. Validation Rules
- Create
  - `requiredAmount >= 100.00`
  - `deadline` must be in the future
  - `committedReturnAmount >= 0`
  - Non-blank `title` and `description`
- Update (only while OPEN, only by original funder)
  - Optional fields; validation applied if present
  - Cannot update once FUNDED
- Invest
  - Request must be OPEN
  - Incoming `walletAdjustment` must be negative (deduction from investor wallet)
  - Absolute value of investment may not exceed remaining required amount
  - Reaching or exceeding required amount flips status to FUNDED and credits the funder with the total principal raised
- Distribute Returns
  - Only if FUNDED and not already distributed
  - Debits funder first by `principal + committedReturnAmount`
  - Credits each investor principal plus pro‑rata share of committed return

## 6. Wallet Interaction
This service does not persist wallet balances; it delegates wallet changes to the User Service via HTTP (WebClient). Each investment or distribution constructs a `UserUpdateRequestDTO` (not shown here) with `walletAdjustment` (positive for credit, negative for debit) and a list of associated `fundingRequestIds`.

Failure in downstream wallet update results in an exception and the funding request state is not mutated (fail-fast behavior).

## 7. API Endpoints
Base Path: `/api/v1/funding-requests`

### 7.1 Create Funding Request
POST `/api/v1/funding-requests`
Headers: `X-User-Id: <funderId>`
Body:
```
{
  "title": "Smart Hydroponics Expansion",
  "requiredAmount": 5000.00,
  "deadline": "2025-12-31T23:59:00",
  "committedReturnAmount": 750.00,
  "description": "Expand production capacity and enter two new markets." 
}
```
201 Created Response (excerpt):
```
{
  "id": "...",
  "status": "OPEN",
  "currentFunded": 0.0,
  "investorAmounts": {}
}
```

### 7.2 List Funding Requests
GET `/api/v1/funding-requests`
Response: `200 OK` array of FundingRequest objects.

### 7.3 Get Funding Request by ID
GET `/api/v1/funding-requests/{requestId}`
Response: `200 OK` FundingRequest.
404 if not found.

### 7.4 Update Funding Request (OPEN only)
PUT `/api/v1/funding-requests/{requestId}`
Headers: `X-User-Id: <funderId>`
Body (any subset):
```
{
  "title": "Updated Title",
  "deadline": "2026-01-15T12:00:00",
  "description": "Refined scope",
  "committedReturnAmount": 800.00
}
```
Response: `200 OK` updated FundingRequest.
403 if not owner. 400 if not OPEN.

### 7.5 Invest in Funding Request
POST `/api/v1/funding-requests/{requestId}/investment`
Headers: `X-User-Id: <investorId>`
Body:
```
{
  "walletAdjustment": -1200.00
}
```
Notes:
- `walletAdjustment` must be negative.
- The service sets `investorId` from header internally.
- On crossing funding goal, status transitions to FUNDED and funder's wallet credited with `currentFunded`.
Response: `200 OK` FundingRequest (updated totals).
Errors: 400 (validation), 404 (request not found), 502 (downstream user service error), 400 (investment exceeds remaining).

### 7.6 Distribute Returns
POST `/api/v1/funding-requests/{requestId}/distribute-returns`
Response: `200 OK` FundingRequest with `returnDistributed=true`.
Errors: 400 (not FUNDED, already distributed, no investors), 404 (not found), 502 (downstream user service error).

## 8. Error Handling
Errors use Spring `ResponseStatusException` with meaningful messages. Common codes:
- 400 Bad Request: Validation failures, invalid lifecycle transitions.
- 403 Forbidden: Unauthorized update attempt (non-owner).
- 404 Not Found: Funding request missing.
- 502 Bad Gateway: Downstream user service error.

## 9. Pro‑Rata Return Calculation Example
Scenario:
- requiredAmount = 10,000
- committedReturnAmount = 2,000
- Investors:
  - A invests 4,000
  - B invests 3,000
  - C invests 3,000
Total principal = 10,000 (status FUNDED)
Ratios: A=0.4, B=0.3, C=0.3
Return Shares: A=800, B=600, C=600
Distribution (after success):
- Funder debited: 12,000 (principal + committed return)
- A credited 4,800; B credited 3,600; C credited 3,600

## 10. Technology Stack
- Java 21 (inferred from Spring Boot 3.5.x compatibility)
- Spring Boot (Web, Reactive WebClient)
- Spring Data MongoDB
- Maven build
- SLF4J + Logback for logging

## 11. Configuration
Edit `application.properties` for MongoDB connection and service-specific settings.
`Constants.USER_SERVICE_BASE_URL` currently points to `http://localhost:3000/api/v1/users` — adjust for deployed environment (e.g., service discovery, Kubernetes). WebClient bean likely configured in `config` package.

## 12. Running & Building
Build:
```bash
./mvnw clean package
```
Run:
```bash
./mvnw spring-boot:run
```
Or run the generated jar:
```bash
java -jar target/investment-service-0.0.1-SNAPSHOT.jar
```

## 13. Local Testing (Sample curl)
Create:
```bash
curl -X POST http://localhost:8080/api/v1/funding-requests \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: FUND123' \
  -d '{"title":"AI Coffee Roaster","requiredAmount":1500,"deadline":"2026-01-01T00:00:00","committedReturnAmount":300,"description":"Prototype smart roaster"}'
```
Invest:
```bash
curl -X POST http://localhost:8080/api/v1/funding-requests/{id}/investment \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: INV456' \
  -d '{"walletAdjustment": -500}'
```
Distribute Returns:
```bash
curl -X POST http://localhost:8080/api/v1/funding-requests/{id}/distribute-returns
```

## 14. Logging Conventions
Controller level: `[HTTP] <action>`
Service level: lifecycle and decision points (investments, funding completion, distribution steps).
Use DEBUG for fine-grained changes (field updates), INFO for major events.

## 15. Extensibility / Future Enhancements
- Add status CLOSED after return distribution automatically.
- Add cancellation flow: funder can close request early (refund investors).
- Support partial return distributions / milestones.
- Add pagination & filtering (status, deadline) to list endpoint.
- Add authentication & authorization integration (currently header-based user id assumed trusted).
- Add optimistic locking to avoid race conditions on simultaneous investments.

## 16. Security Considerations
- Validate all incoming numeric values to prevent overflow or negative logic bypass.
- Ensure user IDs from headers are authenticated by an API gateway in production.
- Rate-limit investment endpoint to mitigate spam or race conditions.
- Consider idempotency keys for investment calls.

## 17. Testing Strategy
Unit tests should target:
- Validation logic (ownership, status, investment limits)
- Funding threshold transition to FUNDED
- Return distribution proportion correctness (edge case: single investor)
- Downstream wallet failure rollback semantics

Integration tests can mock User Service responses (success, 400, 500).

## 18. Edge Cases
- Investing exact remaining amount (triggers FUNDED)
- Attempt distribution twice (should 400)
- Investment attempt after FUNDED (should 400)
- No investors but distribution attempt (should 400)
- Committed return = 0 (distribution returns only principal)

## 19. Glossary
- Principal: Sum of all invested amounts (without committed return).
- Committed Return: Additional aggregate amount promised by funder beyond principal.
- Pro‑Rata: Allocation proportional to each investor's share of principal.

## 20. Maintainers
Replace with actual team contact information.

---
This README replaces the initial auto-generated Spring Boot documentation to provide domain‑specific guidance for the Nexus Investment Service.

