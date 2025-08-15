#lang racket

(require racket/string)

(define (parse-bool raw)
  (define lowered (string-downcase (string-trim raw)))
  (cond
    [(member lowered '("yes" "true" "1")) #t]
    [(member lowered '("no" "false" "0")) #f]
    [else (error 'cli (format "Invalid boolean value: ~a" raw))]))

(define (parse-int raw label)
  (define num (string->number raw))
  (unless (and num (integer? num))
    (error 'cli (format "Invalid integer for ~a: ~a" label raw)))
  num)

(define (parse-decimal raw label)
  (define num (string->number raw))
  (unless (and num (real? num))
    (error 'cli (format "Invalid number for ~a: ~a" label raw)))
  (exact->inexact num))

(define (parse-decimal-range raw label min-val max-val)
  (define num (parse-decimal raw label))
  (unless (and (>= num min-val) (<= num max-val))
    (error 'cli (format "~a must be between ~a and ~a: ~a" label min-val max-val num)))
  num)

(define (parse-rating raw)
  (define rating (parse-int raw "rating"))
  (unless (and (>= rating 1) (<= rating 5))
    (error 'cli (format "Rating must be between 1 and 5: ~a" rating)))
  rating)

(define (parse-rate raw label)
  (parse-decimal-range raw label 0 1))

(define (parse-tags raw)
  (if (or (not raw) (string=? (string-trim raw) ""))
      '()
      (filter (lambda (tag) (not (string=? tag "")))
              (map string-trim (string-split raw ",")))))

(provide parse-bool
         parse-int
         parse-decimal
         parse-decimal-range
         parse-rate
         parse-rating
         parse-tags)
