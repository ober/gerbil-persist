(export content-addressing-test)

(import
  :std/sugar :std/test :std/text/hex
  ../content-addressing)

(def content-addressing-test
  (test-suite "test suite for persist/content-addressing"
    (test-case "digest<-file"
      (check-equal? (hex-encode (digest<-file "/dev/null")) "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"))

    (test-case "digest<-bytes empty"
      ;; Keccak-256 of empty bytes should match the /dev/null digest
      (check-equal? (hex-encode (digest<-bytes #u8()))
                    "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"))

    (test-case "digest<-string consistency"
      ;; digest<-string s should equal digest<-bytes of (string->bytes s)
      (def s "Hello, World!")
      (check-equal? (digest<-string s) (digest<-bytes (string->bytes s))))

    (test-case "digest determinism"
      ;; Same input always produces same output
      (def data (string->bytes "test data"))
      (check-equal? (digest<-bytes data) (digest<-bytes data)))

    (test-case "digest collision resistance"
      ;; Different inputs produce different digests
      (check (equal? (digest<-bytes #u8(1)) (digest<-bytes #u8(2))) => #f))

    (test-case "content-addressing-key includes prefix"
      ;; The content-addressing key should be the prefix + digest
      (def d (digest<-bytes #u8(42)))
      (def k (content-addressing-key d))
      (def prefix (ContentAddressing-key-prefix (current-content-addressing)))
      (check-equal? (subu8vector k 0 (u8vector-length prefix)) prefix)
      (check-equal? (subu8vector k (u8vector-length prefix) (u8vector-length k)) d))

    (test-case "keccak-addressing is default"
      (check (eq? (current-content-addressing) keccak-addressing) => #t))))
