-- Allow everyone to read streaks (needed for leaderboard).
-- Keep write operations restricted to the row owner.

drop policy if exists "users own streak" on streaks;

-- Anyone authenticated can read all streaks
create policy "streaks_read_all"
  on streaks for select using (true);

-- Only the owner can insert / update / delete their own streak row
create policy "streaks_own_insert"
  on streaks for insert with check (auth.uid() = user_id);

create policy "streaks_own_update"
  on streaks for update using (auth.uid() = user_id);

create policy "streaks_own_delete"
  on streaks for delete using (auth.uid() = user_id);
