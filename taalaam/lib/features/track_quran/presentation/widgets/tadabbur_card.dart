import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/tadabbur_provider.dart';
import '../quran_reader_provider.dart';

class TadabburCard extends ConsumerWidget {
  final String userId;
  const TadabburCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tadabburProvider(userId));

    return async.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return _TadabburCardContent(data: data, userId: userId);
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TadabburCardContent extends ConsumerWidget {
  final TadabburData data;
  final String userId;
  const _TadabburCardContent({required this.data, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientQuranic,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                const Text(
                  'আজকের তাদাব্বুর',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    data.surahNameAr,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${data.surahNameBn} : ${data.ayah}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // ── Ayah text ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                data.ayahAr,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 22,
                  color: Colors.white,
                  height: 2.0,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ),

          // ── Tafsir snippet ────────────────────────────────────────────────
          if (data.tafsirSnippet != null && data.tafsirSnippet!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                data.tafsirSnippet!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.7,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── CTA ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(quranNavProvider.notifier)
                    .restore(data.surah, data.ayah);
                context.go('/quran-reader');
              },
              icon: const Icon(Icons.menu_book_rounded, size: 14,
                  color: AppColors.gold),
              label: const Text(
                'পুরোটা পড়ুন',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.gold, width: 0.8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
