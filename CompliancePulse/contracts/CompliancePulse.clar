;; Compliance Monitoring and Reporting Oracle Smart Contract
;; This contract manages compliance data from external oracles, monitors regulatory requirements,
;; and generates compliance reports for tracked entities. It includes access control, data validation,
;; automated compliance status updates, escalation procedures, and comprehensive audit trails.

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-ORACLE (err u101))
(define-constant ERR-INVALID-DATA (err u102))
(define-constant ERR-ENTITY-NOT-FOUND (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-TIMEFRAME (err u106))
(define-constant ERR-ESCALATION-PENDING (err u107))
(define-constant MIN-COMPLIANCE-SCORE u70)
(define-constant CRITICAL-COMPLIANCE-THRESHOLD u40)
(define-constant MAX-ORACLES u10)
(define-constant ESCALATION-DELAY u144) ;; ~24 hours in blocks
(define-constant AUDIT-RETENTION-PERIOD u4320) ;; ~30 days in blocks

;; data maps and vars
(define-map authorized-oracles 
  principal 
  {
    active: bool,
    reputation-score: uint,
    total-reports: uint,
    last-activity: uint
  })

(define-map compliance-entities 
  principal 
  {
    name: (string-ascii 50),
    compliance-score: uint,
    last-updated: uint,
    status: (string-ascii 20),
    violations: uint,
    risk-category: (string-ascii 15),
    next-audit-due: uint,
    escalation-level: uint
  })

(define-map compliance-reports
  {entity: principal, report-id: uint}
  {
    oracle: principal,
    timestamp: uint,
    data-hash: (buff 32),
    compliance-metrics: (list 5 uint),
    notes: (string-ascii 200),
    severity: (string-ascii 10),
    validated: bool
  })

(define-map audit-trails
  {entity: principal, audit-id: uint}
  {
    auditor: principal,
    audit-type: (string-ascii 20),
    findings: (list 10 uint),
    recommendations: (string-ascii 300),
    follow-up-required: bool,
    audit-timestamp: uint
  })

(define-map escalation-queue
  {entity: principal, escalation-id: uint}
  {
    violation-type: (string-ascii 30),
    severity: uint,
    created-at: uint,
    status: (string-ascii 20),
    assigned-to: (optional principal),
    resolution-notes: (optional (string-ascii 200))
  })

(define-data-var next-report-id uint u1)
(define-data-var next-audit-id uint u1)
(define-data-var next-escalation-id uint u1)
(define-data-var total-entities uint u0)
(define-data-var oracle-count uint u0)
(define-data-var contract-paused bool false)

;; private functions
(define-private (is-authorized-oracle (oracle principal))
  (match (map-get? authorized-oracles oracle)
    oracle-data (get active oracle-data)
    false))

(define-private (calculate-compliance-score (metrics (list 5 uint)))
  (let ((sum (fold + metrics u0)))
    (/ sum (len metrics))))

(define-private (update-entity-status (entity principal) (score uint))
  (if (>= score MIN-COMPLIANCE-SCORE)
    "COMPLIANT"
    (if (>= score CRITICAL-COMPLIANCE-THRESHOLD)
      "NON-COMPLIANT"
      "CRITICAL")))

(define-private (determine-risk-category (score uint) (violations uint))
  (if (< score CRITICAL-COMPLIANCE-THRESHOLD)
    "HIGH"
    (if (and (< score MIN-COMPLIANCE-SCORE) (> violations u3))
      "MEDIUM"
      "LOW")))

(define-private (increment-violations (entity principal))
  (match (map-get? compliance-entities entity)
    existing-entity 
      (map-set compliance-entities entity 
        (merge existing-entity {violations: (+ (get violations existing-entity) u1)}))
    false))

(define-private (update-oracle-reputation (oracle principal) (positive bool))
  (match (map-get? authorized-oracles oracle)
    oracle-data
      (let ((current-score (get reputation-score oracle-data))
            (new-score (if positive (+ current-score u5) (- current-score u2))))
        (map-set authorized-oracles oracle
          (merge oracle-data {
            reputation-score: new-score,
            total-reports: (+ (get total-reports oracle-data) u1),
            last-activity: block-height
          })))
    false))

(define-private (create-escalation (entity principal) (violation-type (string-ascii 30)) (severity uint))
  (let ((escalation-id (var-get next-escalation-id)))
    (map-set escalation-queue
      {entity: entity, escalation-id: escalation-id}
      {
        violation-type: violation-type,
        severity: severity,
        created-at: block-height,
        status: "PENDING",
        assigned-to: none,
        resolution-notes: none
      })
    (var-set next-escalation-id (+ escalation-id u1))
    escalation-id))

(define-private (determine-compliance-trend (current-score uint) (average-score uint))
  (if (> current-score (+ average-score u10))
    "IMPROVING"
    (if (< current-score (- average-score u10))
      "DECLINING"
      "STABLE")))

(define-private (analyze-regulatory-compliance-patterns (entities (list 50 principal)) (framework (string-ascii 30)))
  {
    framework-compliance: u0,
    pattern-analysis: "STANDARD",
    recommendations: (list "MAINTAIN_CURRENT_MONITORING" "SCHEDULE_REGULAR_AUDITS")
  })

(define-private (calculate-overall-confidence-score (risk-matrix {high-risk-entities: uint, medium-risk-entities: uint, low-risk-entities: uint, total-violations: uint, average-compliance-score: uint, compliance-trend: (string-ascii 10)}) (predictive-analysis {entities-at-risk: (list 20 principal), predicted-violations: uint, recommended-interventions: (list 10 (string-ascii 50)), confidence-score: uint}))
  (let (
    (data-quality-score (if (> (+ (get high-risk-entities risk-matrix) (get medium-risk-entities risk-matrix) (get low-risk-entities risk-matrix)) u5) u80 u60))
    (prediction-confidence (get confidence-score predictive-analysis))
  )
    (/ (+ data-quality-score prediction-confidence) u2)))

(define-private (calculate-prediction-confidence (entity-data {name: (string-ascii 50), compliance-score: uint, last-updated: uint, status: (string-ascii 20), violations: uint, risk-category: (string-ascii 15), next-audit-due: uint, escalation-level: uint}))
  (let (
    (data-freshness (if (< (- block-height (get last-updated entity-data)) u144) u90 u60))
    (historical-consistency (if (< (get violations entity-data) u3) u80 u50))
  )
    (/ (+ data-freshness historical-consistency) u2)))

(define-private (schedule-priority-audit (entity principal))
  (match (map-get? compliance-entities entity)
    entity-data
      (map-set compliance-entities entity
        (merge entity-data {next-audit-due: (+ block-height u72)})) ;; Schedule audit in ~12 hours
    false))

(define-private (analyze-entity-risk-profile (entity principal) (acc {high-risk-entities: uint, medium-risk-entities: uint, low-risk-entities: uint, total-violations: uint, average-compliance-score: uint, compliance-trend: (string-ascii 10)}))
  (match (map-get? compliance-entities entity)
    entity-data
      (let (
        (risk-category (get risk-category entity-data))
        (compliance-score (get compliance-score entity-data))
        (violations (get violations entity-data))
      )
        {
          high-risk-entities: (if (is-eq risk-category "HIGH") (+ (get high-risk-entities acc) u1) (get high-risk-entities acc)),
          medium-risk-entities: (if (is-eq risk-category "MEDIUM") (+ (get medium-risk-entities acc) u1) (get medium-risk-entities acc)),
          low-risk-entities: (if (is-eq risk-category "LOW") (+ (get low-risk-entities acc) u1) (get low-risk-entities acc)),
          total-violations: (+ (get total-violations acc) violations),
          average-compliance-score: (/ (+ (get average-compliance-score acc) compliance-score) u2),
          compliance-trend: (determine-compliance-trend compliance-score (get average-compliance-score acc))
        })
    acc))

(define-private (calculate-risk-predictions (entity principal) (acc {entities-at-risk: (list 20 principal), predicted-violations: uint, recommended-interventions: (list 10 (string-ascii 50)), confidence-score: uint}))
  (match (map-get? compliance-entities entity)
    entity-data
      (let (
        (risk-score (calculate-predictive-risk-score entity-data))
        (intervention-needed (> risk-score u75))
      )
        {
          entities-at-risk: (if intervention-needed (unwrap-panic (as-max-len? (append (get entities-at-risk acc) entity) u20)) (get entities-at-risk acc)),
          predicted-violations: (+ (get predicted-violations acc) (if (> risk-score u80) u1 u0)),
          recommended-interventions: (if intervention-needed 
            (unwrap-panic (as-max-len? (append (get recommended-interventions acc) "IMMEDIATE_AUDIT_REQUIRED") u10))
            (get recommended-interventions acc)),
          confidence-score: (+ (get confidence-score acc) (calculate-prediction-confidence entity-data))
        })
    acc))

(define-private (calculate-predictive-risk-score (entity-data {name: (string-ascii 50), compliance-score: uint, last-updated: uint, status: (string-ascii 20), violations: uint, risk-category: (string-ascii 15), next-audit-due: uint, escalation-level: uint}))
  (let (
    (score-factor (* (- u100 (get compliance-score entity-data)) u1))
    (violation-factor (* (get violations entity-data) u15))
    (time-factor (if (> (- block-height (get last-updated entity-data)) u720) u20 u0))
    (escalation-factor (* (get escalation-level entity-data) u10))
  )
    (+ score-factor violation-factor time-factor escalation-factor)))

;; public functions
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)))

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)))

