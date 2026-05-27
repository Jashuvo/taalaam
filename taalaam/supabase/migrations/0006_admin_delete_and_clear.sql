-- Admin DELETE policies for units and lessons (were missing — caused silent failures)
create policy "admin can delete units" on units for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

create policy "admin can delete lessons" on lessons for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- Security-definer RPC so admin can wipe everything in one call
-- Runs as table owner → bypasses RLS → guaranteed to work
create or replace function admin_clear_all_content()
returns void
language plpgsql
security definer
as $$
begin
  if (auth.jwt() ->> 'email') != 'jubayedsr@gmail.com' then
    raise exception 'Not authorized';
  end if;
  delete from exercises       where true;
  delete from vocabulary      where true;
  delete from lessons         where true;
  delete from units           where true;
  delete from source_materials where true;
end;
$$;
