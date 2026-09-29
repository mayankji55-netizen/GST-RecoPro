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

