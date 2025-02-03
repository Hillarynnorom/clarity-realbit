;; Share Token Contract

;; Define token
(define-fungible-token property-share)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-insufficient-balance (err u101))

;; Property share details
(define-data-var property-id uint u0)
(define-data-var total-shares uint u0)
(define-data-var share-price uint u0)

;; Initialize property shares
(define-public (initialize-shares (id uint) (shares uint) (price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (var-set property-id id)
    (var-set total-shares shares)
    (var-set share-price price)
    (try! (ft-mint? property-share shares contract-owner))
    (ok true)))

;; Transfer shares
(define-public (transfer-shares (amount uint) (recipient principal))
  (ft-transfer? property-share amount tx-sender recipient))
