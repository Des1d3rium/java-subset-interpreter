#lang racket

(require json rackunit racket/runtime-path racket/sandbox "../interpreter.rkt")

(define-runtime-path cases-path "cases.json")
(define-runtime-path scope-example "../test.java")
(define cases (call-with-input-file cases-path read-json))

(define (run-source source)
  (define path (make-temporary-file "interpreter-test-~a.java"))
  (dynamic-wind
    (lambda () (display-to-file source path #:exists 'truncate))
    (lambda () (call-with-limits 3 #f (lambda () (interpret path))))
    (lambda () (delete-file path))))

(module+ test
  (test-case "original lexical scope example"
    (check-equal? (interpret scope-example) 115))
  (for ([entry (in-list cases)])
    (test-case (format "~a: ~a" (hash-ref entry 'category) (hash-ref entry 'name))
      (if (hash-has-key? entry 'error)
          (check-exn (pregexp (hash-ref entry 'error))
                     (lambda () (run-source (hash-ref entry 'source))))
          (let ([expected (hash-ref entry 'expected)])
            (check-equal? (run-source (hash-ref entry 'source))
                          (if (string? expected) (string->symbol expected) expected))))))
  ;; Run again after all malformed inputs and runtime failures: parser/interpreter
  ;; state must not contaminate the next program in this process.
  (test-case "recovery after failed programs"
    (check-equal? (interpret scope-example) 115)))
