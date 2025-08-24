(define-trait sip10-trait
  (
    ;; Transfers
    (transfer (uint principal principal) (response bool uint))
    (approve (principal uint) (response bool uint))

    ;; Read-only views
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-decimals () (response uint uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-name () (response (string-ascii 32) uint))
    (get-allowance (principal principal) (response uint uint))
  )
)
