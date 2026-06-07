class XpLevel {
  final int level;
  final String nameAr;
  final String nameBn;
  final int minXp;
  final int maxXp; // -1 = no cap (final level)

  const XpLevel._({
    required this.level,
    required this.nameAr,
    required this.nameBn,
    required this.minXp,
    required this.maxXp,
  });

  static const _levels = [
    XpLevel._(level: 1, nameAr: 'مبتدئ', nameBn: 'শিক্ষানবিশ', minXp: 0, maxXp: 200),
    XpLevel._(level: 2, nameAr: 'متعلم', nameBn: 'শিক্ষার্থী', minXp: 200, maxXp: 500),
    XpLevel._(level: 3, nameAr: 'طالب', nameBn: 'ছাত্র', minXp: 500, maxXp: 1000),
    XpLevel._(level: 4, nameAr: 'حافظ', nameBn: 'হাফেজ', minXp: 1000, maxXp: 2000),
    XpLevel._(level: 5, nameAr: 'عالم', nameBn: 'আলেম', minXp: 2000, maxXp: -1),
  ];

  static XpLevel forXp(int xp) =>
      _levels.lastWhere((l) => xp >= l.minXp, orElse: () => _levels.first);

  double progressFraction(int xp) {
    if (maxXp == -1) return 1.0;
    final range = maxXp - minXp;
    if (range <= 0) return 1.0;
    return ((xp - minXp) / range).clamp(0.0, 1.0);
  }

  int xpToNext(int xp) {
    if (maxXp == -1) return 0;
    return (maxXp - xp).clamp(0, maxXp - minXp);
  }
}
