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

(define (parse-rating raw)
  (define rating (parse-int raw "rating"))
  (unless (and (>= rating 1) (<= rating 5))
    (error 'cli (format "Rating must be between 1 and 5: ~a" rating)))
  rating)

(define (parse-tags raw)
  (if (or (not raw) (string=? (string-trim raw) ""))
      '()
      (filter (lambda (tag) (not (string=? tag "")))
              (map string-trim (string-split raw ",")))))

(provide parse-bool parse-int parse-rating parse-tags)
