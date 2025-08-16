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
  (displayln "  follow-up-queue --since YYYY-MM-DD --limit N")
  (displayln "  top-mentors --since YYYY-MM-DD --limit N")
  (displayln "  mentor-alerts --since YYYY-MM-DD --min-sessions N --max-avg-rating 1-5 --min-follow-up-rate 0-1")
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

(define (print-followups rows)
  (when (null? rows)
    (displayln "No follow-ups found."))
  (for ([row rows])
    (match row
      [(list id session-date scholar program rating notes mentor org days-since tags)
       (printf "~a | mentor: ~a (~a) | scholar: ~a | program: ~a | date: ~a | rating: ~a | days since: ~a~n"
               id mentor org scholar program session-date rating days-since)
       (printf "  tags: ~a~n  ~a~n" (if (string=? tags "") "n/a" tags) notes)]
      [_ (displayln row)])))

(define (print-top-mentors rows)
  (when (null? rows)
    (displayln "No mentors found in timeframe."))
  (for ([row rows])
    (match row
      [(list mentor org sessions avg-rating follow-ups)
       (printf "~a (~a) | sessions: ~a | avg rating: ~a | follow-ups: ~a~n"
               mentor org sessions avg-rating follow-ups)]
      [_ (displayln row)])))

(define (print-mentor-alerts rows)
  (when (null? rows)
    (displayln "No mentor alerts found for timeframe."))
  (for ([row rows])
    (match row
      [(list mentor org sessions avg-rating follow-up-rate last-session)
       (printf "~a (~a) | sessions: ~a | avg rating: ~a | follow-up rate: ~a | last: ~a~n"
               mentor org sessions avg-rating follow-up-rate last-session)]
      [_ (displayln row)])))

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
       (define mentor-id (parse-int (require-arg argv "--mentor-id") "mentor-id"))
       (define session-date (require-arg argv "--date"))
       (define scholar (require-arg argv "--scholar"))
       (define program (require-arg argv "--program"))
       (define rating (parse-rating (require-arg argv "--rating")))
       (define notes (require-arg argv "--notes"))
       (define follow-up (parse-bool (require-arg argv "--follow-up")))
       (define tags (parse-tags (arg-value argv "--tags")))
       (add-session! mentor-id session-date scholar program rating notes follow-up tags)
       (displayln "Session logged.")]
      [(mentor-summary)
       (define mentor-id (parse-int (require-arg argv "--mentor-id") "mentor-id"))
       (print-summary (mentor-summary mentor-id))]
      [(follow-up-queue)
       (define since (require-arg argv "--since"))
       (define limit-raw (arg-value argv "--limit"))
       (define limit (if limit-raw (parse-int limit-raw "limit") 50))
       (print-followups (follow-up-queue #:since since #:limit limit))]
      [(top-mentors)
       (define since (require-arg argv "--since"))
       (define limit (parse-int (require-arg argv "--limit") "limit"))
       (print-top-mentors (top-mentors since limit))]
      [(mentor-alerts)
       (define since (require-arg argv "--since"))
       (define min-sessions-raw (arg-value argv "--min-sessions"))
       (define max-avg-rating-raw (arg-value argv "--max-avg-rating"))
       (define min-follow-up-rate-raw (arg-value argv "--min-follow-up-rate"))
       (define min-sessions (if min-sessions-raw (parse-int min-sessions-raw "min-sessions") 3))
       (define max-avg-rating (if max-avg-rating-raw
                                  (parse-decimal-range max-avg-rating-raw "max-avg-rating" 1 5)
                                  3.0))
       (define min-follow-up-rate (if min-follow-up-rate-raw
                                      (parse-rate min-follow-up-rate-raw "min-follow-up-rate")
                                      0.4))
       (print-mentor-alerts (mentor-alerts since min-sessions max-avg-rating min-follow-up-rate))]
      [(weekly-digest)
       (define week-start (require-arg argv "--week-start"))
       (define-values (summary tags) (weekly-digest week-start))
       (print-digest summary tags)]
      [else (usage)]))
