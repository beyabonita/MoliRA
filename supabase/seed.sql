-- Seed sample CHMSU Talisay Library resources
insert into public.resources (title, authors, edition_year, format, subject, campus, shelf_location, call_number, description, total_copies, available_copies, cover_color, cover_tag)
values
  (
    'Research Methods in Education',
    'Louis Cohen, Lawrence Manion & Keith Morrison',
    '8th edition · 2018',
    'print',
    'Education',
    'Talisay',
    'Talisay · Education section',
    'LB1028 C64 2018',
    'A practical guide to planning educational research, selecting methods, and interpreting findings. Useful for research proposals and thesis preparation.',
    5,
    2,
    '#1B4332',
    'EIGHTH EDITION'
  ),
  (
    'Fundamentals of Nursing',
    'Barbara Kozier, Glenora Erb & Audrey Berman',
    '10th edition · 2020',
    'print',
    'Nursing',
    'Talisay',
    'Talisay · Health Sciences section',
    'RT41 K69 2020',
    'Comprehensive foundational text covering clinical nursing concepts, patient care procedures, and evidence-based practice.',
    3,
    0,
    '#9A5B3C',
    'TENTH EDITION'
  ),
  (
    'Statistics for Research',
    'R. Sharma',
    'Study guide · 2022',
    'ebook',
    'Research',
    'Talisay',
    'Digital Repository',
    'QA276 S48 2022',
    'Applied statistical techniques for undergraduate and graduate research, including hypothesis testing, ANOVA, and regression.',
    10,
    10,
    '#345063',
    'STUDY GUIDE'
  ),
  (
    'Ethics & the Human Condition',
    'Learning Collection Editorial Board',
    '2nd edition · 2021',
    'print',
    'General education',
    'Talisay',
    'Talisay · Humanities section',
    'BJ1012 E84 2021',
    'Introductory reader on moral philosophy, civic responsibility, and ethical reasoning in contemporary society.',
    2,
    1,
    '#7D6B44',
    'SECOND EDITION'
  )
on conflict do nothing;
