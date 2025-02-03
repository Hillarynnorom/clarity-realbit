;; Property Registry Contract

;; Define NFT
(define-non-fungible-token property uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-property-exists (err u101))

;; Data vars
(define-map property-details uint 
  {
    name: (string-utf8 100),
    location: (string-utf8 200),
    value: uint,
    shares: uint,
    share-contract: principal
  }
)

(define-data-var property-count uint u0)

;; Register new property
(define-public (register-property 
  (name (string-utf8 100))
  (location (string-utf8 200))
  (value uint)
  (total-shares uint)
  (share-contract principal))
  (let ((property-id (+ (var-get property-count) u1)))
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (try! (nft-mint? property property-id tx-sender))
    (map-set property-details property-id
      {
        name: name,
        location: location,
        value: value,
        shares: total-shares,
        share-contract: share-contract
      })
    (var-set property-count property-id)
    (ok property-id)))
