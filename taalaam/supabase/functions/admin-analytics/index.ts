// supabase/functions/admin-analytics/index.ts
// Returns dashboard statistics for the admin CMS.
// Deploy: supabase functions deploy admin-analytics --no-verify-jwt

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

  // ── Content counts ─────────────────────────────────────────────────────
  const [unitsRes, lessonsRes, exercisesRes, vocabRes, tracksRes] = await Promise.all([
    sb.from('units').select('status, track_id, tier_level'),
    sb.from('lessons').select('status, unit_id'),
    sb.from('exercises').select('id', { count: 'exact', head: true }),
    sb.from('vocabulary').select('id', { count: 'exact', head: true }),
    sb.from('tracks').select('id, slug, name_bn').order('sort_order'),
  ]);

  const units: any[] = unitsRes.data ?? [];
  const lessons: any[] = lessonsRes.data ?? [];
  const tracks: any[] = tracksRes.data ?? [];

  const publishedUnits = units.filter(u => u.status === 'published').length;
  const draftUnits     = units.filter(u => u.status === 'draft').length;
  const publishedLess  = lessons.filter(l => l.status === 'published').length;
  const draftLess      = lessons.filter(l => l.status === 'draft').length;

  // Per-track breakdown
  const trackStats = tracks.map((t: any) => {
    const tUnits   = units.filter(u => u.track_id === t.id);
    const tUnitIds = new Set(tUnits.map((u: any) => u.id));
    // lessons join through units — we don't have unit_id on lessons easily here
    // so just count units per track
    return {
      slug: t.slug,
      name_bn: t.name_bn,
      units_published: tUnits.filter(u => u.status === 'published').length,
      units_draft: tUnits.filter(u => u.status === 'draft').length,
    };
  });

  // Tier distribution
  const tierDist: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0 };
  for (const u of units) {
    const t = u.tier_level ?? 1;
    tierDist[t] = (tierDist[t] ?? 0) + 1;
  }

  // ── Learner stats ──────────────────────────────────────────────────────
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const [streaksRes, progressRes, recentRes, monthRes] = await Promise.all([
    sb.from('streaks').select('user_id, current_streak, longest_streak, total_xp, hearts'),
    sb.from('user_progress').select('user_id, lesson_id, completed_at', { count: 'exact' }),
    sb.from('user_progress').select('user_id').gte('completed_at', sevenDaysAgo),
    sb.from('user_progress').select('user_id').gte('completed_at', thirtyDaysAgo),
  ]);

  const streaks: any[] = streaksRes.data ?? [];
  const progress: any[] = progressRes.data ?? [];
  const recent: any[] = recentRes.data ?? [];
  const monthly: any[] = monthRes.data ?? [];

  const active7d  = new Set(recent.map((p: any) => p.user_id)).size;
  const active30d = new Set(monthly.map((p: any) => p.user_id)).size;
  const avgStreak = streaks.length ? Math.round(streaks.reduce((s, r) => s + (r.current_streak ?? 0), 0) / streaks.length) : 0;
  const maxStreak = streaks.reduce((m, r) => Math.max(m, r.current_streak ?? 0), 0);
  const totalXp   = streaks.reduce((s, r) => s + (r.total_xp ?? 0), 0);

  // ── Top lessons ────────────────────────────────────────────────────────
  const lessonCounts = new Map<string, number>();
  for (const row of progress) {
    lessonCounts.set(row.lesson_id, (lessonCounts.get(row.lesson_id) ?? 0) + 1);
  }

  const topIds = [...lessonCounts.entries()]
    .sort(([, a], [, b]) => b - a)
    .slice(0, 6)
    .map(([id]) => id);

  let topLessons: any[] = [];
  if (topIds.length > 0) {
    const { data } = await sb.from('lessons').select('id, title_bn').in('id', topIds);
    topLessons = (data ?? []).map((l: any) => ({
      id: l.id,
      title_bn: l.title_bn,
      completions: lessonCounts.get(l.id) ?? 0,
    })).sort((a: any, b: any) => b.completions - a.completions);
  }

  // ── Auth users (registered vs anonymous) ──────────────────────────────
  const { data: { users: authUsers } } = await sb.auth.admin.listUsers({ perPage: 1000 });
  const registeredCount = (authUsers ?? []).filter((u: any) => !u.is_anonymous && u.email).length;
  const anonymousCount  = (authUsers ?? []).filter((u: any) => u.is_anonymous).length;

  const result = {
    content: {
      units_published: publishedUnits,
      units_draft: draftUnits,
      lessons_published: publishedLess,
      lessons_draft: draftLess,
      exercises_total: exercisesRes.count ?? 0,
      vocabulary_total: vocabRes.count ?? 0,
      tier_distribution: tierDist,
      tracks: trackStats,
    },
    learners: {
      total: streaks.length,
      registered: registeredCount,
      anonymous: anonymousCount,
      active_7d: active7d,
      active_30d: active30d,
      total_completions: progressRes.count ?? 0,
      avg_streak: avgStreak,
      max_streak: maxStreak,
      total_xp: totalXp,
    },
    top_lessons: topLessons,
  };

  return new Response(JSON.stringify(result), {
    headers: { 'Content-Type': 'application/json', ...cors },
  });
});
