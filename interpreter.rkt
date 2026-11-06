#lang racket

;; Simple Language Interpreter Part 3
;; Original course team: Zeyu Chen, Andrej Antunovikj, Dasheng Lin.
;; Showcase revision: lexical environments use shared binding cells; control
;; transfers remain explicit continuations. Original implementation: 5faf614.

(require "functionParser.rkt" racket/runtime-path)
(provide interpret)

(struct closure (name parameters body environment) #:transparent)
(struct transfer (kind value) #:transparent)
(define uninitialized (gensym 'uninitialized))

(define (fail message . arguments)
  (raise-user-error 'interpreter (apply format message arguments)))

;; An environment is a lexical chain of frames. A frame maps names to cells.
;; Closures share those cells, never reconstruct bindings from a caller's names.
(define (new-frame environment) (cons (make-hasheq) environment))

(define (binding name environment)
  (cond
    [(null? environment) (fail "undefined variable: ~a" name)]
    [(hash-ref (car environment) name #f) => values]
    [else (binding name (cdr environment))]))

(define (lookup name environment)
  (define value (unbox (binding name environment)))
  (when (eq? value uninitialized) (fail "uninitialized variable: ~a" name))
  value)

(define (declare! name value environment)
  (when (hash-has-key? (car environment) name) (fail "redeclared variable: ~a" name))
  (hash-set! (car environment) name (box value)))

(define (declare-function! statement environment)
  (match-define (list 'function name parameters body) statement)
  (when (memq '& parameters) (fail "reference parameters are not supported"))
  (unless (= (length parameters) (length (remove-duplicates parameters)))
    (fail "duplicate parameter in function: ~a" name))
  (declare! name (closure name parameters body environment) environment))

(define (integer-value value)
  (unless (exact-integer? value) (fail "expected integer, received ~a" value))
  value)

(define (boolean-value value)
  (unless (boolean? value) (fail "expected boolean, received ~a" value))
  value)

(define (value-result value name)
  (when (void? value) (fail "function ~a completed without a return value" name))
  value)

(define (call-function statement caller-environment throw)
  (match-define (list 'funcall name arguments ...) statement)
  (define function (lookup name caller-environment))
  (unless (closure? function) (fail "~a is not a function" name))
  (define parameters (closure-parameters function))
  (unless (= (length parameters) (length arguments))
    (fail "arity mismatch for ~a: expected ~a arguments, received ~a"
          name (length parameters) (length arguments)))
  ;; Evaluate arguments in the caller, left to right, before entering the callee.
  (define values
    (for/list ([argument (in-list arguments)])
      (eval-expression argument caller-environment throw)))
  (define local (new-frame (closure-environment function)))
  (for ([parameter (in-list parameters)] [value (in-list values)])
    (declare! parameter value local))
  (call/cc
   (lambda (return)
     (execute-list (closure-body function) local return
                   (lambda () (fail "break used outside a loop"))
                   (lambda () (fail "continue used outside a loop")) throw)
     (void))))

(define (eval-expression expression environment throw)
  (match expression
    [(? exact-integer?) expression]
    ['true #t]
    ['false #f]
    [(? symbol?) (lookup expression environment)]
    [(list 'funcall name arguments ...)
     (value-result (call-function expression environment throw) name)]
    [(list '= name rhs)
     (define target (binding name environment))
     (define value (eval-expression rhs environment throw))
     (set-box! target value)
     value]
    [(list '! operand) (not (boolean-value (eval-expression operand environment throw)))]
    [(list '- operand) (- (integer-value (eval-expression operand environment throw)))]
    [(list '&& left right)
     (and (boolean-value (eval-expression left environment throw))
          (boolean-value (eval-expression right environment throw)))]
    [(list '|| left right)
     (or (boolean-value (eval-expression left environment throw))
         (boolean-value (eval-expression right environment throw)))]
    [(list operator left right)
     (define a (eval-expression left environment throw))
     (define b (eval-expression right environment throw))
     (cond
       [(memq operator '(== !=))
        (unless (and (or (exact-integer? a) (boolean? a))
                     (or (exact-integer? b) (boolean? b)))
          (fail "equality requires integer or boolean values"))
        (if (eq? operator '==) (equal? a b) (not (equal? a b)))]
       [else
        (integer-value a)
        (integer-value b)
        (case operator
          [(+) (+ a b)] [(-) (- a b)] [(*) (* a b)]
          [(/ %) (when (zero? b) (fail "division by zero"))
                 (if (eq? operator '/) (quotient a b) (remainder a b))]
          [(<) (< a b)] [(<=) (<= a b)] [(>) (> a b)] [(>=) (>= a b)]
          [else (fail "unknown operator: ~a" operator)])])]
    [_ (fail "invalid expression: ~a" expression)]))

(define (execute-list statements environment return break continue throw)
  (for ([statement (in-list statements)])
    (execute-statement statement environment return break continue throw)))

(define (execute-block statements environment return break continue throw)
  (execute-list statements (new-frame environment) return break continue throw))

;; Capture a pending language-level transfer before running finally. This avoids
;; stale state and guarantees finally runs on normal completion and every kind
;; of transfer. A new transfer from finally supersedes the pending transfer.
(define (capture action)
  (call/cc
   (lambda (done)
     (action (lambda (value) (done (transfer 'return value)))
             (lambda () (done (transfer 'break #f)))
             (lambda () (done (transfer 'continue #f)))
             (lambda (value) (done (transfer 'throw value))))
     (transfer 'normal #f))))

(define (execute-try body catch-clause finally-clause environment return break continue throw)
  (define pending
    (capture (lambda (r b c t) (execute-block body environment r b c t))))
  (when (and (eq? (transfer-kind pending) 'throw) (pair? catch-clause))
    (match-define (list 'catch (list name) catch-body) catch-clause)
    (define catch-environment (new-frame environment))
    (declare! name (transfer-value pending) catch-environment)
    (set! pending
          (capture (lambda (r b c t)
                     (execute-list catch-body catch-environment r b c t)))))
  (when (pair? finally-clause)
    (execute-block (cadr finally-clause) environment return break continue throw))
  (case (transfer-kind pending)
    [(normal) (void)]
    [(return) (return (transfer-value pending))]
    [(break) (break)]
    [(continue) (continue)]
    [(throw) (throw (transfer-value pending))]))

(define (execute-statement statement environment return break continue throw)
  (match statement
    [(list 'var name)
     (declare! name uninitialized environment)]
    [(list 'var name expression)
     (when (hash-has-key? (car environment) name) (fail "redeclared variable: ~a" name))
     (declare! name (eval-expression expression environment throw) environment)]
    [(list '= name expression) (eval-expression statement environment throw) (void)]
    [(list 'function _ _ _) (declare-function! statement environment)]
    [(list 'funcall _ _ ...) (call-function statement environment throw) (void)]
    [(list 'return expression) (return (eval-expression expression environment throw))]
    [(list 'if condition then)
     (when (boolean-value (eval-expression condition environment throw))
       (execute-statement then environment return break continue throw))]
    [(list 'if condition then otherwise)
     (execute-statement
      (if (boolean-value (eval-expression condition environment throw)) then otherwise)
      environment return break continue throw)]
    [(list 'while condition body)
     (call/cc
      (lambda (stop)
        (let loop ()
          (when (boolean-value (eval-expression condition environment throw))
            (call/cc
             (lambda (next)
               (execute-statement body environment return
                                  (lambda () (stop (void)))
                                  (lambda () (next (void))) throw)))
            (loop)))))]
    [(list 'begin statements ...)
     (execute-block statements environment return break continue throw)]
    [(list 'break) (break)]
    [(list 'continue) (continue)]
    [(list 'throw expression) (throw (eval-expression expression environment throw))]
    [(list 'try body catch-clause finally-clause)
     (execute-try body catch-clause finally-clause environment return break continue throw)]
    [_ (fail "unknown statement: ~a" statement)]))

(define (interpret file)
  (define statements (parser file))
  (define global (new-frame '()))
  (define (uncaught value) (fail "uncaught exception: ~a" value))
  ;; Register global functions before initializing variables, permitting mutual
  ;; recursion and calls independent of global function declaration order.
  (for ([statement (in-list statements)] #:when (eq? (car statement) 'function))
    (declare-function! statement global))
  (for ([statement (in-list statements)] #:unless (eq? (car statement) 'function))
    (execute-statement statement global
                       (lambda (_) (fail "return outside a function"))
                       (lambda () (fail "break used outside a loop"))
                       (lambda () (fail "continue used outside a loop")) uncaught))
  (define value (value-result (call-function '(funcall main) global uncaught) 'main))
  (cond [(eq? value #t) 'true]
        [(eq? value #f) 'false]
        [(exact-integer? value) value]
        [else (fail "main must return an integer or boolean")]))

(define-runtime-path default-example "test.java")
(module+ main
  (define arguments (current-command-line-arguments))
  (when (> (vector-length arguments) 1)
    (eprintf "usage: racket interpreter.rkt [program.java]\n")
    (exit 2))
  (with-handlers ([exn:fail? (lambda (exception)
                              (eprintf "~a\n" (exn-message exception))
                              (exit 1))])
    (displayln (interpret (if (zero? (vector-length arguments))
                             default-example (vector-ref arguments 0))))))
