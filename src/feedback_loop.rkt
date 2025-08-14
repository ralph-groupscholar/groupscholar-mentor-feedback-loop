#lang racket

(require db
         racket/list
         racket/string
         "db.rkt")

(define schema "mentor_feedback_loop")

(define (qualified name)
  (format "~a.~a" schema name))

(define (add-mentor! name org)
  (with-connection
   (lambda (conn)
     (query-exec conn
                 (format "insert into ~a (full_name, org) values ($1, $2)" (qualified "mentors"))
                 name org))))

(define (list-mentors)
  (with-connection
   (lambda (conn)
     (query-rows conn
                 (format "select id, full_name, org, active, created_at from ~a order by full_name" (qualified "mentors"))))))

(define (ensure-tags! conn tags)
  (for/list ([tag tags])
    (define normalized (string-downcase (string-trim tag)))
    (query-value conn
                 (format "insert into ~a (label) values ($1) on conflict (label) do update set label = excluded.label returning id" (qualified "tags"))
                 normalized)))

(define (add-session! mentor-id session-date scholar program rating notes follow-up tags)
  (with-connection
   (lambda (conn)
     (define session-id
       (query-value conn
                    (format "insert into ~a (mentor_id, session_date, scholar_name, program, rating, notes, follow_up_needed) values ($1,$2,$3,$4,$5,$6,$7) returning id" (qualified "sessions"))
                    mentor-id session-date scholar program rating notes follow-up))
     (define tag-ids (ensure-tags! conn tags))
     (for ([tag-id tag-ids])
       (query-exec conn
                   (format "insert into ~a (session_id, tag_id) values ($1, $2) on conflict do nothing" (qualified "session_tags"))
                   session-id tag-id))
     session-id)))

(define (mentor-summary mentor-id)
  (with-connection
   (lambda (conn)
     (query-row conn
                (format (string-append
                         "select m.full_name, m.org, "
                         "count(s.id) as sessions, "
                         "round(avg(s.rating)::numeric, 2) as avg_rating, "
                         "sum(case when s.follow_up_needed then 1 else 0 end) as follow_ups, "
                         "max(s.session_date) as last_session "
                         "from ~a m "
                         "left join ~a s on s.mentor_id = m.id "
                         "where m.id = $1 "
                         "group by m.full_name, m.org")
                        (qualified "mentors")
                        (qualified "sessions"))
                mentor-id))))

(define (weekly-digest week-start)
  (with-connection
   (lambda (conn)
     (define summary
       (query-row conn
                  (format (string-append
                           "select count(*) as sessions, "
                           "round(avg(rating)::numeric, 2) as avg_rating, "
                           "sum(case when follow_up_needed then 1 else 0 end) as follow_ups "
                           "from ~a where session_date between $1 and ($1::date + interval '6 days')")
                          (qualified "sessions"))
                  week-start))
     (define top-tags
       (query-rows conn
                   (format (string-append
                            "select t.label, count(*) as uses "
                            "from ~a st "
                            "join ~a t on t.id = st.tag_id "
                            "join ~a s on s.id = st.session_id "
                            "where s.session_date between $1 and ($1::date + interval '6 days') "
                            "group by t.label "
                            "order by uses desc, t.label "
                            "limit 5")
                           (qualified "session_tags")
                           (qualified "tags")
                           (qualified "sessions"))
                   week-start))
     (values summary top-tags))))

(define (follow-up-queue #:since [since #f] #:limit [limit 50])
  (with-connection
   (lambda (conn)
     (define base-query
       (string-append
        "select s.id, s.session_date, s.scholar_name, s.program, s.rating, s.notes, "
        "m.full_name, m.org, "
        "(current_date - s.session_date) as days_since, "
        "coalesce(string_agg(t.label, ', ' order by t.label), '') as tags "
        "from " (qualified "sessions") " s "
        "join " (qualified "mentors") " m on m.id = s.mentor_id "
        "left join " (qualified "session_tags") " st on st.session_id = s.id "
        "left join " (qualified "tags") " t on t.id = st.tag_id "
        "where s.follow_up_needed = true "))
     (define grouped
       (string-append
        "group by s.id, s.session_date, s.scholar_name, s.program, s.rating, s.notes, m.full_name, m.org "))
     (if since
         (query-rows conn
                     (string-append base-query
                                    "and s.session_date >= $1 "
                                    grouped
                                    "order by s.session_date asc, s.id asc "
                                    "limit $2")
                     since limit)
         (query-rows conn
                     (string-append base-query
                                    grouped
                                    "order by s.session_date asc, s.id asc "
                                    "limit $1")
                     limit)))))

(define (top-mentors since-date limit)
  (with-connection
   (lambda (conn)
     (query-rows conn
                 (format (string-append
                          "select m.full_name, m.org, count(s.id) as sessions, "
                          "round(avg(s.rating)::numeric, 2) as avg_rating, "
                          "sum(case when s.follow_up_needed then 1 else 0 end) as follow_ups "
                          "from ~a m "
                          "left join ~a s on s.mentor_id = m.id and s.session_date >= $1 "
                          "where m.active is true "
                          "group by m.full_name, m.org "
                          "order by sessions desc, avg_rating desc "
                          "limit $2")
                         (qualified "mentors")
                         (qualified "sessions"))
                 since-date limit))))

(provide add-mentor!
         list-mentors
         add-session!
         mentor-summary
         weekly-digest
         follow-up-queue
         top-mentors)
