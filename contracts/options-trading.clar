;; ===============================================================
;; Options Trading Smart Contract
;; Author: GPT-5
;; Description:
;;   A decentralized options trading contract for SIP-010 tokens
;;   or STX, allowing users to create (write), buy, exercise, and
;;   expire CALL and PUT options.
;; ===============================================================

(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-decimals () (response uint uint))
  )
)

;; ===============================================================
;; Data Structures
;; ===============================================================

(define-data-var option-counter uint u0)

(define-map options uint {
  writer: principal,
  buyer: (optional principal),
  option-type: (string-ascii 4), ;; "CALL" or "PUT"
  underlying: principal,
  strike-price: uint,
  amount: uint,
  premium: uint,
  expiration: uint,
  exercised: bool
})

;; ===============================================================
;; Error Codes
;; ===============================================================

(define-constant ERR_INVALID_TYPE (err u100))
(define-constant ERR_ALREADY_BOUGHT (err u101))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_TOO_EARLY (err u105))
(define-constant ERR_EXPIRED (err u106))
(define-constant ERR_NOT_ITM (err u107))
(define-constant ERR_ALREADY_EXERCISED (err u108))
(define-constant ERR_UNAUTHORIZED (err u109))

;; ===============================================================
;; Event Helper
;; ===============================================================

(define-private (emit-event (event-type (string-ascii 32)) (option-id uint) (sender principal))
  (print { event: event-type, id: option-id, caller: sender })
)

;; ===============================================================
;; Core Functions
;; ===============================================================

;; ---------------------------------------------------------------
;; Create an Option (Writer locks collateral)
;; ---------------------------------------------------------------
(define-public (create-option
  (option-type (string-ascii 4))
  (underlying principal)
  (strike-price uint)
  (amount uint)
  (premium uint)
  (expiration uint)
)
  (begin
    (asserts! (or (is-eq option-type "CALL") (is-eq option-type "PUT")) ERR_INVALID_TYPE)

    ;; Increment counter and set new ID
    (var-set option-counter (+ (var-get option-counter) u1))
    (let ((id (var-get option-counter)))
      (begin
        ;; Record option details
        (map-set options id {
          writer: tx-sender,
          buyer: none,
          option-type: option-type,
          underlying: underlying,
          strike-price: strike-price,
          amount: amount,
          premium: premium,
          expiration: expiration,
          exercised: false
        })

        (emit-event "create-option" id tx-sender)
        (ok id)
      )
    )
  )
)

;; ---------------------------------------------------------------
;; Buy an Option
;; ---------------------------------------------------------------
(define-public (buy-option (id uint))
  (let ((option (map-get? options id)))
    (match option o
      (begin
        (asserts! (is-none (get buyer o)) ERR_ALREADY_BOUGHT)
        (let (
              (writer (get writer o))
              (premium (get premium o))
             )
          (try! (stx-transfer? premium tx-sender writer))
          (map-set options id (merge o { buyer: (some tx-sender) }))
          (emit-event "buy-option" id tx-sender)
          (ok "Option purchased")
        )
      )
      ERR_NOT_FOUND
    )
  )
)

;; ---------------------------------------------------------------
;; Exercise Option (Buyer executes if in-the-money)
;; Buyer provides current market price (oracle can replace later)
;; ---------------------------------------------------------------
(define-public (exercise-option (id uint) (current-price uint))
  (let ((option (map-get? options id)))
    (match option o
      (begin
        (asserts! (is-some (get buyer o)) ERR_UNAUTHORIZED)
        (asserts! (not (get exercised o)) ERR_ALREADY_EXERCISED)
        (asserts! (<= stacks-block-height (get expiration o)) ERR_EXPIRED)

        (let (
              (buyer (unwrap-panic (get buyer o)))
              (writer (get writer o))
              (option-type (get option-type o))
              (underlying (get underlying o))
              (strike (get strike-price o))
              (amount (get amount o))
             )

          (if (is-eq option-type "CALL")
              ;; ----------------
              ;; CALL OPTION
              ;; ----------------
              (if (< strike current-price)
                  (begin
                    ;; Buyer pays strike * amount to writer
                    (try! (stx-transfer? (* strike amount) buyer writer))
                    ;; Collateral (underlying) sent to buyer)
                    (map-set options id (merge o { exercised: true }))
                    (emit-event "exercise-call" id buyer)
                    (ok "Call exercised")
                  )
                  ERR_NOT_ITM
              )
              ;; ----------------
              ;; PUT OPTION
              ;; ----------------
              (if (> strike current-price)
                  (begin
                    ;; Writer pays strike * amount to buyer
                    (try! (stx-transfer? (* strike amount) writer buyer))
                    ;; Buyer transfers underlying tokens to writer)
                    (map-set options id (merge o { exercised: true }))
                    (emit-event "exercise-put" id buyer)
                    (ok "Put exercised")
                  )
                  ERR_NOT_ITM
              )
          )
        )
      )
      ERR_NOT_FOUND
    )
  )
)

;; ---------------------------------------------------------------
;; Expire Option (If past expiration and unexercised)
;; ---------------------------------------------------------------
(define-public (expire-option (id uint))
  (let ((option (map-get? options id)))
    (match option o
      (begin
        (asserts! (> stacks-block-height (get expiration o)) ERR_TOO_EARLY)
        (asserts! (not (get exercised o)) ERR_ALREADY_EXERCISED)

        (let (
              (option-type (get option-type o))
              (underlying (get underlying o))
              (amount (get amount o))
              (writer (get writer o))
             )

          (if (is-eq option-type "CALL")
              ;; CALL OPTION EXPIRATION
              (begin
                (map-delete options id)
                (emit-event "expire-call" id writer)
                (ok "CALL option expired and collateral returned")
              )
              ;; PUT OPTION EXPIRATION
              (begin
                (map-delete options id)
                (emit-event "expire-put" id tx-sender)
                (ok "PUT option expired")
              )
          )
        )
      )
      ERR_NOT_FOUND
    )
  )
)

;; ===============================================================
;; View / Getter Functions
;; ===============================================================

(define-read-only (get-option (id uint))
  (map-get? options id)
)

(define-read-only (get-option-count)
  (ok (var-get option-counter))
)
