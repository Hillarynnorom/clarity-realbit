;; Market Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-listing-not-active (err u104))
(define-constant err-insufficient-funds (err u105))

;; Listing details
(define-map share-listings uint 
  {
    seller: principal,
    token-contract: principal,
    price: uint,
    amount: uint,
    active: bool
  }
)

(define-data-var listing-nonce uint u0)

;; Helper functions
(define-private (validate-listing-params (price uint) (amount uint))
  (begin
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> amount u0) err-invalid-amount)
    (ok true)))

;; Create listing
(define-public (create-listing 
  (token-contract principal)
  (amount uint)
  (price uint))
  (let ((listing-id (+ (var-get listing-nonce) u1)))
    (try! (validate-listing-params price amount))
    (try! (contract-call? token-contract transfer-shares amount (as-contract tx-sender)))
    (map-set share-listings listing-id
      {
        seller: tx-sender,
        token-contract: token-contract,
        price: price,
        amount: amount,
        active: true
      })
    (var-set listing-nonce listing-id)
    (ok listing-id)))

;; Cancel listing
(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? share-listings listing-id) err-listing-not-found)))
    (asserts! (is-eq (get seller listing) tx-sender) err-not-authorized)
    (asserts! (get active listing) err-listing-not-active)
    (try! (contract-call? (get token-contract listing) transfer-shares 
      (get amount listing) 
      (get seller listing)))
    (map-set share-listings listing-id
      (merge listing { active: false }))
    (ok true)))

;; Purchase shares
(define-public (purchase-shares (listing-id uint))
  (let ((listing (unwrap! (map-get? share-listings listing-id) err-listing-not-found)))
    (asserts! (get active listing) err-listing-not-active)
    (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
    (try! (contract-call? (get token-contract listing) transfer-shares
      (get amount listing)
      tx-sender))
    (map-set share-listings listing-id
      (merge listing { active: false }))
    (ok true)))
