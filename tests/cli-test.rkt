#lang racket

(require rackunit racket/runtime-path racket/system)

(define-runtime-path interpreter "../interpreter.rkt")
(define-runtime-path scope "../test.java")
(define racket-executable (find-executable-path "racket"))

(define (run . arguments)
  (define output (open-output-string))
  (define errors (open-output-string))
  (define status
    (parameterize ([current-output-port output] [current-error-port errors]
                   [current-directory (find-system-path 'temp-dir)])
      (apply system*/exit-code racket-executable arguments)))
  (list status (get-output-string output) (get-output-string errors)))

(module+ test
  (test-case "default example resolves outside the repository directory"
    (check-equal? (run (path->string interpreter)) '(0 "115\n" "")))
  (test-case "explicit input path"
    (check-equal? (run (path->string interpreter) (path->string scope)) '(0 "115\n" "")))
  (test-case "missing input reports an error on stderr with nonzero status"
    (match-define (list status output errors)
      (run (path->string interpreter) "missing-interpreter-fixture.java"))
    (check-true (and (= status 1) (equal? output "") (regexp-match? #rx"cannot open" errors))))
  (test-case "extra arguments produce usage and exit 2"
    (match-define (list status output errors) (run (path->string interpreter) "one" "two"))
    (check-true (and (= status 2) (equal? output "") (regexp-match? #rx"usage:" errors))))
  (test-case "importing the library does not execute the bundled example"
    (check-equal? (run "-e" (format "(require (file ~s))" (path->string interpreter))) '(0 "" "")))
  (test-case "runtime failure uses stderr and a nonzero exit status"
    (define path (make-temporary-file "interpreter-cli-~a.java"))
    (dynamic-wind
      (lambda () (display-to-file "function main(){throw 17;}" path #:exists 'truncate))
      (lambda ()
        (match-define (list status output errors) (run (path->string interpreter) (path->string path)))
        (check-true (and (= status 1) (equal? output "")
                         (regexp-match? #rx"uncaught exception: 17" errors))))
      (lambda () (delete-file path)))))
