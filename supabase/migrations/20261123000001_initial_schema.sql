-- CHMSU Mobile Library Resource Application - Initial Schema
-- Follows the Supabase + Postgres + RLS architecture of Security Agency Management System

create extension if not exists "pgcrypto";

-- 1. PROFILES (Students & Librarians)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  student_id text unique,
  full_name text not null,
  email text unique not null,
  role text not null default 'student' check (role in ('student', 'librarian')),
  campus text not null default 'Talisay',
  created_at timestamptz not null default now()
);

-- 2. LIBRARY RESOURCES (Print books & E-resources)
create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  authors text not null,
  edition_year text not null default '',
  format text not null check (format in ('print', 'ebook')),
  subject text not null,
  campus text not null default 'Talisay',
  shelf_location text not null default '',
  call_number text not null default '',
  description text not null default '',
  total_copies integer not null default 1 check (total_copies >= 0),
  available_copies integer not null default 1 check (available_copies >= 0),
  cover_color text not null default '#1B4332',
  cover_tag text not null default '',
  created_at timestamptz not null default now()
);

-- 3. RESERVATIONS
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  reference_code text unique not null,
  student_id uuid not null references public.profiles(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'ready', 'completed', 'cancelled')),
  pickup_deadline timestamptz,
  notes text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. BORROWINGS (Active loans & Borrowing history)
create table if not exists public.borrowings (
  id uuid primary key default gen_random_uuid(),
  transaction_code text unique not null,
  student_id uuid not null references public.profiles(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  reservation_id uuid references public.reservations(id) on delete set null,
  status text not null default 'borrowed' check (status in ('borrowed', 'returned', 'overdue')),
  borrowed_at timestamptz not null default now(),
  due_at timestamptz not null default (now() + interval '7 days'),
  returned_at timestamptz
);

-- 5. DIGITAL ACCESS LOGS (For E-resource analytics)
create table if not exists public.digital_access_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  accessed_at timestamptz not null default now()
);

-- 6. AUTOMATED NOTIFICATIONS
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null default 'borrowing' check (category in ('borrowing', 'library')),
  type text not null default 'reservation_update' check (type in ('reservation_ready', 'reservation_update', 'due_soon', 'overdue', 'library_update')),
  title text not null,
  body text not null,
  status_label text not null default '',
  reference_id text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 7. GENERATED REPORTS HISTORY
create table if not exists public.generated_reports (
  id uuid primary key default gen_random_uuid(),
  report_code text unique not null,
  report_type text not null check (report_type in ('resource_usage', 'borrowing_summary', 'reservation_status')),
  period_label text not null,
  campus text not null default 'Talisay',
  resource_format text not null default 'All formats',
  generated_by uuid references public.profiles(id) on delete set null,
  format text not null default 'CSV / PDF',
  created_at timestamptz not null default now()
);

-- Helper: check if current authenticated user is a librarian
create or replace function public.is_librarian()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'librarian'
  );
$$;

-- Trigger: auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, student_id, full_name, email, role, campus)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'student_id', ''),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'student'),
    coalesce(new.raw_user_meta_data->>'campus', 'Talisay')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Sequence helpers for human-readable codes
create sequence if not exists public.reservation_seq start 100;
create sequence if not exists public.borrowing_seq start 100;
create sequence if not exists public.report_seq start 10;

-- RPC: Student reserves a copy
create or replace function public.reserve_resource(p_resource_id uuid)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_res public.resources;
  v_ref text;
  v_row public.reservations;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  select * into v_res from public.resources where id = p_resource_id for update;
  if not found then
    raise exception 'Resource not found';
  end if;

  if v_res.format <> 'print' then
    raise exception 'Only print resources can be reserved';
  end if;

  if v_res.available_copies <= 0 then
    raise exception 'No copies currently available for reservation';
  end if;

  v_ref := 'RSV-' || to_char(now(), 'YYMMDD') || '-' || lpad(nextval('public.reservation_seq')::text, 3, '0');

  insert into public.reservations (reference_code, student_id, resource_id, status)
  values (v_ref, v_user_id, p_resource_id, 'pending')
  returning * into v_row;

  insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
  values (
    v_user_id,
    'borrowing',
    'reservation_update',
    'Reservation submitted',
    v_res.title || ' (' || v_ref || ') is pending librarian review.',
    'Pending review',
    v_row.id::text
  );

  return v_row;
end;
$$;

