# Group Scholar Mentor Feedback Loop

A Racket CLI that logs mentor session feedback, tracks follow-ups, and builds weekly digests for the Group Scholar team. It stores structured feedback in Postgres, making it easy to surface trends, mentor performance signals, and follow-up needs.

## Features
- Add mentors and session feedback entries with tags
- Track follow-up needs and session quality ratings
- Mentor-level summaries (session counts, average ratings, follow-ups)
- Weekly digest report for program leads
- Postgres-backed storage with a dedicated schema

## Tech
- Racket
- PostgreSQL

## Setup
1. Install Racket and the `db` package (bundled with Racket).
2. Set environment variables:
   - `GS_DB_HOST`
   - `GS_DB_PORT`
   - `GS_DB_NAME` (default: `postgres`)
   - `GS_DB_USER`
   - `GS_DB_PASSWORD`
3. Create schema + tables:
   ```bash
   psql "$GS_DB_NAME" -h "$GS_DB_HOST" -p "$GS_DB_PORT" -U "$GS_DB_USER" -f sql/schema.sql
   ```
4. Seed sample data (production only):
   ```bash
   psql "$GS_DB_NAME" -h "$GS_DB_HOST" -p "$GS_DB_PORT" -U "$GS_DB_USER" -f sql/seed.sql
   ```

## Usage
Run with Racket:
```bash
racket src/cli.rkt list-mentors
racket src/cli.rkt add-mentor --name "Ariane Wells" --org "STEM Fellows"
racket src/cli.rkt add-session --mentor-id 1 --date 2026-02-03 --scholar "Nico P" --program "STEM Scholars" --rating 5 --notes "Strong goal-setting focus." --follow-up no --tags "goal-setting,confidence"
racket src/cli.rkt mentor-summary --mentor-id 1
racket src/cli.rkt weekly-digest --week-start 2026-02-02
```

## Notes
- Uses a dedicated schema: `mentor_feedback_loop`.
- Avoid storing credentials in source control; use environment variables.

