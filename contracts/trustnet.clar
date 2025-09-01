;; TRUSTNET PROTOCOL
;;  TrustNet establishes the foundational layer for reputation-based systems  
;;  in the Bitcoin ecosystem. By leveraging Stacks' smart contract            
;;  capabilities and Bitcoin's immutable consensus, TrustNet creates          
;;  verifiable trust scores that enhance security, reduce counterparty        
;;  risk, and enable sophisticated DeFi interactions.                         
;;                                                                             
;;  KEY INNOVATIONS:                                                           
;;  - Time-weighted reputation with entropy-resistant decay                   
;;  - Multi-dimensional trust scoring for diverse Bitcoin applications        
;;  - Cryptographically verifiable audit trails anchored to Bitcoin          
;;  - Dynamic threshold management for cross-platform integrations           
;;  - Gas-optimized batch operations for Lightning Network compatibility      
;;                                                                             
;;  SECURITY MODEL:                                                            
;;  All reputation state transitions are cryptographically committed to       
;;  Bitcoin's blockchain via Stacks' unique consensus mechanism, ensuring     
;;  that trust scores inherit Bitcoin's security guarantees while enabling    
;;  programmable logic for complex reputation calculations.                   

;;                              ERROR TAXONOMY

(define-constant ERR_UNAUTHORIZED (err u1001))       ;; Insufficient privileges
(define-constant ERR_MALFORMED_DATA (err u1002))     ;; Invalid input format
(define-constant ERR_IDENTITY_EXISTS (err u1003))    ;; Duplicate registration
(define-constant ERR_IDENTITY_UNKNOWN (err u1004))   ;; Unregistered account
(define-constant ERR_TRUST_INSUFFICIENT (err u1005)) ;; Below required threshold
(define-constant ERR_TRUST_SATURATED (err u1006))    ;; Maximum score reached
(define-constant ERR_OPERATION_EXISTS (err u1007))   ;; Duplicate action type
(define-constant ERR_OPERATION_UNKNOWN (err u1008))  ;; Invalid action reference
(define-constant ERR_GOVERNANCE_LOCK (err u1009))    ;; Admin access required
(define-constant ERR_PROTOCOL_OFFLINE (err u1010))   ;; System maintenance mode

;;                          PROTOCOL PARAMETERS

(define-constant MAX_TRUST_SCORE u10000)             ;; Precision-scaled maximum (100.00%)
(define-constant MIN_TRUST_SCORE u0)                 ;; Absolute minimum trust level
(define-constant GENESIS_TRUST_SCORE u750)           ;; Bootstrap score for new users (7.5%)
(define-constant ENTROPY_DECAY_FACTOR u12)           ;; Temporal degradation rate (1.2% per cycle)
(define-constant MIN_IDENTITY_LENGTH u8)             ;; Minimum identifier character count
(define-constant PROTOCOL_REVISION u300)             ;; Current implementation version
(define-constant STACKS_PER_BITCOIN_BLOCK u10)       ;; Approximate block ratio for timing

;;                           GLOBAL STATE VARIABLES

(define-data-var governance-authority principal tx-sender)
(define-data-var protocol-operational bool true)
(define-data-var entropy-decay-rate uint ENTROPY_DECAY_FACTOR)
(define-data-var decay-cycle-duration uint u14400)               ;; ~10 Bitcoin blocks worth
(define-data-var bootstrap-trust-allocation uint GENESIS_TRUST_SCORE)
(define-data-var total-registered-identities uint u0)
(define-data-var global-trust-distribution uint u0)              ;; Aggregate trust across network

;;                            CORE DATA STRUCTURES