-- RPC: Librarian or student updates reservation status
create or replace function public.update_reservation_status(
  p_reservation_id uuid,
  p_new_status text,
  p_pickup_deadline timestamptz default null
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_rsv public.reservations;
  v_res public.resources;
  v_title text;
  v_body text;
  v_label text;
  v_type text := 'reservation_update';
begin
  select * into v_rsv from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'Reservation not found';
  end if;

  -- Students may only cancel their own active reservations
  if not public.is_librarian() then
    if v_rsv.student_id <> v_uid or p_new_status <> 'cancelled' then
      raise exception 'Not authorized';
    end if;
  end if;

  select * into v_res from public.resources where id = v_rsv.resource_id for update;

  -- Manage copy hold when transitioning into approved/ready or cancelling
  if v_rsv.status = 'pending' and p_new_status in ('approved', 'ready') then
    if v_res.available_copies <= 0 then
      raise exception 'No available copies left to allocate';
    end if;
    update public.resources set available_copies = available_copies - 1 where id = v_res.id;
  elsif v_rsv.status in ('approved', 'ready') and p_new_status = 'cancelled' then
    update public.resources set available_copies = least(total_copies, available_copies + 1) where id = v_res.id;
  end if;

  update public.reservations
  set status = p_new_status,
      pickup_deadline = coalesce(p_pickup_deadline,
        case when p_new_status = 'ready' then (date_trunc('day', now() + interval '1 day') + interval '16 hours') else pickup_deadline end),
      updated_at = now()
  where id = p_reservation_id
  returning * into v_rsv;

  if p_new_status = 'approved' then
    v_title := 'Reservation approved';
    v_body := v_res.title || ' has been approved and is awaiting preparation at the circulation desk.';
    v_label := 'Approved';
  elsif p_new_status = 'ready' then
    v_type := 'reservation_ready';
    v_title := 'Your book is ready';
    v_body := v_res.title || ' is ready at the ' || v_res.campus || ' circulation desk. Collect by ' || to_char(v_rsv.pickup_deadline, 'DD Mon, FMHH12:MI AM') || '.';
    v_label := 'Reservation ready';
  elsif p_new_status = 'cancelled' then
    v_title := 'Reservation cancelled';
    v_body := 'Reservation ' || v_rsv.reference_code || ' for ' || v_res.title || ' has been cancelled.';
    v_label := 'Cancelled';
  end if;

  if v_title is not null then
    insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
    values (v_rsv.student_id, 'borrowing', v_type, v_title, v_body, v_label, v_rsv.id::text);
  end if;

  return v_rsv;
end;
$$;

-- RPC: Librarian completes checkout from a reservation -> creates borrowing
create or replace function public.complete_reservation_checkout(p_reservation_id uuid)
returns public.borrowings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rsv public.reservations;
  v_res public.resources;
  v_txn text;
  v_borrowing public.borrowings;
begin
  if not public.is_librarian() then
    raise exception 'Librarian role required';
  end if;

  select * into v_rsv from public.reservations where id = p_reservation_id for update;
  if not found then
    raise exception 'Reservation not found';
  end if;

  if v_rsv.status in ('completed', 'cancelled') then
    raise exception 'Reservation is already closed';
  end if;

  select * into v_res from public.resources where id = v_rsv.resource_id for update;
  if v_rsv.status = 'pending' then
    if v_res.available_copies <= 0 then
      raise exception 'No available copies';
    end if;
    update public.resources set available_copies = available_copies - 1 where id = v_res.id;
  end if;

  update public.reservations set status = 'completed', updated_at = now() where id = p_reservation_id;

  v_txn := 'TXN-' || to_char(now(), 'YYMMDD') || '-' || lpad(nextval('public.borrowing_seq')::text, 3, '0');

  insert into public.borrowings (transaction_code, student_id, resource_id, reservation_id, status, borrowed_at, due_at)
  values (v_txn, v_rsv.student_id, v_rsv.resource_id, v_rsv.id, 'borrowed', now(), date_trunc('day', now() + interval '7 days') + interval '17 hours')
  returning * into v_borrowing;

  insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
  values (
    v_rsv.student_id,
    'borrowing',
    'reservation_update',
    'Book checked out',
    v_res.title || ' (' || v_txn || ') is due on ' || to_char(v_borrowing.due_at, 'DD Mon YYYY') || '.',
    'Checked out',
    v_borrowing.id::text
  );

  return v_borrowing;
end;
$$;

-- RPC: Librarian records book return
create or replace function public.return_borrowed_book(p_borrowing_id uuid)
returns public.borrowings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bor public.borrowings;
  v_res public.resources;
begin
  if not public.is_librarian() then
    raise exception 'Librarian role required';
  end if;

  select * into v_bor from public.borrowings where id = p_borrowing_id for update;
  if not found then
    raise exception 'Borrowing record not found';
  end if;

  if v_bor.status = 'returned' then
    return v_bor;
  end if;

  update public.borrowings
  set status = 'returned', returned_at = now()
  where id = p_borrowing_id
  returning * into v_bor;

  update public.resources
  set available_copies = least(total_copies, available_copies + 1)
  where id = v_bor.resource_id
  returning * into v_res;

  insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
  values (
    v_bor.student_id,
    'borrowing',
    'reservation_update',
    'Book returned',
    v_res.title || ' (' || v_bor.transaction_code || ') has been marked as returned.',
    case when v_bor.returned_at > v_bor.due_at then 'Returned late' else 'Returned on time' end,
    v_bor.id::text
  );

  return v_bor;
end;
$$;

-- RPC: Log digital e-resource access
create or replace function public.log_digital_access(p_resource_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  insert into public.digital_access_logs (student_id, resource_id)
  values (auth.uid(), p_resource_id);
end;
$$;

-- RPC: Automated due-soon and overdue notifications
create or replace function public.generate_due_and_overdue_notifications()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  r record;
begin
  -- Mark overdue loans
  update public.borrowings
  set status = 'overdue'
  where status = 'borrowed' and due_at < now();

  -- Overdue notifications (max 1 per borrowing per day)
  for r in
    select b.id, b.student_id, b.due_at, res.title,
           greatest(1, extract(day from (now() - b.due_at))::integer) as days_late
    from public.borrowings b
    join public.resources res on res.id = b.resource_id
    where b.status = 'overdue'
      and not exists (
        select 1 from public.notifications n
        where n.user_id = b.student_id
          and n.reference_id = b.id::text
          and n.type = 'overdue'
          and n.created_at::date = now()::date
      )
  loop
    insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
    values (
      r.student_id, 'borrowing', 'overdue',
      'A return is overdue',
      r.title || ' was due on ' || to_char(r.due_at, 'DD Mon YYYY') || '. Return the copy or contact the library for help.',
      r.days_late || ' days overdue',
      r.id::text
    );
    v_count := v_count + 1;
  end loop;

  -- Due soon notifications (within 2 days)
  for r in
    select b.id, b.student_id, b.due_at, res.title, res.campus
    from public.borrowings b
    join public.resources res on res.id = b.resource_id
    where b.status = 'borrowed'
      and b.due_at between now() and (now() + interval '2 days')
      and not exists (
        select 1 from public.notifications n
        where n.user_id = b.student_id
          and n.reference_id = b.id::text
          and n.type = 'due_soon'
      )
  loop
    insert into public.notifications (user_id, category, type, title, body, status_label, reference_id)
    values (
      r.student_id, 'borrowing', 'due_soon',
      'Due in 2 days',
      r.title || ' is due on ' || to_char(r.due_at, 'DD Mon YYYY') || '. Please return your print copy to the circulation desk.',
      'Due soon',
      r.id::text
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ROW LEVEL SECURITY (RLS)
alter table public.profiles enable row level security;
alter table public.resources enable row level security;
alter table public.reservations enable row level security;
alter table public.borrowings enable row level security;
alter table public.digital_access_logs enable row level security;
alter table public.notifications enable row level security;
alter table public.generated_reports enable row level security;

-- Profiles policies
create policy "Users can view own profile or librarians view all"
  on public.profiles for select
  using (auth.uid() = id or public.is_librarian());

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Resources policies
create policy "Authenticated users can view resources"
  on public.resources for select
  using (auth.role() = 'authenticated');

create policy "Librarians can manage resources"
  on public.resources for all
  using (public.is_librarian());

-- Reservations policies
create policy "Students view own reservations; librarians view all"
  on public.reservations for select
  using (auth.uid() = student_id or public.is_librarian());

create policy "Students create own reservations"
  on public.reservations for insert
  with check (auth.uid() = student_id);

create policy "Librarians manage reservations"
  on public.reservations for update
  using (public.is_librarian() or auth.uid() = student_id);

-- Borrowings policies
create policy "Students view own borrowings; librarians view all"
  on public.borrowings for select
  using (auth.uid() = student_id or public.is_librarian());

create policy "Librarians manage borrowings"
  on public.borrowings for all
  using (public.is_librarian());

-- Digital access logs policies
create policy "Students log own digital access; librarians view all"
  on public.digital_access_logs for select
  using (auth.uid() = student_id or public.is_librarian());

create policy "Students insert own digital access"
  on public.digital_access_logs for insert
  with check (auth.uid() = student_id);

-- Notifications policies
create policy "Users view own notifications; librarians view all"
  on public.notifications for select
  using (auth.uid() = user_id or public.is_librarian());

create policy "Users mark own notifications read"
  on public.notifications for update
  using (auth.uid() = user_id);

create policy "Librarians send library notifications"
  on public.notifications for insert
  with check (public.is_librarian());

-- Generated reports policies
create policy "Librarians manage reports"
  on public.generated_reports for all
  using (public.is_librarian());
