import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _clearing = false;

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear All Content?',
      body: 'This will permanently delete ALL units, lessons, exercises, '
          'vocabulary, and source materials from the database.\n\nThis cannot be undone.',
      confirmLabel: 'Delete Everything',
      cancelLabel: 'Cancel',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _clearing = true);
    try {
      await Supabase.instance.client.rpc('admin_clear_all_content');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All content deleted successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Ta'allam — لوحة التحكم"),
        backgroundColor: theme.colorScheme.primaryContainer,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _clearing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting all content…'),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(Icons.mosque_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Content Management',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Quick links ──────────────────────────────────────
                    _AdminActionCard(
                      icon: Icons.upload_file_outlined,
                      title: 'Upload Content',
                      subtitle: 'PDF, text, or image → AI lesson generation',
                      onTap: () => context.go('/admin/upload'),
                    ),
                    const SizedBox(height: 12),
                    _AdminActionCard(
                      icon: Icons.rate_review_outlined,
                      title: 'Review Drafts',
                      subtitle: 'Edit and publish AI-generated lessons',
                      onTap: () => context.go('/admin/review'),
                    ),
                    const SizedBox(height: 20),

                    // ── Quranic curriculum ───────────────────────────────
                    const _QuranCurriculumSection(),
                    const SizedBox(height: 20),

                    // ── Danger zone ──────────────────────────────────────
                    _AdminActionCard(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Clear All Content',
                      subtitle: 'Delete all units, lessons, exercises & vocabulary',
                      onTap: _confirmAndClearAll,
                      danger: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Arabic rendering test ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text('Arabic rendering test:', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'هُوَ أُسْتَاذٌ جَدِيدٌ',
                              style: TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 22,
                                height: 1.8,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Quranic curriculum section ───────────────────────────────────────────────

class _QuranCurriculumSection extends StatelessWidget {
  const _QuranCurriculumSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 18, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              Text(
                'কুরআনিক পাঠ কারিকুলাম',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _UnitCurationCard(
          unitIndex: 1,
          title: 'সালাতের ভাষা',
          subtitle: '৪ পাঠ — প্রতিদিন ১৭ বার পঠিত সূরা',
          color: const Color(0xFF1565C0),
          icon: Icons.mosque_outlined,
          child: _SalahUnitControls(),
        ),
        const SizedBox(height: 8),
        _UnitCurationCard(
          unitIndex: 2,
          title: 'সবচেয়ে বেশি ব্যবহৃত শব্দ',
          subtitle: '৫ পাঠ — কুরআনের ৫০% শব্দ শিখুন',
          color: const Color(0xFF6A1B9A),
          icon: Icons.bar_chart_outlined,
          child: _FrequentWordsControls(),
        ),
        const SizedBox(height: 8),
        _UnitCurationCard(
          unitIndex: 3,
          title: 'আল্লাহর গুণাবলী',
          subtitle: '৪ পাঠ — রহমত · জ্ঞান · শক্তি · রাজত্ব',
          color: const Color(0xFFE65100),
          icon: Icons.star_outline,
          child: _AttributesControls(),
        ),
        const SizedBox(height: 8),
        _UnitCurationCard(
          unitIndex: 4,
          title: 'জুয আম্মার সূরা',
          subtitle: 'যেকোনো সূরা থেকে পাঠ তৈরি করুন',
          color: AppColors.forestGreen,
          icon: Icons.menu_book_outlined,
          child: _JuzAmmaControls(),
        ),
        const SizedBox(height: 8),
        _UnitCurationCard(
          unitIndex: 5,
          title: 'কুরআনের ক্রিয়াপদ',
          subtitle: '৫ পাঠ — শিকড়ভিত্তিক ক্রিয়া শিক্ষা',
          color: const Color(0xFF00695C),
          icon: Icons.timeline_outlined,
          child: _VerbsControls(),
        ),
      ],
    );
  }
}

// ── Collapsible unit card ─────────────────────────────────────────────────────

class _UnitCurationCard extends StatelessWidget {
  final int unitIndex;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Widget child;

  const _UnitCurationCard({
    required this.unitIndex,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Unit $unitIndex',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
          ),
          children: [child],
        ),
      ),
    );
  }
}

// ── Helper: curate button ─────────────────────────────────────────────────────

Future<void> _callCurate({
  required BuildContext ctx,
  required Map<String, dynamic> body,
  required String successMsg,
}) async {
  try {
    final res = await Supabase.instance.client.functions
        .invoke('curate-quran-lesson', body: body);
    final err = res.data?['error'] as String?;
    if (err != null) throw Exception(err);
    final exErr = res.data?['exercise_error'] as String?;
    if (ctx.mounted) {
      final msg = exErr != null ? '$successMsg (exercises failed: $exErr)' : successMsg;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: exErr != null ? Colors.orange : Colors.green,
      ));
    }
  } catch (e) {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── Unit 1: Salah ─────────────────────────────────────────────────────────────

class _SalahUnitControls extends StatefulWidget {
  @override
  State<_SalahUnitControls> createState() => _SalahUnitControlsState();
}

class _SalahUnitControlsState extends State<_SalahUnitControls> {
  static const _salahs = [
    (number: 1,   nameBn: 'আল-ফাতিহা'),
    (number: 112, nameBn: 'আল-ইখলাস'),
    (number: 108, nameBn: 'আল-কাওসার'),
    (number: 103, nameBn: 'আল-আসর'),
  ];
  int? _busy;

  Future<void> _curate(int surahNumber, String nameBn) async {
    setState(() => _busy = surahNumber);
    await _callCurate(
      ctx: context,
      body: {'unit_type': 'salah', 'surah_number': surahNumber},
      successMsg: 'সূরা $nameBn পাঠ তৈরি হয়েছে ✓',
    );
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _salahs.map((s) => FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _busy != null ? null : () => _curate(s.number, s.nameBn),
        child: _busy == s.number
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(s.nameBn, style: const TextStyle(fontSize: 13)),
      )).toList(),
    );
  }
}

