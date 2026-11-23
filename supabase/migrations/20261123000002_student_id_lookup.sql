-- Allow student login using Student ID by resolving to their registered university email
create or replace function public.get_email_by_student_id(p_student_id text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email from public.profiles
  where student_id = p_student_id
  limit 1;
$$;

grant execute on function public.get_email_by_student_id(text) to anon, authenticated;
