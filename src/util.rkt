#lang racket

(require racket/string)

(define (parse-bool raw)
  (define lowered (string-downcase (string-trim raw)))
  (cond
    [(member lowered '("yes" "true" "1")) #t]
    [(member lowered '("no" "false" "0")) #f]
    [else (error 'cli (format "Invalid boolean value: ~a" raw))]))

(define (parse-tags raw)
  (if (or (not raw) (string=? (string-trim raw) ""))
      '()
      (filter (lambda (tag) (not (string=? tag "")))
              (map string-trim (string-split raw ",")))))

(provide parse-bool parse-tags)