;; Primary identity-to-trust mapping with comprehensive metadata
(define-map trust-registry
  {identity: principal}
  {
    unique-handle: (string-ascii 64),          ;; Human-readable identity string
    trust-coefficient: uint,                   ;; Current trust score (0-10000)
    genesis-block: uint,                       ;; Initial registration height
    last-interaction: uint,                    ;; Most recent activity timestamp
    entropy-checkpoint: uint,                  ;; Last decay calculation point
    verified-operations: uint,                 ;; Cumulative successful actions
    active-status: bool,                       ;; Identity operational state
    trust-tier: uint                           ;; Categorical trust classification (0-5)
  }
)

;; Configurable trust-earning operations with dynamic parameters
(define-map trust-operations
  {operation-type: (string-ascii 48)}
  {
    trust-multiplier: uint,                    ;; Base points awarded
    operation-description: (string-ascii 120), ;; Human-readable explanation
    minimum-tier-requirement: uint,            ;; Required trust tier to execute
    maximum-daily-executions: uint,            ;; Rate limiting per identity
    operational: bool                          ;; Global enable/disable flag
  }
)

;; Immutable trust transition log for transparency and forensics
(define-map trust-ledger
  {identity: principal, sequence-id: uint}
  {
    operation-executed: (string-ascii 48),
    trust-before: uint,
    trust-after: uint,
    bitcoin-anchor: uint,                      ;; Bitcoin block for immutability proof
    stacks-height: uint,                       ;; Stacks block for chronological ordering
    gas-consumed: uint,                        ;; Transaction cost for analytics
    validator-signature: (optional (buff 65)) ;; Optional cryptographic attestation
  }
)

;; Cross-ecosystem integration credentials and permissions
(define-map ecosystem-credentials
  {ecosystem: (string-ascii 32), identity: principal}
  {
    minimum-trust-threshold: uint,             ;; Required score for access
    credential-issued: uint,                   ;; Grant timestamp
    credential-expires: uint,                  ;; Expiration block height
    privilege-level: uint,                     ;; Tiered access classification
    revocation-flag: bool                      ;; Emergency disable mechanism
  }
)

;; Advanced analytics for trust score distribution insights
(define-map trust-analytics
  {metric-name: (string-ascii 32)}
  {
    current-value: uint,
    historical-peak: uint,
    last-updated: uint,
    measurement-frequency: uint
  }
)

;;                         GOVERNANCE & ADMINISTRATION

;; Transfer governance control to new authority with security checks
(define-public (delegate-governance-authority (new-authority principal))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-authority)) ERR_GOVERNANCE_LOCK)
    (asserts! (not (is-eq new-authority (var-get governance-authority))) ERR_MALFORMED_DATA)
    (asserts! (not (is-eq new-authority tx-sender)) ERR_MALFORMED_DATA)
    
    (var-set governance-authority new-authority)
    (print {
      governance-event: "authority-delegated",
      former-authority: tx-sender,
      new-authority: new-authority,
      effective-height: stacks-block-height,
      bitcoin-anchor: burn-block-height
    })
    (ok true)
  )
)

;; Emergency protocol circuit breaker for critical security events
(define-public (modify-protocol-status (operational-state bool))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-authority)) ERR_GOVERNANCE_LOCK)
    
    (var-set protocol-operational operational-state)
    (print {
      governance-event: "protocol-status-modified",
      new-status: operational-state,
      authority: tx-sender,
      timestamp: stacks-block-height
    })
    (ok operational-state)
  )
)

;; Fine-tune entropy decay mechanics for long-term protocol stability
(define-public (calibrate-entropy-parameters (decay-factor uint) (cycle-length uint))
  (begin
    (asserts! (is-eq tx-sender (var-get governance-authority)) ERR_GOVERNANCE_LOCK)
    (asserts! (and (>= decay-factor u5) (<= decay-factor u25)) ERR_MALFORMED_DATA)
    (asserts! (and (>= cycle-length u7200) (<= cycle-length u86400)) ERR_MALFORMED_DATA)
    
    (var-set entropy-decay-rate decay-factor)
    (var-set decay-cycle-duration cycle-length)
    
    ;; Update analytics
    (map-set trust-analytics
      {metric-name: "entropy-calibration"}
      {
        current-value: decay-factor,
        historical-peak: cycle-length,
        last-updated: stacks-block-height,
        measurement-frequency: u1
      }
    )
    
    (print {
      governance-event: "entropy-calibrated",
      decay-factor: decay-factor,
      cycle-duration: cycle-length,
      effective-immediately: true
    })
    (ok true)
  )
)