(define-public (add-oracle (oracle principal) (initial-reputation uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (< (var-get oracle-count) MAX-ORACLES) ERR-INVALID-ORACLE)
    (asserts! (not (is-authorized-oracle oracle)) ERR-ALREADY-EXISTS)
    (map-set authorized-oracles oracle {
      active: true,
      reputation-score: initial-reputation,
      total-reports: u0,
      last-activity: block-height
    })
    (var-set oracle-count (+ (var-get oracle-count) u1))
    (ok true)))

(define-public (deactivate-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-authorized-oracle oracle) ERR-INVALID-ORACLE)
    (match (map-get? authorized-oracles oracle)
      oracle-data
        (map-set authorized-oracles oracle (merge oracle-data {active: false}))
      false)
    (var-set oracle-count (- (var-get oracle-count) u1))
    (ok true)))

(define-public (register-entity (entity principal) (name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    (asserts! (is-none (map-get? compliance-entities entity)) ERR-ALREADY-EXISTS)
    (map-set compliance-entities entity {
      name: name,
      compliance-score: u0,
      last-updated: block-height,
      status: "PENDING",
      violations: u0,
      risk-category: "UNKNOWN",
      next-audit-due: (+ block-height u1440), ;; ~10 days
      escalation-level: u0
    })
    (var-set total-entities (+ (var-get total-entities) u1))
    (ok true)))

(define-public (submit-compliance-data 
  (entity principal) 
  (data-hash (buff 32)) 
  (metrics (list 5 uint))
  (notes (string-ascii 200))
  (severity (string-ascii 10)))
  (let (
    (report-id (var-get next-report-id))
    (compliance-score (calculate-compliance-score metrics))
    (new-status (update-entity-status entity compliance-score))
  )
    (asserts! (is-authorized-oracle tx-sender) ERR-UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? compliance-entities entity)) ERR-ENTITY-NOT-FOUND)
    (asserts! (> (len metrics) u0) ERR-INVALID-DATA)
    
    ;; Store compliance report
    (map-set compliance-reports 
      {entity: entity, report-id: report-id}
      {
        oracle: tx-sender,
        timestamp: block-height,
        data-hash: data-hash,
        compliance-metrics: metrics,
        notes: notes,
        severity: severity,
        validated: false
      })
    
    ;; Update entity compliance data
    (match (map-get? compliance-entities entity)
      existing-entity
        (begin
          (let ((new-risk-category (determine-risk-category compliance-score (get violations existing-entity))))
            (map-set compliance-entities entity 
              (merge existing-entity {
                compliance-score: compliance-score,
                last-updated: block-height,
                status: new-status,
                risk-category: new-risk-category,
                next-audit-due: (+ block-height u1440)
              }))
            ;; Create escalation if critical
            (if (is-eq new-status "CRITICAL")
              (begin
                (create-escalation entity "CRITICAL_COMPLIANCE_FAILURE" u10)
                true)
              true)
            ;; Increment violations if non-compliant
            (if (or (is-eq new-status "NON-COMPLIANT") (is-eq new-status "CRITICAL"))
              (increment-violations entity)
              true)))
      false)
    
    ;; Update oracle reputation
    (update-oracle-reputation tx-sender true)
    (var-set next-report-id (+ report-id u1))
    (ok report-id)))

(define-public (validate-report (entity principal) (report-id uint) (valid bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (match (map-get? compliance-reports {entity: entity, report-id: report-id})
      report-data
        (begin
          (map-set compliance-reports {entity: entity, report-id: report-id}
            (merge report-data {validated: valid}))
          ;; Update oracle reputation based on validation
          (update-oracle-reputation (get oracle report-data) valid)
          (ok true))
      ERR-INVALID-DATA)))

(define-public (conduct-entity-audit 
  (entity principal) 
  (audit-type (string-ascii 20))
  (findings (list 10 uint))
  (recommendations (string-ascii 300)))
  (let ((audit-id (var-get next-audit-id)))
    (asserts! (is-authorized-oracle tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? compliance-entities entity)) ERR-ENTITY-NOT-FOUND)
    
    (map-set audit-trails
      {entity: entity, audit-id: audit-id}
      {
        auditor: tx-sender,
        audit-type: audit-type,
        findings: findings,
        recommendations: recommendations,
        follow-up-required: (> (fold + findings u0) u50),
        audit-timestamp: block-height
      })
    
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)))


