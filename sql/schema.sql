create schema if not exists mentor_feedback_loop;

create table if not exists mentor_feedback_loop.mentors (
  id serial primary key,
  full_name text not null,
  org text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists mentor_feedback_loop.sessions (
  id serial primary key,
  mentor_id integer not null references mentor_feedback_loop.mentors(id) on delete cascade,
  session_date date not null,
  scholar_name text not null,
  program text not null,
  rating integer not null check (rating between 1 and 5),
  notes text not null,
  follow_up_needed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists mentor_feedback_loop.tags (
  id serial primary key,
  label text not null unique
);

create table if not exists mentor_feedback_loop.session_tags (
  session_id integer not null references mentor_feedback_loop.sessions(id) on delete cascade,
  tag_id integer not null references mentor_feedback_loop.tags(id) on delete cascade,
  primary key (session_id, tag_id)
);

create index if not exists idx_feedback_sessions_mentor on mentor_feedback_loop.sessions(mentor_id, session_date);
create index if not exists idx_feedback_sessions_date on mentor_feedback_loop.sessions(session_date);
create index if not exists idx_feedback_tags_label on mentor_feedback_loop.tags(label);