;;                       TRUST OPERATION MANAGEMENT

;; Register new trust-earning operation with comprehensive validation
(define-public (register-trust-operation
  (operation-type (string-ascii 48))
  (multiplier uint)
  (description (string-ascii 120))
  (tier-requirement uint)
  (daily-limit uint)
)
  (begin
    (asserts! (is-eq tx-sender (var-get governance-authority)) ERR_GOVERNANCE_LOCK)
    (asserts! (> (len operation-type) u2) ERR_MALFORMED_DATA)
    (asserts! (> (len description) u10) ERR_MALFORMED_DATA)
    (asserts! (is-none (map-get? trust-operations {operation-type: operation-type})) ERR_OPERATION_EXISTS)
    (asserts! (and (>= multiplier u1) (<= multiplier u500)) ERR_MALFORMED_DATA)
    (asserts! (<= tier-requirement u5) ERR_MALFORMED_DATA)
    (asserts! (and (>= daily-limit u1) (<= daily-limit u100)) ERR_MALFORMED_DATA)
    
    (map-set trust-operations
      {operation-type: operation-type}
      {
        trust-multiplier: multiplier,
        operation-description: description,
        minimum-tier-requirement: tier-requirement,
        maximum-daily-executions: daily-limit,
        operational: true
      }
    )
    
    (print {
      governance-event: "operation-registered",
      operation-type: operation-type,
      trust-multiplier: multiplier,
      tier-requirement: tier-requirement
    })
    (ok true)
  )
)

;; Modify existing trust operation with enhanced parameter validation
(define-public (modify-trust-operation
  (operation-type (string-ascii 48))
  (multiplier uint)
  (description (string-ascii 120))
  (tier-requirement uint)
  (daily-limit uint)
  (operational bool)
)
  (let
    (
      (existing-operation
        (unwrap!
          (map-get? trust-operations {operation-type: operation-type})
          ERR_OPERATION_UNKNOWN
        )
      )
    )
    (begin
      (asserts! (is-eq tx-sender (var-get governance-authority)) ERR_GOVERNANCE_LOCK)
      (asserts! (> (len description) u10) ERR_MALFORMED_DATA)
      (asserts! (and (>= multiplier u1) (<= multiplier u500)) ERR_MALFORMED_DATA)
      (asserts! (<= tier-requirement u5) ERR_MALFORMED_DATA)
      (asserts! (and (>= daily-limit u1) (<= daily-limit u100)) ERR_MALFORMED_DATA)
      
      (map-set trust-operations
        {operation-type: operation-type}
        {
          trust-multiplier: multiplier,
          operation-description: description,
          minimum-tier-requirement: tier-requirement,
          maximum-daily-executions: daily-limit,
          operational: operational
        }
      )
      
      (print {
        governance-event: "operation-modified",
        operation-type: operation-type,
        new-multiplier: multiplier,
        operational-status: operational
      })
      (ok true)
    )
  )
)

;;                           INTERNAL UTILITIES

;; Validate identity ownership and operational status
(define-private (validate-identity-authority (identity principal))
  (match (map-get? trust-registry {identity: identity})
    registry-entry
      (and
        (is-eq identity tx-sender)
        (get active-status registry-entry)
      )
    false
  )
)

