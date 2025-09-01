# TrustNet Protocol

> A reputation-based trust system for the Bitcoin ecosystem, built on Stacks

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Clarity Version](https://img.shields.io/badge/Clarity-3.0-orange.svg)](https://docs.stacks.co/clarity)
[![Bitcoin Anchored](https://img.shields.io/badge/Bitcoin-Anchored-f7931a.svg)](https://stacks.co)

## Overview

TrustNet establishes the foundational layer for reputation-based systems in the Bitcoin ecosystem. By leveraging Stacks' smart contract capabilities and Bitcoin's immutable consensus, TrustNet creates verifiable trust scores that enhance security, reduce counterparty risk, and enable sophisticated DeFi interactions.

## Key Innovations

- **Time-weighted reputation** with entropy-resistant decay mechanisms
- **Multi-dimensional trust scoring** for diverse Bitcoin applications
- **Cryptographically verifiable audit trails** anchored to Bitcoin
- **Dynamic threshold management** for cross-platform integrations
- **Gas-optimized batch operations** for Lightning Network compatibility

## Security Model

All reputation state transitions are cryptographically committed to Bitcoin's blockchain via Stacks' unique consensus mechanism, ensuring that trust scores inherit Bitcoin's security guarantees while enabling programmable logic for complex reputation calculations.

## Architecture

### Core Components

#### 1. Trust Registry

The central data structure mapping principals to their trust profiles:

```clarity
{
  unique-handle: (string-ascii 64),     // Human-readable identifier
  trust-coefficient: uint,              // Current trust score (0-10000)
  genesis-block: uint,                  // Registration block height
  last-interaction: uint,               // Most recent activity
  entropy-checkpoint: uint,             // Last decay calculation
  verified-operations: uint,            // Cumulative successful actions
  active-status: bool,                  // Operational state
  trust-tier: uint                      // Categorical classification (0-5)
}
```

#### 2. Trust Operations

Configurable actions that users can perform to earn trust:

```clarity
{
  trust-multiplier: uint,               // Base points awarded
  operation-description: (string-ascii 120),
  minimum-tier-requirement: uint,       // Required trust tier
  maximum-daily-executions: uint,       // Rate limiting
  operational: bool                     // Enable/disable flag
}
```

#### 3. Ecosystem Credentials

Cross-platform integration permissions:

```clarity
{
  minimum-trust-threshold: uint,        // Required score for access
  credential-issued: uint,              // Grant timestamp
  credential-expires: uint,             // Expiration block
  privilege-level: uint,                // Tiered access level
  revocation-flag: bool                 // Emergency disable
}
```

### Trust Scoring Algorithm

The trust scoring system uses a sophisticated multi-factor approach:

1. **Base Score Calculation**: Operations award points based on type and user tier
2. **Tier Multipliers**: Higher-tier users earn bonus points (1-1.5x multiplier)
3. **Entropy Decay**: Non-linear decay prevents score stagnation
4. **Ceiling Protection**: Maximum score of 10,000 (100.00%) prevents inflation

#### Trust Tiers

| Tier | Score Range | Description |
|------|-------------|-------------|
| 0    | 0-499       | Unrated     |
| 1    | 500-1999    | Novice      |
| 2    | 2000-3999   | Basic       |
| 3    | 4000-5999   | Medium      |
| 4    | 6000-7999   | High        |
| 5    | 8000-10000  | Elite       |

## Protocol Functions

### Identity Management

#### `establish-trust-identity`

```clarity
(define-public (establish-trust-identity (unique-handle (string-ascii 64))))
```

Register a new identity in the trust network with bootstrap score allocation.

#### `modify-identity-status`

```clarity
(define-public (modify-identity-status (active-state bool)))
```

Enable or disable identity participation in the protocol.

### Trust Operations

#### `execute-trust-operation`

```clarity
(define-public (execute-trust-operation (operation-type (string-ascii 48))))
```

Execute a trust-earning operation with automatic entropy decay application.

#### `trigger-entropy-decay`

```clarity
(define-public (trigger-entropy-decay))
```

Manually apply entropy decay to prevent gaming and ensure active participation.

### Governance Functions

#### `delegate-governance-authority`

```clarity
(define-public (delegate-governance-authority (new-authority principal)))
```

Transfer protocol governance to a new authority with security checks.

#### `register-trust-operation`

```clarity
(define-public (register-trust-operation 
  (operation-type (string-ascii 48))
  (multiplier uint)
  (description (string-ascii 120))
  (tier-requirement uint)
  (daily-limit uint)))
```

Add new trust-earning operations to the protocol.

### Cross-Ecosystem Integration

#### `grant-ecosystem-credential`

```clarity
(define-public (grant-ecosystem-credential
  (ecosystem (string-ascii 32))
  (trust-threshold uint)
  (validity-duration uint)
  (privilege-tier uint)))
```

Issue credentials for external ecosystem access based on trust scores.

### Query Interface

#### `get-trust-coefficient`

```clarity
(define-read-only (get-trust-coefficient (identity principal)))
```

Retrieve current trust score for an identity.

#### `verify-trust-threshold`

```clarity
(define-read-only (verify-trust-threshold 
  (identity principal)
  (required-threshold uint)))
```

Check if an identity meets a specific trust threshold with detailed response.

#### `simulate-trust-operation`

```clarity
(define-read-only (simulate-trust-operation
  (identity principal)
  (operation-type (string-ascii 48))))
```

Calculate projected trust score after operation execution.

## Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/akeem-ibrahim/trustnet.git
cd trustnet
```

2. Install dependencies:

```bash
npm install
```

3. Verify contract syntax:

```bash
clarinet check
```

### Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage and cost analysis:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

### Contract Deployment

1. **Local Development**:

```bash
clarinet integrate
```

2. **Testnet Deployment**:

```bash
clarinet deploy --testnet
```

3. **Mainnet Deployment**:

```bash
clarinet deploy --mainnet
```

## Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX_TRUST_SCORE` | 10000 | Maximum achievable trust score |
| `GENESIS_TRUST_SCORE` | 750 | Initial score for new identities |
| `ENTROPY_DECAY_FACTOR` | 12 | Base decay rate (1.2% per cycle) |
| `MIN_IDENTITY_LENGTH` | 8 | Minimum handle character count |
| `PROTOCOL_REVISION` | 300 | Current implementation version |

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 1001 | `ERR_UNAUTHORIZED` | Insufficient privileges |
| 1002 | `ERR_MALFORMED_DATA` | Invalid input format |
| 1003 | `ERR_IDENTITY_EXISTS` | Duplicate registration |
| 1004 | `ERR_IDENTITY_UNKNOWN` | Unregistered account |
| 1005 | `ERR_TRUST_INSUFFICIENT` | Below required threshold |
| 1006 | `ERR_TRUST_SATURATED` | Maximum score reached |
| 1007 | `ERR_OPERATION_EXISTS` | Duplicate operation type |
| 1008 | `ERR_OPERATION_UNKNOWN` | Invalid operation reference |
| 1009 | `ERR_GOVERNANCE_LOCK` | Admin access required |
| 1010 | `ERR_PROTOCOL_OFFLINE` | System maintenance mode |

## Use Cases

### DeFi Lending Protocols

- Collateral ratio adjustments based on borrower trust scores
- Interest rate optimization for trusted participants
- Automated liquidation thresholds

### Lightning Network Routing

- Channel reliability scoring for pathfinding algorithms
- Watchtower selection based on operator reputation
- Payment routing optimization

### Bitcoin Marketplace Integration

- Seller/buyer reputation for P2P trading
- Escrow service selection
- Dispute resolution weighting

### Cross-Chain Bridge Operations

- Validator selection and rotation
- Slashing condition adjustments
- Emergency response coordination

## Governance

The TrustNet protocol implements a governance model with the following principles:

1. **Minimal Viable Governance**: Core parameters are adjustable but constrained
2. **Emergency Controls**: Circuit breakers for critical security events
3. **Transparent Operations**: All governance actions are logged on-chain
4. **Progressive Decentralization**: Authority can be transferred to DAOs or multisigs

## Security Considerations

### Audit Status

- [ ] Initial security review
- [ ] Formal verification of core algorithms
- [ ] Economic model analysis
- [ ] Integration testing with Bitcoin testnet

### Known Limitations

- Trust scores are not transferable between identities
- Entropy decay may require periodic manual triggers for inactive users
- Cross-ecosystem credential revocation requires active monitoring

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and add tests
4. Ensure all tests pass: `npm test`
5. Format code: `clarinet fmt`
6. Submit a pull request

## Roadmap

### Phase 1: Core Protocol (Current)

- [x] Basic trust scoring system
- [x] Identity registration and management
- [x] Entropy decay mechanisms
- [x] Cross-ecosystem credentials

### Phase 2: Advanced Features

- [ ] Multi-signature governance
- [ ] Delegation and proxy voting
- [ ] Advanced analytics dashboard
- [ ] Lightning Network integration

### Phase 3: Ecosystem Integration

- [ ] DeFi protocol partnerships
- [ ] Bitcoin marketplace integration
- [ ] Cross-chain bridge implementations
- [ ] Developer SDK and tooling

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
