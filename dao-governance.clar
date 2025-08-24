;; ---------------------------
;; DAO Governance Contract
;; ---------------------------

;; Import the SIP-010 trait
(use-trait sip10-trait .sip10-trait)

(define-constant GOVERNANCE-TOKEN .governance-token)

;; Proposal counter
(define-data-var proposal-counter uint u0)

;; Proposal storage
(define-map proposals
  { id: uint }
  {
    proposer: principal,
    description: (string-utf8 200),
    votes-for: uint,
    votes-against: uint,
    executed: bool
  }
)

;; Track who has voted
(define-map has-voted
  { id: uint, voter: principal }
  { voted: bool }
)

;; --- Error codes ---
(define-constant ERR-ALREADY-VOTED     (err u200))
(define-constant ERR-NO-PROPOSAL       (err u201))
(define-constant ERR-ALREADY-EXECUTED  (err u202))
(define-constant ERR-NO-BALANCE        (err u300))

;; --- Create a new proposal ---
(define-public (create-proposal (description (string-utf8 200)))
  (let ((id (+ (var-get proposal-counter) u1)))
    (begin
      (var-set proposal-counter id)
      (map-set proposals { id: id }
        {
          proposer: tx-sender,
          description: description,
          votes-for: u0,
          votes-against: u0,
          executed: false
        })
      (ok id)
    )
  )
)

;; --- Vote FOR ---
(define-public (vote-for (id uint))
  (let ((maybe (map-get? proposals { id: id })))
    (match maybe
      proposal
        (let ((already (get voted (default-to { voted: false }
                                  (map-get? has-voted { id: id, voter: tx-sender })))))
          (if already
              ERR-ALREADY-VOTED
              (let ((power (unwrap! (contract-call? GOVERNANCE-TOKEN get-balance tx-sender)
                                    ERR-NO-BALANCE)))
                (map-set proposals { id: id }
                  {
                    proposer: (get proposer proposal),
                    description: (get description proposal),
                    votes-for: (+ (get votes-for proposal) power),
                    votes-against: (get votes-against proposal),
                    executed: (get executed proposal)
                  })
                (map-set has-voted { id: id, voter: tx-sender } { voted: true })
                (ok true)
              )
          )
        )
      ERR-NO-PROPOSAL
    )
  )
)

;; --- Vote AGAINST ---
(define-public (vote-against (id uint))
  (let ((maybe (map-get? proposals { id: id })))
    (match maybe
      proposal
        (let ((already (get voted (default-to { voted: false }
                                  (map-get? has-voted { id: id, voter: tx-sender })))))
          (if already
              ERR-ALREADY-VOTED
              (let ((power (unwrap! (contract-call? GOVERNANCE-TOKEN get-balance tx-sender)
                                    ERR-NO-BALANCE)))
                (map-set proposals { id: id }
                  {
                    proposer: (get proposer proposal),
                    description: (get description proposal),
                    votes-for: (get votes-for proposal),
                    votes-against: (+ (get votes-against proposal) power),
                    executed: (get executed proposal)
                  })
                (map-set has-voted { id: id, voter: tx-sender } { voted: true })
                (ok true)
              )
          )
        )
      ERR-NO-PROPOSAL
    )
  )
)

;; --- Execute proposal ---
(define-public (execute (id uint))
  (let ((maybe (map-get? proposals { id: id })))
    (match maybe
      proposal
        (if (get executed proposal)
            ERR-ALREADY-EXECUTED
            (if (> (get votes-for proposal) (get votes-against proposal))
                (begin
                  (map-set proposals { id: id }
                    {
                      proposer: (get proposer proposal),
                      description: (get description proposal),
                      votes-for: (get votes-for proposal),
                      votes-against: (get votes-against proposal),
                      executed: true
                    })
                  (ok "passed: would trigger actions here")
                )
                (ok "failed")
            )
        )
      ERR-NO-PROPOSAL
    )
  )
)

;; --- Read-only helpers ---
(define-read-only (get-proposal (id uint))
  (ok (map-get? proposals { id: id }))
)

(define-read-only (get-has-voted (id uint) (voter principal))
  (ok (map-get? has-voted { id: id, voter: voter }))
)

(define-read-only (get-proposal-count)
  (ok (var-get proposal-counter))
)
