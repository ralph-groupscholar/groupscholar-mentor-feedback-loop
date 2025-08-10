insert into mentor_feedback_loop.mentors (full_name, org, active)
values
  ('Ariane Wells', 'STEM Fellows', true),
  ('Marcus Dorsey', 'Community Pathways', true),
  ('Leila Zhang', 'College Access Lab', true)
on conflict do nothing;

insert into mentor_feedback_loop.tags (label)
values
  ('goal-setting'),
  ('confidence'),
  ('college-fit'),
  ('time-management'),
  ('financial-aid')
on conflict do nothing;

insert into mentor_feedback_loop.sessions (mentor_id, session_date, scholar_name, program, rating, notes, follow_up_needed)
values
  (1, '2026-02-03', 'Nico P', 'STEM Scholars', 5, 'Strong goal-setting focus with clear next steps.', false),
  (1, '2026-02-05', 'Priya K', 'STEM Scholars', 4, 'Confidence building and interview prep.', true),
  (2, '2026-02-04', 'Jamal S', 'Future Leaders', 3, 'Time management challenges surfaced.', true),
  (3, '2026-02-06', 'Lina R', 'College Access', 5, 'Great college-fit exploration.', false)
on conflict do nothing;

insert into mentor_feedback_loop.session_tags (session_id, tag_id)
values
  (1, 1),
  (1, 2),
  (2, 2),
  (3, 4),
  (4, 3)
on conflict do nothing;
