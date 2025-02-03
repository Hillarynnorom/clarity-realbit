;; Market Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))

;; Listing details
(define-map share-listings uint 
  {
    seller: principal,
    token-contract: principal,
    price: uint,
    amount: uint
  }
)

(define-data-var listing-nonce uint u0)

;; Create listing
(define-public (create-listing 
  (token-contract principal)
  (amount uint)
  (price uint))
  (let ((listing-id (+ (var-get listing-nonce) u1)))
    (map-set share-listings listing-id
      {
        seller: tx-sender,
        token-contract: token-contract,
        price: price,
        amount: amount
      })
    (var-set listing-nonce listing-id)
    (ok listing-id)))