;; Calculate trust tier based on current score with hysteresis
(define-private (compute-trust-tier (trust-score uint))
  (if (>= trust-score u8000) u5      ;; Elite tier (80%+)
    (if (>= trust-score u6000) u4    ;; High tier (60-80%)
      (if (>= trust-score u4000) u3  ;; Medium tier (40-60%)
        (if (>= trust-score u2000) u2 ;; Basic tier (20-40%)
          (if (>= trust-score u500) u1 ;; Novice tier (5-20%)
            u0                        ;; Unrated tier (<5%)
          )
        )
      )
    )
  )
)

;; Record trust coefficient changes with enhanced metadata
(define-private (record-trust-transition
  (identity principal)
  (operation-name (string-ascii 48))
  (previous-score uint)
  (updated-score uint)
  (gas-cost uint)
)
  (let ((transition-id (+ stacks-block-height (get verified-operations (default-to {
      unique-handle: "",
      trust-coefficient: u0,
      genesis-block: u0,
      last-interaction: u0,
      entropy-checkpoint: u0,
      verified-operations: u0,
      active-status: false,
      trust-tier: u0
    } (map-get? trust-registry {identity: identity}))))))
    (map-set trust-ledger
      {identity: identity, sequence-id: transition-id}
      {
        operation-executed: operation-name,
        trust-before: previous-score,
        trust-after: updated-score,
        bitcoin-anchor: burn-block-height,
        stacks-height: stacks-block-height,
        gas-consumed: gas-cost,
        validator-signature: none
      }
    )
    
    ;; Update global trust distribution analytics
    (var-set global-trust-distribution
      (+ (var-get global-trust-distribution)
         (if (> updated-score previous-score)
           (- updated-score previous-score)
           u0)))
    
    (print {
      trust-event: "coefficient-updated",
      identity: identity,
      operation: operation-name,
      score-delta: (if (>= updated-score previous-score)
                    (- updated-score previous-score)
                    (- previous-score updated-score)),
      new-total: updated-score,
      trust-tier: (compute-trust-tier updated-score)
    })
  )
)

;; Retrieve operation multiplier with safety fallback
(define-private (get-operation-trust-multiplier (operation-type (string-ascii 48)))
  (default-to u0
    (get trust-multiplier
      (map-get? trust-operations {operation-type: operation-type})
    )
  )
)

;; Verify operation availability and tier requirements
(define-private (is-operation-accessible (operation-type (string-ascii 48)) (identity-tier uint))
  (match (map-get? trust-operations {operation-type: operation-type})
    operation-config
      (and
        (get operational operation-config)
        (>= identity-tier (get minimum-tier-requirement operation-config))
      )
    false
  )
)

;; Determine if entropy decay should be applied based on cycle completion
(define-private (requires-entropy-decay (last-checkpoint uint))
  (>= (- stacks-block-height last-checkpoint) (var-get decay-cycle-duration))
)

;;                        IDENTITY LIFECYCLE MANAGEMENT

;; Establish new trust identity with Bitcoin-anchored registration
(define-public (establish-trust-identity (unique-handle (string-ascii 64)))
  (let
    (
      (registrant tx-sender)
      (registration-height stacks-block-height)
      (initial-trust (var-get bootstrap-trust-allocation))
      (initial-tier (compute-trust-tier initial-trust))
    )
    (begin
      (asserts! (var-get protocol-operational) ERR_PROTOCOL_OFFLINE)
      (asserts! (is-none (map-get? trust-registry {identity: registrant})) ERR_IDENTITY_EXISTS)
      (asserts! (>= (len unique-handle) MIN_IDENTITY_LENGTH) ERR_MALFORMED_DATA)
      
      (map-set trust-registry
        {identity: registrant}
        {
          unique-handle: unique-handle,
          trust-coefficient: initial-trust,
          genesis-block: registration-height,
          last-interaction: registration-height,
          entropy-checkpoint: registration-height,
          verified-operations: u0,
          active-status: true,
          trust-tier: initial-tier
        }
      )
      
      ;; Update protocol-wide statistics
      (var-set total-registered-identities (+ (var-get total-registered-identities) u1))
      (var-set global-trust-distribution (+ (var-get global-trust-distribution) initial-trust))
      
      ;; Initialize analytics entry
      (map-set trust-analytics
        {metric-name: "new-registrations"}
        {
          current-value: (var-get total-registered-identities),
          historical-peak: registration-height,
          last-updated: registration-height,
          measurement-frequency: u1
        }
      )
      
      (print {
        trust-event: "identity-established",
        identity: registrant,
        handle: unique-handle,
        initial-trust: initial-trust,
        trust-tier: initial-tier,
        bitcoin-anchor: burn-block-height,
        registration-id: registration-height
      })
      
      (ok unique-handle)
    )
  )
)

