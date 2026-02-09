(export db-queue-test)

(import
  :std/misc/number
  :std/sugar :std/test
  :clan/concurrency :clan/path-config
  ../db ../db-queue)

(def db-queue-test
  (test-suite "test suite for persist/db-queue"
    (test-case "DbQueue? predicate"
      (with-db-connection (c "test-queue-db-pred")
        (def qkey (string->bytes "test-q-pred"))
        (def q (DbQueue-restore 'test-q-pred qkey (lambda (msg tx) (void))))
        (check (DbQueue? q) => #t)
        (check (DbQueue? 42) => #f)))

    (test-case "DbQueue send does not error"
      (with-db-connection (c "test-queue-db-send")
        (def qkey (string->bytes "test-q-send"))
        (def q (DbQueue-restore 'test-q-send qkey (lambda (msg tx) (void))))
        ;; Send a message — should not raise an error
        (with-committed-tx (tx)
          (DbQueue-send! q (string->bytes "hello") tx))
        ;; Send multiple messages in one tx
        (with-committed-tx (tx)
          (DbQueue-send! q (string->bytes "a") tx)
          (DbQueue-send! q (string->bytes "b") tx))
        (check #t => #t))) ;; if we get here, no errors

    (test-case "DbQueue restore is idempotent"
      (with-db-connection (c "test-queue-db-idem")
        (def qkey (string->bytes "test-q-idem"))
        ;; Restore twice on the same key — should not error
        (def q1 (DbQueue-restore 'test-q-idem1 qkey (lambda (msg tx) (void))))
        (check (DbQueue? q1) => #t)
        (with-committed-tx (tx)
          (DbQueue-send! q1 (string->bytes "persisted") tx))
        ;; Restoring again from same key should work
        (def q2 (DbQueue-restore 'test-q-idem2 qkey (lambda (msg tx) (void))))
        (check (DbQueue? q2) => #t)))))
