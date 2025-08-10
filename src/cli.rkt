#lang racket

(require racket/date
         racket/string
         "feedback_loop.rkt"
         "util.rkt")

(define (usage)
  (displayln "Group Scholar Mentor Feedback Loop")
  (displayln "Commands:")
  (displayln "  list-mentors")
  (displayln "  add-mentor --name NAME --org ORG")
  (displayln "  add-session --mentor-id ID --date YYYY-MM-DD --scholar NAME --program NAME --rating 1-5 --notes TEXT --follow-up yes|no --tags tag1,tag2")
  (displayln "  mentor-summary --mentor-id ID")
  (displayln "  weekly-digest --week-start YYYY-MM-DD"))

(define (arg-value args key)
  (define idx (member key args))
  (if (and idx (pair? (cdr idx)))
      (cadr idx)
      #f))

(define (require-arg args key)
  (define val (arg-value args key))
  (unless val
    (error 'cli (format "Missing required argument: ~a" key)))
  val)

(define (print-mentor-row row)
  (match row
    [(list id name org active created-at)
     (printf "~a | ~a | ~a | active: ~a | created: ~a~n"
             id name org active created-at)]
    [_ (displayln row)]))

(define (print-summary summary)
  (match summary
    [(list name org sessions avg-rating follow-ups last-session)
     (printf "Mentor: ~a (~a)~n" name org)
     (printf "Sessions: ~a | Avg rating: ~a | Follow-ups: ~a | Last: ~a~n"
             sessions avg-rating follow-ups (or last-session "n/a"))]
    [_ (displayln summary)]))

(define (print-digest summary tags)
  (match summary
    [(list sessions avg-rating follow-ups)
     (printf "Weekly digest: sessions=~a avg_rating=~a follow_ups=~a~n" sessions avg-rating follow-ups)]
    [_ (displayln summary)])
  (when (pair? tags)
    (displayln "Top tags:")
    (for ([row tags])
      (match row
        [(list label uses)
         (printf "- ~a (~a)~n" label uses)]
        [_ (displayln row)]))))

(define argv (vector->list (current-command-line-arguments)))

(if (null? argv)
    (usage)
    (case (string->symbol (car argv))
      [(list-mentors)
       (for ([row (list-mentors)])
         (print-mentor-row row))]
      [(add-mentor)
       (define name (require-arg argv "--name"))
       (define org (require-arg argv "--org"))
       (add-mentor! name org)
       (displayln "Mentor added.")]
      [(add-session)
       (define mentor-id (string->number (require-arg argv "--mentor-id")))
       (define session-date (require-arg argv "--date"))
       (define scholar (require-arg argv "--scholar"))
       (define program (require-arg argv "--program"))
       (define rating (string->number (require-arg argv "--rating")))
       (define notes (require-arg argv "--notes"))
       (define follow-up (parse-bool (require-arg argv "--follow-up")))
       (define tags (parse-tags (arg-value argv "--tags")))
       (add-session! mentor-id session-date scholar program rating notes follow-up tags)
       (displayln "Session logged.")]
      [(mentor-summary)
       (define mentor-id (string->number (require-arg argv "--mentor-id")))
       (print-summary (mentor-summary mentor-id))]
      [(weekly-digest)
       (define week-start (require-arg argv "--week-start"))
       (define-values (summary tags) (weekly-digest week-start))
       (print-digest summary tags)]
      [else (usage)]))
