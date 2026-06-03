// supabase/functions/fsrs-notifier/index.ts
// Cron-triggered daily function: finds users with ≥5 decaying SRS cards
// and logs notification payloads. Wire up FCM here when push infra is ready.
// Deploy: supabase functions deploy fsrs-notifier --no-verify-jwt
//
// Schedule via Supabase Dashboard → Edge Functions → Cron:
//   Cron expr: 0 8 * * *  (every day at 08:00 UTC)
//   Or via SQL Editor once pg_cron + pg_net are enabled:
//   select cron.schedule(
//     'daily-fsrs-reminder',
//     '0 8 * * *',
//     $$ select net.http_post(
//       url:='https://xborpnxbdvstiabtevix.supabase.co/functions/v1/fsrs-notifier',
//       headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer <service-role-key>')
//     ) $$
//   );

import { createClient } from 'npm:@supabase/supabase-js@2';

const DECAY_THRESHOLD = 4; // notify users with more than this many due cards

Deno.serve(async (_req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: decayingRecords, error } = await supabase
    .from('v_decaying_srs_cards')
    .select('user_id, display_name, decaying_count')
    .gt('decaying_count', DECAY_THRESHOLD);

  if (error) {
    console.error('[FSRS] View query failed:', error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const notified: { user_id: string; display_name: string; count: number }[] = [];

  for (const row of decayingRecords ?? []) {
    const payload = {
      title: 'মেমোরি ব্যাংক অ্যালার্ট!',
      body: `${row.display_name}, আপনার মেমোরি ব্যাংক থেকে ${row.decaying_count}টি গুরুত্বপূর্ণ শব্দ আজ ভুলে যাওয়ার সম্ভাবনা তৈরি হয়েছে! মাত্র ২ মিনিটের একটি কুইক রিভিউ সেশনের মাধ্যমে শব্দগুলো সতেজ করে নিন।`,
    };

    // TODO: replace console.log with FCM push when Firebase is wired up
    console.log(`[FSRS] ${row.user_id} | ${row.display_name} | ${row.decaying_count} cards | payload: ${payload.body}`);

    notified.push({
      user_id: row.user_id,
      display_name: row.display_name,
      count: row.decaying_count,
    });
  }

  return new Response(
    JSON.stringify({ notified_count: notified.length, users: notified }),
    { headers: { 'Content-Type': 'application/json' }, status: 200 },
  );
});
