-- Schedule fsrs-notifier edge function to run daily at 08:00 UTC.
-- Requires pg_cron and pg_net extensions (both enabled by default on Supabase).
--
-- Run this once in the Supabase SQL Editor.
-- Replace <YOUR_SERVICE_ROLE_KEY> with the value from:
--   Supabase Dashboard → Project Settings → API → service_role (secret)
--
-- Alternatively, set it up in the Dashboard UI:
--   Edge Functions → fsrs-notifier → Schedules → Add schedule → 0 8 * * *

select cron.schedule(
  'daily-fsrs-reminder',
  '0 8 * * *',
  $$
  select net.http_post(
    url     := 'https://xborpnxbdvstiabtevix.supabase.co/functions/v1/fsrs-notifier',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer <YOUR_SERVICE_ROLE_KEY>'
    ),
    body    := '{}'::jsonb
  ) as request_id;
  $$
);
