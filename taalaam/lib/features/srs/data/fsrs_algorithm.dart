import 'dart:math';

// FSRS-4.5 algorithm — default weights from paper
// Ratings: 1=Again, 2=Hard, 3=Good, 4=Easy
class FsrsAlgorithm {
  static const _w = [
    0.4072, 1.1829, 3.1262, 15.4722, // S_0 per rating
    7.2102, 0.5316, 1.0651, 0.0589, // D_0 params
    1.5330, 0.1544, 1.0071, 1.9239, // S_r params
    0.1100, 0.2900, 2.2700, 0.2500, // S_f params
    2.9898, // D_decay
  ];
  static const _desiredRetention = 0.9;

  // Called when a new card is first rated
  static ({double stability, double difficulty, int interval}) initCard(
      int rating) {
    assert(rating >= 1 && rating <= 4);
    final s = _w[rating - 1]; // S_0
    final d = (_w[4] - exp(_w[5] * (rating - 1)) + 1).clamp(1.0, 10.0);
    final interval = _nextInterval(s);
    return (stability: s, difficulty: d, interval: interval);
  }

  // Called on each subsequent review
  static ({double stability, double difficulty, int interval}) review({
    required double stability,
    required double difficulty,
    required int elapsedDays,
    required int rating,
    required int state, // 0=new,1=learning,2=review,3=relearning
  }) {
    assert(rating >= 1 && rating <= 4);
    final r = _retrievability(stability, elapsedDays.toDouble());
    late double newS;
    late double newD;

    if (rating >= 3) {
      // Successful recall
      newS = stability *
          (exp(_w[8]) *
              (11 - difficulty) *
              pow(stability, -_w[7]) *
              (exp(_w[8] * (1 - r)) - 1) *
              _ratingFactor(rating) +
              1);
    } else {
      // Forgotten
      newS = _w[11] *
          pow(difficulty, -_w[12]) *
          (pow(stability + 1, _w[13]) - 1) *
          exp(_w[14] * (1 - r));
    }
    newS = newS.clamp(0.1, 365.0 * 10);

    // Difficulty update
    newD = (difficulty +
            _w[6] * (rating - 3) * (1 - exp(-_w[16] * (difficulty - 1))))
        .clamp(1.0, 10.0);

    return (
      stability: newS,
      difficulty: newD,
      interval: _nextInterval(newS),
    );
  }

  static double _retrievability(double s, double t) =>
      pow(1 + t / (9 * s), -1).toDouble();

  static int _nextInterval(double stability) {
    final i = stability * 9 * (1 / _desiredRetention - 1);
    return i.round().clamp(1, 365 * 10);
  }

  static double _ratingFactor(int rating) {
    if (rating == 2) return _w[15];
    if (rating == 4) return _w[16];
    return 1.0;
  }
}
