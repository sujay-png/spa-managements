-- ============================================================================
-- UNDO Ira Spa payments SQL in the WRONG project.
-- Only drops objects that exactly match what the spa script created.
-- Your project's own invoice tables are detected and kept.
-- Read the NOTICE messages in the output to see what happened.
-- ============================================================================
do $$
declare
  v_cols text;
  v_left int;
  -- exact column sets created by the spa script
  c_invoices text := 'booking_id,business_ref,cgst,created_at,customer_name,customer_phone,discount,gst_rate,id,invoice_number,items,notes,paid_at,payment_method,payment_ref,payment_status,round_off,service_date,sgst,subtotal,taxable_amount,therapist,total,updated_at';
  c_settings text := 'address,business_name,business_ref,default_gst_rate,email,footer_note,gst_inclusive,gstin,invoice_prefix,phone,sac_code,updated_at,upi_id,upi_payee_name';
  c_counters text := 'business_ref,fiscal_year,last_number';
  r record;
  v_name text;
begin
  for r in select * from (values
      ('invoices', c_invoices, 'invoices business access'),
      ('billing_settings', c_settings, 'billing_settings business access'),
      ('invoice_counters', c_counters, null)
    ) as t(tbl, cols, pol)
  loop
    if to_regclass('public.' || r.tbl) is null then
      raise notice '% : not present, nothing to do', r.tbl;
      continue;
    end if;

    select string_agg(column_name, ',' order by column_name) into v_cols
    from information_schema.columns
    where table_schema = 'public' and table_name = r.tbl;

    if v_cols = r.cols then
      execute format('drop table public.%I cascade', r.tbl);
      raise notice '% : created by spa script -> DROPPED', r.tbl;
    else
      -- Pre-existing table of this project: keep it, only remove what we added.
      if r.pol is not null then
        execute format('drop policy if exists %I on public.%I', r.pol, r.tbl);
        select count(*) into v_left from pg_policies
        where schemaname = 'public' and tablename = r.tbl;
        if v_left = 0 then
          -- it had no policies of its own, so RLS was off before our script
          execute format('alter table public.%I disable row level security', r.tbl);
          raise notice '% : YOUR table kept; removed spa policy and turned RLS back off', r.tbl;
        else
          raise notice '% : YOUR table kept; removed spa policy (your % policies untouched)', r.tbl, v_left;
        end if;
      else
        raise notice '% : YOUR table kept untouched', r.tbl;
      end if;
      execute format('drop trigger if exists %I on public.%I',
                     case r.tbl when 'invoices' then 'invoices_touch'
                                when 'billing_settings' then 'billing_settings_touch'
                                else 'none_x' end, r.tbl);
    end if;
  end loop;

  -- Functions: drop only if the body is ours
  for r in
    select p.oid::regprocedure as sig, p.prosrc
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('next_invoice_number', 'current_business_ref', 'touch_updated_at')
  loop
    if r.prosrc ilike '%invoice_counters%'
       or r.prosrc ilike '%userbusinessref%'
       or r.prosrc ilike '%user_businessRef%'
       or btrim(regexp_replace(r.prosrc, '\s+', ' ', 'g')) = 'begin new.updated_at = now(); return new; end'
    then
      v_name := r.sig::text;
      begin
        execute format('drop function %s', v_name);
        raise notice 'function % : spa version -> DROPPED', v_name;
      exception when dependent_objects_still_exist then
        raise notice 'function % : still used by your own triggers -> kept', v_name;
      end;
    else
      raise notice 'function % : YOUR function -> kept', r.sig::text;
    end if;
  end loop;
end $$;
