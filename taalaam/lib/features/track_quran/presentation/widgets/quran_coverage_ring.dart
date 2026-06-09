import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/local/database.dart';
import '../../../../shared/services/progression_service.dart';
import '../../data/quran_coverage_service.dart';

const _milestones = [10.0, 25.0, 50.0, 75.0, 100.0];
const _milestoneXp = 50;
const _milestoneLabels = ['১০%', '২৫%', '৫০%', '৭৫%', '১০০%'];

String _toBengali(String s) {
  const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return s.replaceAllMapped(
      RegExp(r'\d'), (m) => bn[int.parse(m.group(0)!)]);
}

String _pctLabel(double d) => _toBengali(d.toStringAsFixed(1));
String _intLabel(int n) => _toBengali(n.toString());

// ── Ring painter ───────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double sweep; // 0.0–1.0
  final Color bg;
  final Color fg;
  const _RingPainter({required this.sweep, required this.bg, required this.fg});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    final track = Paint()
      ..color = bg
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = fg
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, track);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        sweep * 2 * pi,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep;
}

// ── Coverage ring widget ───────────────────────────────────────────────────────
class QuranCoverageRing extends ConsumerStatefulWidget {
  final String userId;
  const QuranCoverageRing({required this.userId, super.key});

  @override
  ConsumerState<QuranCoverageRing> createState() => _QuranCoverageRingState();
}

class _QuranCoverageRingState extends ConsumerState<QuranCoverageRing> {
  Set<int> _awarded = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAwardedMilestones();
  }

  Future<void> _loadAwardedMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('coverage_milestones_${widget.userId}');
    final awarded = raw?.map(int.parse).toSet() ?? <int>{};
    if (mounted) setState(() { _awarded = awarded; _loaded = true; });
  }

  Future<void> _checkMilestones(double percent) async {
    if (!_loaded) return;
    bool changed = false;
    for (int i = 0; i < _milestones.length; i++) {
      if (percent >= _milestones[i] && !_awarded.contains(i)) {
        _awarded.add(i);
        changed = true;
        final db = ref.read(appDatabaseProvider);
        await ProgressionService(db).awardBonusXp(widget.userId, _milestoneXp);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'মাইলফলক! +${_toBengali("$_milestoneXp")} XP — '
                'কুরআনের ${_milestoneLabels[i]} শব্দ কভার করা হয়েছে'),
            backgroundColor: AppColors.forestGreen,
          ));
        }
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'coverage_milestones_${widget.userId}',
          _awarded.map((e) => e.toString()).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverageAsync = ref.watch(quranCoverageProvider(widget.userId));

    ref.listen<AsyncValue<CoverageResult>>(
        quranCoverageProvider(widget.userId), (_, next) {
      next.whenData((r) => _checkMilestones(r.percent));
    });

    return coverageAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) => _buildRing(context, result),
    );
  }

  Widget _buildRing(BuildContext context, CoverageResult result) {
    final sweep = result.percent / 100;
    return GestureDetector(
      onTap: () => _showDetail(context, result),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: sweep),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _RingPainter(
                      sweep: value,
                      bg: AppColors.brightGreen.withValues(alpha: 0.2),
                      fg: AppColors.brightGreen,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _pctLabel(result.percent),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightGreen,
                            ),
                          ),
                          const Text(
                            '%',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.brightGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কুরআন কভারেজ',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.brightGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_intLabel(result.knownCount)} / ${_intLabel(result.totalCount)} টোকেন',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brightGreen.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'বিস্তারিত দেখতে ট্যাপ করুন',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brightGreen.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, CoverageResult result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _CoverageDetailSheet(result: result),
    );
  }
}

// ── Detail bottom sheet ────────────────────────────────────────────────────────
class _CoverageDetailSheet extends StatelessWidget {
  final CoverageResult result;
  const _CoverageDetailSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('কুরআন কভারেজ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 16),
          Text(
            '${_pctLabel(result.percent)}%',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: AppColors.brightGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আপনি ${_intLabel(result.knownCount)} টি কুরআনিক শব্দ-টোকেন চেনেন',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            '(মোট ${_intLabel(result.totalCount)} টোকেনের মধ্যে)',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'FSRS state ≥ ২ অথবা ≥ ৭ দিনের interval সহ\nশব্দগুলোকে "জানা" হিসেবে গণ্য করা হয়েছে।',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'মাইলফলক: ${_milestoneLabels.join(" · ")} — প্রতিটিতে +${_toBengali("$_milestoneXp")} XP',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
