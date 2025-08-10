#lang racket

(require db)

(define (required-env name)
  (define val (getenv name))
  (unless (and val (not (string=? val "")))
    (error 'config (format "Missing environment variable: ~a" name)))
  val)

(define (db-name)
  (define val (getenv "GS_DB_NAME"))
  (if (and val (not (string=? val ""))) val "postgres"))

(define (open-connection)
  (postgresql-connect
   #:host (required-env "GS_DB_HOST")
   #:port (string->number (required-env "GS_DB_PORT"))
   #:database (db-name)
   #:user (required-env "GS_DB_USER")
   #:password (required-env "GS_DB_PASSWORD")
   #:ssl 'yes))

(define (with-connection proc)
  (define conn (open-connection))
  (dynamic-wind
    void
    (lambda () (proc conn))
    (lambda () (disconnect conn))))

(provide with-connection)