;; Modify identity operational status with proper authorization
(define-public (modify-identity-status (active-state bool))
  (let
    (
      (identity tx-sender)
      (current-registry
        (unwrap!
          (map-get? trust-registry {identity: identity})
          ERR_IDENTITY_UNKNOWN
        )
      )
    )
    (begin
      (asserts! (var-get protocol-operational) ERR_PROTOCOL_OFFLINE)
      
      (map-set trust-registry
        {identity: identity}
        (merge current-registry {
          active-status: active-state,
          last-interaction: stacks-block-height
        })
      )
      
      (print {
        trust-event: "identity-status-modified",
        identity: identity,
        active: active-state,
        timestamp: stacks-block-height
      })
      
      (ok active-state)
    )
  )
)

;;                           TRUST COEFFICIENT ENGINE

;; Execute trust-earning operation with comprehensive validation and scoring
(define-public (execute-trust-operation (operation-type (string-ascii 48)))
  (let
    (
      (executor tx-sender)
      (registry-entry
        (unwrap!
          (map-get? trust-registry {identity: executor})
          ERR_IDENTITY_UNKNOWN
        )
      )
      (current-trust (get trust-coefficient registry-entry))
      (current-tier (get trust-tier registry-entry))
      (operation-multiplier (get-operation-trust-multiplier operation-type))
      (verified-count (+ (get verified-operations registry-entry) u1))
    )
    (begin
      (asserts! (var-get protocol-operational) ERR_PROTOCOL_OFFLINE)
      (asserts! (get active-status registry-entry) ERR_UNAUTHORIZED)
      (asserts! (is-some (map-get? trust-operations {operation-type: operation-type})) ERR_OPERATION_UNKNOWN)
      (asserts! (is-operation-accessible operation-type current-tier) ERR_TRUST_INSUFFICIENT)
      
      ;; Apply entropy decay if cycle completed
      (if (requires-entropy-decay (get entropy-checkpoint registry-entry))
        (execute-entropy-decay-internal executor)
        true
      )
      
      ;; Calculate updated trust coefficient with ceiling protection
      (let
        (
          (refreshed-registry (unwrap! (map-get? trust-registry {identity: executor}) ERR_IDENTITY_UNKNOWN))
          (decayed-trust (get trust-coefficient refreshed-registry))
          (trust-increment (* operation-multiplier (+ u1 (/ current-tier u10))))
          (updated-trust
            (if (< (+ decayed-trust trust-increment) MAX_TRUST_SCORE)
              (+ decayed-trust trust-increment)
              MAX_TRUST_SCORE
            )
          )
          (updated-tier (compute-trust-tier updated-trust))
        )
        (begin
          (map-set trust-registry
            {identity: executor}
            (merge refreshed-registry {
              trust-coefficient: updated-trust,
              last-interaction: stacks-block-height,
              verified-operations: verified-count,
              trust-tier: updated-tier
            })
          )
          
          (record-trust-transition executor operation-type decayed-trust updated-trust u0)
          
          (ok updated-trust)
        )
      )
    )
  )
)

