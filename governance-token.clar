;; ------------------------------------------------------
;; Governance Token — SIP-010 Implementation
;; ------------------------------------------------------

(use-trait sip10-trait .sip_010_trait)
(impl-trait sip10-trait)

(define-data-var total-supply uint u0)
(define-map balances { account: principal } { balance: uint })

;; Internal helper
(define-read-only (get-balance-internal (who principal))
  (get balance (default-to { balance: u0 } (map-get? balances { account: who })))
)

;; --- SIP-010 Read-onlys ---
(define-read-only (get-balance (owner principal))
  (ok (get-balance-internal owner))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-decimals) (ok u6))
(define-read-only (get-symbol) (ok "GOV"))
(define-read-only (get-name) (ok "Governance Token"))

(define-read-only (get-allowance (owner principal) (spender principal))
  (ok u0)
)

(define-public (approve (spender principal) (amount uint))
  (ok true)
)

;; --- SIP-010 Mutable Ops ---
(define-public (mint (amount uint) (recipient principal))
  (begin
    (var-set total-supply (+ (var-get total-supply) amount))
    (map-set balances { account: recipient }
      { balance: (+ (get-balance-internal recipient) amount) })
    (ok true)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (let ((sender-bal (get-balance-internal sender)))
    (if (< sender-bal amount)
        (err u1) ;; insufficient balance
        (begin
          (map-set balances { account: sender } { balance: (- sender-bal amount) })
          (map-set balances { account: recipient }
            { balance: (+ (get-balance-internal recipient) amount) })
          (ok true)
        )
    )
  )
)
