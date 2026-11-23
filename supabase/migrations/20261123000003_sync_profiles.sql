-- Backfill any auth.users that do not yet have a row in public.profiles
insert into public.profiles (id, student_id, full_name, email, role, campus)
select
  u.id,
  nullif(u.raw_user_meta_data->>'student_id', ''),
  coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  u.email,
  coalesce(u.raw_user_meta_data->>'role', 'student'),
  coalesce(u.raw_user_meta_data->>'campus', 'Talisay')
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
);
