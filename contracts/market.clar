;; Market Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-listing-not-active (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-expired-listing (err u106))

;; Listing details
(define-map share-listings uint 
  {
    seller: principal,
    token-contract: principal,
    price: uint,
    amount: uint,
    remaining: uint,
    active: bool,
    expiry: uint,
    created-at: uint
  }
)

(define-data-var listing-nonce uint u0)

;; Events
(define-data-var last-event-id uint u0)
(define-map events uint 
  {
    event-type: (string-utf8 20),
    listing-id: uint,
    user: principal,
    amount: uint,
    price: uint,
    timestamp: uint
  }
)

;; Helper functions
(define-private (validate-listing-params (price uint) (amount uint))
  (begin
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> amount u0) err-invalid-amount)
    (ok true)))

(define-private (record-event (event-type (string-utf8 20)) (listing-id uint) (amount uint) (price uint))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (map-set events event-id
      {
        event-type: event-type,
        listing-id: listing-id,
        user: tx-sender,
        amount: amount,
        price: price,
        timestamp: block-height
      })
    (var-set last-event-id event-id)
    (ok event-id)))

;; Create listing
(define-public (create-listing 
  (token-contract principal)
  (amount uint)
  (price uint)
  (expiry uint))
  (let ((listing-id (+ (var-get listing-nonce) u1)))
    (try! (validate-listing-params price amount))
    (asserts! (>= expiry block-height) err-expired-listing)
    (try! (contract-call? token-contract transfer-shares amount (as-contract tx-sender)))
    (map-set share-listings listing-id
      {
        seller: tx-sender,
        token-contract: token-contract,
        price: price,
        amount: amount,
        remaining: amount,
        active: true,
        expiry: expiry,
        created-at: block-height
      })
    (var-set listing-nonce listing-id)
    (try! (record-event "listing-created" listing-id amount price))
    (ok listing-id)))

;; Update listing price
(define-public (update-listing-price (listing-id uint) (new-price uint))
  (let ((listing (unwrap! (map-get? share-listings listing-id) err-listing-not-found)))
    (asserts! (is-eq (get seller listing) tx-sender) err-not-authorized)
    (asserts! (get active listing) err-listing-not-active)
    (asserts! (> new-price u0) err-invalid-price)
    (map-set share-listings listing-id
      (merge listing { price: new-price }))
    (try! (record-event "price-updated" listing-id (get remaining listing) new-price))
    (ok true)))

;; Cancel listing
(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? share-listings listing-id) err-listing-not-found)))
    (asserts! (is-eq (get seller listing) tx-sender) err-not-authorized)
    (asserts! (get active listing) err-listing-not-active)
    (try! (contract-call? (get token-contract listing) transfer-shares 
      (get remaining listing) 
      (get seller listing)))
    (map-set share-listings listing-id
      (merge listing { active: false }))
    (try! (record-event "listing-cancelled" listing-id (get remaining listing) (get price listing)))
    (ok true)))

;; Purchase shares
(define-public (purchase-shares (listing-id uint) (amount uint))
  (let ((listing (unwrap! (map-get? share-listings listing-id) err-listing-not-found)))
    (asserts! (get active listing) err-listing-not-active)
    (asserts! (<= block-height (get expiry listing)) err-expired-listing)
    (asserts! (<= amount (get remaining listing)) err-invalid-amount)
    (let ((total-price (* amount (get price listing))))
      (try! (stx-transfer? total-price tx-sender (get seller listing)))
      (try! (contract-call? (get token-contract listing) transfer-shares
        amount
        tx-sender))
      (let ((new-remaining (- (get remaining listing) amount)))
        (map-set share-listings listing-id
          (merge listing { 
            remaining: new-remaining,
            active: (> new-remaining u0)
          }))
        (try! (record-event "shares-purchased" listing-id amount (get price listing)))
        (ok true)))))
