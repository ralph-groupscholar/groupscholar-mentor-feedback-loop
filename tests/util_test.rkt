#lang racket

(require rackunit
         "../src/util.rkt")

(module+ test
  (check-true (parse-bool "yes"))
  (check-true (parse-bool "True"))
  (check-false (parse-bool "no"))
  (check-equal? (parse-tags "goal-setting, confidence, ") '("goal-setting" "confidence"))
  (check-equal? (parse-tags "") '())
  (check-equal? (parse-tags #f) '()))