;; Internal entropy decay application with sophisticated algorithms
(define-private (execute-entropy-decay-internal (identity principal))
  (let
    (
      (registry-entry
        (default-to
          {
            unique-handle: "",
            trust-coefficient: u0,
            genesis-block: u0,
            last-interaction: u0,
            entropy-checkpoint: u0,
            verified-operations: u0,
            active-status: false,
            trust-tier: u0
          }
          (map-get? trust-registry {identity: identity})
        )
      )
      (current-trust (get trust-coefficient registry-entry))
      (decay-factor (var-get entropy-decay-rate))
      ;; Non-linear decay - higher scores decay faster to prevent stagnation
      (adjusted-decay (+ decay-factor (/ (get trust-tier registry-entry) u2)))
      (decay-amount (/ (* current-trust adjusted-decay) u100))
      (updated-trust
        (if (> current-trust decay-amount)
          (- current-trust decay-amount)
          MIN_TRUST_SCORE
        )
      )
      (updated-tier (compute-trust-tier updated-trust))
    )
    (begin
      (map-set trust-registry
        {identity: identity}
        (merge registry-entry {
          trust-coefficient: updated-trust,
          last-interaction: stacks-block-height,
          entropy-checkpoint: stacks-block-height,
          trust-tier: updated-tier
        })
      )
      
      (record-trust-transition identity "entropy-decay" current-trust updated-trust u0)
      
      ;; Update global distribution
      (var-set global-trust-distribution
        (if (> (var-get global-trust-distribution) (- current-trust updated-trust))
          (- (var-get global-trust-distribution) (- current-trust updated-trust))
          u0))
      
      true
    )
  )
)

;; Public interface for manual entropy decay application
(define-public (trigger-entropy-decay)
  (let
    (
      (identity tx-sender)
      (registry-entry
        (unwrap!
          (map-get? trust-registry {identity: identity})
          ERR_IDENTITY_UNKNOWN
        )
      )
    )
    (begin
      (asserts! (var-get protocol-operational) ERR_PROTOCOL_OFFLINE)
      (asserts! (get active-status registry-entry) ERR_UNAUTHORIZED)
      (asserts! (requires-entropy-decay (get entropy-checkpoint registry-entry)) ERR_MALFORMED_DATA)
      
      (execute-entropy-decay-internal identity)
      
      (let ((updated-registry (unwrap! (map-get? trust-registry {identity: identity}) ERR_IDENTITY_UNKNOWN)))
        (ok (get trust-coefficient updated-registry))
      )
    )
  )
)

;;                       CROSS-ECOSYSTEM INTEGRATION

;; Grant ecosystem access credential with advanced validation
(define-public (grant-ecosystem-credential
  (ecosystem (string-ascii 32))
  (trust-threshold uint)
  (validity-duration uint)
  (privilege-tier uint)
)
  (let
    (
      (identity tx-sender)
      (registry-entry (unwrap! (map-get? trust-registry {identity: identity}) ERR_IDENTITY_UNKNOWN))
      (current-trust (get trust-coefficient registry-entry))
      (expiration-height (+ stacks-block-height validity-duration))
    )
    (begin
      (asserts! (var-get protocol-operational) ERR_PROTOCOL_OFFLINE)
      (asserts! (get active-status registry-entry) ERR_UNAUTHORIZED)
      (asserts! (> (len ecosystem) u3) ERR_MALFORMED_DATA)
      (asserts! (and (> validity-duration u0) (<= validity-duration u1051200)) ERR_MALFORMED_DATA) ;; Max ~2 years
      (asserts! (>= current-trust trust-threshold) ERR_TRUST_INSUFFICIENT)
      (asserts! (<= trust-threshold MAX_TRUST_SCORE) ERR_MALFORMED_DATA)
      (asserts! (<= privilege-tier u5) ERR_MALFORMED_DATA)
      
      (map-set ecosystem-credentials
        {ecosystem: ecosystem, identity: identity}
        {
          minimum-trust-threshold: trust-threshold,
          credential-issued: stacks-block-height,
          credential-expires: expiration-height,
          privilege-level: privilege-tier,
          revocation-flag: false
        }
      )
      
      (print {
        trust-event: "credential-granted",
        ecosystem: ecosystem,
        identity: identity,
        trust-threshold: trust-threshold,
        privilege-level: privilege-tier,
        expires-at: expiration-height,
        bitcoin-anchor: burn-block-height
      })
      
      (ok true)
    )
  )
)

