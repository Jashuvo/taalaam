// supabase/functions/admin-users/index.ts
// Returns all users with their progress stats for the admin Users page.
// Deploy: supabase functions deploy admin-users --no-verify-jwt

import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = 'jubayedsr@gmail.com';

async function checkAdmin(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json', ...cors } });
  const { data: { user }, error } = await createClient(
    Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!
  ).auth.getUser(token);
  if (error || user?.email !== ADMIN_EMAIL) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { 'Content-Type': 'application/json', ...cors } });
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const denied = await checkAdmin(req); if (denied) return denied;

  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Fetch all auth users (up to 1000)
  const { data: { users: authUsers }, error: authErr } = await sb.auth.admin.listUsers({ perPage: 1000 });
  if (authErr) return new Response(JSON.stringify({ error: authErr.message }), { status: 500, headers: { 'Content-Type': 'application/json', ...cors } });

  const userIds = (authUsers ?? []).map((u: any) => u.id);

  // Fetch streaks and progress in parallel
  // NOTE: 'hearts' lives only in local Drift — not in the Supabase streaks table.
  // Selecting it would cause a PostgREST schema-cache error and null data.
  const [streaksRes, progressRes] = await Promise.all([
    sb.from('streaks').select('user_id, current_streak, longest_streak, total_xp, last_activity_date').in('user_id', userIds),
    sb.from('user_progress').select('user_id').in('user_id', userIds),
  ]);

  const streakMap = new Map((streaksRes.data ?? []).map((s: any) => [s.user_id, s]));
  const completionCount = new Map<string, number>();
  for (const p of (progressRes.data ?? [])) {
    completionCount.set(p.user_id, (completionCount.get(p.user_id) ?? 0) + 1);
  }

  const users = (authUsers ?? []).map((u: any) => {
    const streak = streakMap.get(u.id);
    return {
      id: u.id,
      email: u.email ?? null,
      display_name: u.user_metadata?.full_name ?? u.user_metadata?.name ?? null,
      avatar_url: u.user_metadata?.avatar_url ?? null,
      is_anonymous: u.is_anonymous ?? false,
      provider: u.app_metadata?.provider ?? 'email',
      created_at: u.created_at,
      last_sign_in_at: u.last_sign_in_at ?? null,
      current_streak: streak?.current_streak ?? 0,
      longest_streak: streak?.longest_streak ?? 0,
      total_xp: streak?.total_xp ?? 0,
      last_active: streak?.last_activity_date ?? null,
      lessons_completed: completionCount.get(u.id) ?? 0,
    };
  });

  // Sort: registered first, then by last sign-in descending
  users.sort((a: any, b: any) => {
    if (a.is_anonymous !== b.is_anonymous) return a.is_anonymous ? 1 : -1;
    return new Date(b.last_sign_in_at ?? 0).getTime() - new Date(a.last_sign_in_at ?? 0).getTime();
  });

  return new Response(JSON.stringify({ users, total: users.length }), {
    headers: { 'Content-Type': 'application/json', ...cors },
  });
});
