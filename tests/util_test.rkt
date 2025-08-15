#lang racket

(require rackunit
         "../src/util.rkt")

(module+ test
  (check-true (parse-bool "yes"))
  (check-true (parse-bool "True"))
  (check-false (parse-bool "no"))
  (check-equal? (parse-int "12" "mentor-id") 12)
  (check-equal? (parse-decimal "3.25" "rating") 3.25)
  (check-equal? (parse-decimal-range "4.5" "avg-rating" 1 5) 4.5)
  (check-equal? (parse-rate "0.6" "follow-up-rate") 0.6)
  (check-equal? (parse-rating "5") 5)
  (check-exn exn:fail? (lambda () (parse-rating "7")))
  (check-equal? (parse-tags "goal-setting, confidence, ") '("goal-setting" "confidence"))
  (check-equal? (parse-tags "") '())
  (check-equal? (parse-tags #f) '()))