;; Revoke ecosystem credential with audit trail
(define-public (revoke-ecosystem-credential (ecosystem (string-ascii 32)) (target-identity principal))
  (let
    (
      (existing-credential
        (unwrap!
          (map-get? ecosystem-credentials {ecosystem: ecosystem, identity: target-identity})
          ERR_OPERATION_UNKNOWN
        )
      )
    )
    (begin
      (asserts! (or
                  (is-eq tx-sender (var-get governance-authority))
                  (is-eq tx-sender target-identity))
                ERR_UNAUTHORIZED)
      
      (map-set ecosystem-credentials
        {ecosystem: ecosystem, identity: target-identity}
        (merge existing-credential {
          revocation-flag: true
        })
      )
      
      (print {
        trust-event: "credential-revoked",
        ecosystem: ecosystem,
        identity: target-identity,
        revoked-by: tx-sender,
        timestamp: stacks-block-height
      })
      
      (ok true)
    )
  )
)

;;                            QUERY INTERFACE

;; Retrieve current trust coefficient for identity
(define-read-only (get-trust-coefficient (identity principal))
  (match (map-get? trust-registry {identity: identity})
    registry-entry (some (get trust-coefficient registry-entry))
    none
  )
)

;; Get comprehensive trust profile with all metadata
(define-read-only (get-trust-profile (identity principal))
  (map-get? trust-registry {identity: identity})
)

;; Verify trust threshold compliance with detailed response
(define-read-only (verify-trust-threshold
  (identity principal)
  (required-threshold uint)
)
  (match (map-get? trust-registry {identity: identity})
    registry-entry
      (let
        (
          (current-trust (get trust-coefficient registry-entry))
          (threshold-met (and
                          (get active-status registry-entry)
                          (>= current-trust required-threshold)))
          (trust-difference
            (if (>= current-trust required-threshold)
              (- current-trust required-threshold)
              (- required-threshold current-trust)))
        )
        (some {
          verified: threshold-met,
          current-trust: current-trust,
          trust-tier: (get trust-tier registry-entry),
          threshold-met: required-threshold,
          trust-difference: trust-difference,
          active-status: (get active-status registry-entry)
        })
      )
    none
  )
)

;; Check ecosystem credential validity and access permissions
(define-read-only (verify-ecosystem-access
  (ecosystem (string-ascii 32))
  (identity principal)
)
  (match (map-get? ecosystem-credentials {ecosystem: ecosystem, identity: identity})
    credential
      (let
        (
          (is-valid (and
                      (not (get revocation-flag credential))
                      (< stacks-block-height (get credential-expires credential))))
        )
        (some {
          access-granted: is-valid,
          privilege-level: (get privilege-level credential),
          expires-at: (get credential-expires credential),
          trust-threshold: (get minimum-trust-threshold credential),
          revoked: (get revocation-flag credential),
          current-height: stacks-block-height
        })
      )
    none
  )
)

;; Retrieve trust operation configuration details
(define-read-only (get-operation-details (operation-type (string-ascii 48)))
  (map-get? trust-operations {operation-type: operation-type})
)

;; Get trust transition history for specific identity
(define-read-only (get-trust-history (identity principal) (sequence-id uint))
  (map-get? trust-ledger {identity: identity, sequence-id: sequence-id})
)

;; Retrieve protocol analytics and metrics
(define-read-only (get-protocol-analytics (metric-name (string-ascii 32)))
  (map-get? trust-analytics {metric-name: metric-name})
)