// ── Unit 2: Frequent words ────────────────────────────────────────────────────

class _FrequentWordsControls extends StatefulWidget {
  @override
  State<_FrequentWordsControls> createState() => _FrequentWordsControlsState();
}

class _FrequentWordsControlsState extends State<_FrequentWordsControls> {
  int? _busyIndex;

  Future<void> _curate(int lessonIndex) async {
    setState(() => _busyIndex = lessonIndex);
    final start = lessonIndex * 20 + 1;
    final end   = start + 19;
    await _callCurate(
      ctx: context,
      body: {'unit_type': 'frequent', 'lesson_index': lessonIndex},
      successMsg: 'পাঠ ${lessonIndex + 1} ($start–$end) তৈরি হয়েছে ✓',
    );
    if (mounted) setState(() => _busyIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(5, (i) {
        final label = 'পাঠ ${i + 1} (${i * 20 + 1}–${i * 20 + 20})';
        return FilledButton.tonal(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _busyIndex != null ? null : () => _curate(i),
          child: _busyIndex == i
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label, style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}

// ── Unit 3: Allah's Attributes ────────────────────────────────────────────────

class _AttributesControls extends StatefulWidget {
  @override
  State<_AttributesControls> createState() => _AttributesControlsState();
}

class _AttributesControlsState extends State<_AttributesControls> {
  static const _themes = [
    'রহমত ও ক্ষমা',
    'জ্ঞান ও প্রজ্ঞা',
    'শক্তি ও ক্ষমতা',
    'রাজত্ব ও মহত্ত্ব',
  ];
  int? _busyIndex;

  Future<void> _curate(int lessonIndex) async {
    setState(() => _busyIndex = lessonIndex);
    await _callCurate(
      ctx: context,
      body: {'unit_type': 'attributes', 'lesson_index': lessonIndex},
      successMsg: '"${_themes[lessonIndex]}" পাঠ তৈরি হয়েছে ✓',
    );
    if (mounted) setState(() => _busyIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(_themes.length, (i) => FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _busyIndex != null ? null : () => _curate(i),
        child: _busyIndex == i
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_themes[i], style: const TextStyle(fontSize: 12)),
      )),
    );
  }
}

// ── Unit 4: Juz Amma (surah picker) ──────────────────────────────────────────

class _JuzAmmaControls extends StatefulWidget {
  @override
  State<_JuzAmmaControls> createState() => _JuzAmmaControlsState();
}

class _JuzAmmaControlsState extends State<_JuzAmmaControls> {
  bool _loading   = false;
  bool _busy      = false;
  int? _selected;
  List<Map<String, dynamic>> _surahs = [];

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('quran_surahs')
          .select('number, name_bn')
          .gte('number', 78)
          .order('number') as List;
      if (mounted) {
        setState(() {
          _surahs = rows.cast<Map<String, dynamic>>();
          if (_surahs.isNotEmpty) _selected = _surahs.first['number'] as int;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _curate() async {
    if (_selected == null) return;
    final name = _surahs
        .where((s) => s['number'] == _selected)
        .firstOrNull?['name_bn'] as String? ?? '$_selected';
    setState(() => _busy = true);
    await _callCurate(
      ctx: context,
      body: {'unit_type': 'juz_amma', 'surah_number': _selected},
      successMsg: 'সূরা $name পাঠ তৈরি হয়েছে ✓',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _selected,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: _surahs.map((s) {
              final n    = s['number'] as int;
              final name = s['name_bn'] as String? ?? '$n';
              return DropdownMenuItem(value: n, child: Text('$n. $name', style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: _busy ? null : (v) { if (v != null) setState(() => _selected = v); },
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: _busy ? null : _curate,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('তৈরি করুন'),
        ),
      ],
    );
  }
}

// ── Unit 5: Quranic Verbs ─────────────────────────────────────────────────────

class _VerbsControls extends StatefulWidget {
  @override
  State<_VerbsControls> createState() => _VerbsControlsState();
}

class _VerbsControlsState extends State<_VerbsControls> {
  int? _busyIndex;

  Future<void> _curate(int lessonIndex) async {
    setState(() => _busyIndex = lessonIndex);
    await _callCurate(
      ctx: context,
      body: {'unit_type': 'verbs', 'lesson_index': lessonIndex},
      successMsg: 'ক্রিয়া পাঠ ${lessonIndex + 1} তৈরি হয়েছে ✓',
    );
    if (mounted) setState(() => _busyIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
          ),
          child: const Text(
            '⚠ প্রথমে enrich_quran_roots.ts স্ক্রিপ্ট চালান — verb root ডেটা ছাড়া পাঠ তৈরি হবে না।',
            style: TextStyle(fontSize: 12),
          ),
        ),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(5, (i) => FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _busyIndex != null ? null : () => _curate(i),
            child: _busyIndex == i
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('ক্রিয়া পাঠ ${i + 1}', style: const TextStyle(fontSize: 12)),
          )),
        ),
      ],
    );
  }
}

// ── Shared admin action card ──────────────────────────────────────────────────

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final iconBg      = danger ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final iconColor   = danger ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;
    final borderColor = danger
        ? theme.colorScheme.error.withValues(alpha: 0.4)
        : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: danger ? theme.colorScheme.error : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
