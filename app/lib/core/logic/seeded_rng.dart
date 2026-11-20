/// A small deterministic random generator (Mulberry32). The same seed always
/// gives the same sequence on every platform, which a bout replay and the
/// Daily Bout depend on. It uses only 32-bit arithmetic done through masking.
class SeededRng {
  SeededRng(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  int _state;

  /// The next 32 random bits as a non-negative int.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    int t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & _mask;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & _mask)) & _mask;
    return (t ^ (t >> 14)) & _mask;
  }

  /// A uniform int in [0, max). [max] must be positive.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    return (nextUint32() * max) >> 32;
  }

  /// A uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// True with probability [p] (0 to 1).
  bool chance(double p) => nextDouble() < p;

  /// A new generator whose sequence depends on this one's seed state and [label],
  /// so independent streams (AI, effects) never disturb each other.
  SeededRng fork(String label) {
    int h = 0x811C9DC5;
    for (final int unit in label.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & _mask;
    }
    return SeededRng((h ^ _state) & _mask);
  }
}
