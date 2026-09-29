-- GST RecoPro Cloud / Multi-Company schema
-- Run this entire file in Supabase SQL Editor for the project used by GST RecoPro.
-- The browser uses only the publishable key. The service-role key is used only by the Netlify Function.

create extension if not exists pgcrypto;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) >= 2),
  gstin text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.company_members (
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('admin','user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (company_id,user_id)
);

create table if not exists public.company_snapshots (
  company_id uuid primary key references public.companies(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 0,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table if not exists public.company_period_locks (
  company_id uuid not null references public.companies(id) on delete cascade,
  module text not null check (module in ('2B','IMS')),
  period text not null check (period ~ '^\\d{4}-\\d{2}$'),
  meta jsonb not null default '{}'::jsonb,
  locked_at timestamptz not null default now(),
  locked_by uuid references auth.users(id) on delete set null,
  primary key(company_id,module,period)
);

create index if not exists company_members_user_idx on public.company_members(user_id);
create index if not exists company_period_locks_company_idx on public.company_period_locks(company_id,module,period);

-- Helper functions used by RLS and RPCs.
create or replace function public.is_company_member(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = p_company_id and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_company_admin(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = p_company_id and m.user_id = auth.uid() and m.role = 'admin'
  );
$$;

-- Create a company and make the authenticated caller its Admin.
create or replace function public.create_company(p_name text, p_gstin text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_name is null or length(trim(p_name)) < 2 then
    raise exception 'Company name is required';
  end if;
  -- A user without any company may create the first company. A user who is already a
  -- normal USER cannot create an extra tenant; company Admins may create additional companies.
  if exists (select 1 from public.company_members m where m.user_id=auth.uid() and m.role <> 'admin')
     and not exists (select 1 from public.company_members m where m.user_id=auth.uid() and m.role='admin') then
    raise exception 'Only a Company Admin can create another company';
  end if;

  insert into public.companies(name,gstin,created_by)
  values(trim(p_name),nullif(upper(trim(coalesce(p_gstin,''))),''),auth.uid())
  returning id into v_company_id;

  insert into public.company_members(company_id,user_id,role)
  values(v_company_id,auth.uid(),'admin');

  insert into public.company_snapshots(company_id,payload,revision,updated_by)
  values(v_company_id,jsonb_build_object(
    'app','gst-recon',
    'version',4,
    'nextId',1,
    'twoB','[]'::jsonb,
    'books','[]'::jsonb,
    'rcm','[]'::jsonb,
    'manualInel','{}'::jsonb,
    'ims',jsonb_build_object('records','[]'::jsonb,'books','[]'::jsonb),
    'notes','{}'::jsonb
  ),0,auth.uid());

  return v_company_id;
end;
$$;

-- Save the whole application state with optimistic concurrency.
-- p_expected_revision=0 is valid for the first save after an empty/new company.
create or replace function public.save_company_snapshot(
  p_company_id uuid,
  p_payload jsonb,
  p_expected_revision bigint
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current bigint;
  v_new bigint;
  v_current_payload jsonb;
  v_admin boolean;
  v_two_b_current integer; v_two_b_new integer;
  v_books_current integer; v_books_new integer;
  v_rcm_current integer; v_rcm_new integer;
  v_ims_current integer; v_ims_new integer;
  v_ims_books_current integer; v_ims_books_new integer;
begin
  if auth.uid() is null or not public.is_company_member(p_company_id) then
    raise exception 'Company access denied';
  end if;
  if jsonb_typeof(coalesce(p_payload,'{}'::jsonb)) <> 'object' then
    raise exception 'Invalid company payload';
  end if;

  v_admin := public.is_company_admin(p_company_id);

  select revision, payload into v_current, v_current_payload
  from public.company_snapshots
  where company_id = p_company_id
  for update;

  if v_current is null then
    if not v_admin then raise exception 'Company snapshot must be initialized by an Admin'; end if;
    if coalesce(p_expected_revision,0) <> 0 then
      raise exception 'CONFLICT: company snapshot does not exist';
    end if;
    v_new := 1;
    insert into public.company_snapshots(company_id,payload,revision,updated_by,updated_at)
    values(p_company_id,p_payload,v_new,auth.uid(),now());
  else
    if v_current <> coalesce(p_expected_revision,0) then
      raise exception 'CONFLICT: expected revision %, current revision %',p_expected_revision,v_current;
    end if;

    -- Normal company users can import/reconcile, but cannot alter period locks
    -- or use the generic snapshot RPC to erase existing rows.
    if not v_admin then
      if coalesce(v_current_payload->'closed','{}'::jsonb)
         is distinct from coalesce(p_payload->'closed','{}'::jsonb) then
        raise exception 'Admin permission required to change 2B period locks';
      end if;
      if coalesce(v_current_payload->'ims'->'closed','{}'::jsonb)
         is distinct from coalesce(p_payload->'ims'->'closed','{}'::jsonb) then
        raise exception 'Admin permission required to change IMS period locks';
      end if;

      v_two_b_current := jsonb_array_length(coalesce(v_current_payload->'twoB','[]'::jsonb));
      v_two_b_new := jsonb_array_length(coalesce(p_payload->'twoB','[]'::jsonb));
      v_books_current := jsonb_array_length(coalesce(v_current_payload->'books','[]'::jsonb));
      v_books_new := jsonb_array_length(coalesce(p_payload->'books','[]'::jsonb));
      v_rcm_current := jsonb_array_length(coalesce(v_current_payload->'rcm','[]'::jsonb));
      v_rcm_new := jsonb_array_length(coalesce(p_payload->'rcm','[]'::jsonb));
      v_ims_current := jsonb_array_length(coalesce(v_current_payload->'ims'->'records','[]'::jsonb));
      v_ims_new := jsonb_array_length(coalesce(p_payload->'ims'->'records','[]'::jsonb));
      v_ims_books_current := jsonb_array_length(coalesce(v_current_payload->'ims'->'books','[]'::jsonb));
      v_ims_books_new := jsonb_array_length(coalesce(p_payload->'ims'->'books','[]'::jsonb));

      if v_two_b_new < v_two_b_current
         or v_books_new < v_books_current
         or v_rcm_new < v_rcm_current
         or v_ims_new < v_ims_current
         or v_ims_books_new < v_ims_books_current then
        raise exception 'Admin permission required to erase company data';
      end if;
    end if;

    v_new := v_current + 1;
    update public.company_snapshots
    set payload=p_payload,revision=v_new,updated_by=auth.uid(),updated_at=now()
    where company_id=p_company_id;
  end if;
  return v_new;
end;
$$;

-- Frozen periods are separate from the editable snapshot. Only company admins can change locks.
create or replace function public.save_period_locks(
  p_company_id uuid,
  p_two_b jsonb,
  p_ims jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  k text;
  v jsonb;
begin
  if auth.uid() is null or not public.is_company_admin(p_company_id) then
    raise exception 'Admin access required';
  end if;

  delete from public.company_period_locks where company_id=p_company_id;

  if jsonb_typeof(coalesce(p_two_b,'{}'::jsonb))='object' then
    for k,v in select key,value from jsonb_each(p_two_b)
    loop
      if k ~ '^\\d{4}-\\d{2}$' then
        insert into public.company_period_locks(company_id,module,period,meta,locked_at,locked_by)
        values(p_company_id,'2B',k,coalesce(v,'{}'::jsonb),now(),auth.uid());
      end if;
    end loop;
  end if;

  if jsonb_typeof(coalesce(p_ims,'{}'::jsonb))='object' then
    for k,v in select key,value from jsonb_each(p_ims)
    loop
      if k ~ '^\\d{4}-\\d{2}$' then
        insert into public.company_period_locks(company_id,module,period,meta,locked_at,locked_by)
        values(p_company_id,'IMS',k,coalesce(v,'{}'::jsonb),now(),auth.uid());
      end if;
    end loop;
  end if;
end;
$$;

-- Explicit grants: only read access to the protected tables from the browser;
-- state writes and lock writes happen through the security-definer RPCs above.
revoke all on public.companies from anon, authenticated;
revoke all on public.company_members from anon, authenticated;
revoke all on public.company_snapshots from anon, authenticated;
revoke all on public.company_period_locks from anon, authenticated;

grant select on public.companies, public.company_members, public.company_snapshots, public.company_period_locks to authenticated;
grant execute on function public.create_company(text,text) to authenticated;
grant execute on function public.save_company_snapshot(uuid,jsonb,bigint) to authenticated;
grant execute on function public.save_period_locks(uuid,jsonb,jsonb) to authenticated;

alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.company_snapshots enable row level security;
alter table public.company_period_locks enable row level security;

drop policy if exists companies_member_select on public.companies;
create policy companies_member_select on public.companies
for select to authenticated using (public.is_company_member(id));

drop policy if exists members_self_or_admin_select on public.company_members;
create policy members_self_or_admin_select on public.company_members
for select to authenticated using (user_id=auth.uid() or public.is_company_admin(company_id));

drop policy if exists snapshot_member_select on public.company_snapshots;
create policy snapshot_member_select on public.company_snapshots
for select to authenticated using (public.is_company_member(company_id));

drop policy if exists locks_member_select on public.company_period_locks;
create policy locks_member_select on public.company_period_locks
for select to authenticated using (public.is_company_member(company_id));

-- Keep helper functions executable by authenticated callers for policy evaluation only;
-- their SQL is constrained by auth.uid().
revoke all on function public.is_company_member(uuid) from public, anon;
grant execute on function public.is_company_member(uuid) to authenticated;
revoke all on function public.is_company_admin(uuid) from public, anon;
grant execute on function public.is_company_admin(uuid) to authenticated;
