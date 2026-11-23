-- Allow both anon and authenticated users to read the library catalog
drop policy if exists "Authenticated users can view resources" on public.resources;
create policy "Anyone can view resources"
  on public.resources for select
  using (true);
