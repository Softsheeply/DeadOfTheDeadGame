import 'package:flutter/foundation.dart';

/// Lightweight plaza mission progress for the first shippable loop.
enum MissionId { marigolds, mariachi }

class PlazaMission {
  PlazaMission() {
    _set(MissionId.marigolds);
  }

  final ValueNotifier<String> title = ValueNotifier<String>('');
  final ValueNotifier<String> detail = ValueNotifier<String>('');
  final ValueNotifier<int> progress = ValueNotifier<int>(0);
  final ValueNotifier<int> goal = ValueNotifier<int>(3);
  final ValueNotifier<bool> completedFlash = ValueNotifier<bool>(false);

  MissionId current = MissionId.marigolds;
  int _progress = 0;
  int _goal = 3;
  bool _completePending = false;

  void _set(MissionId id) {
    current = id;
    _progress = 0;
    _completePending = false;
    completedFlash.value = false;
    switch (id) {
      case MissionId.marigolds:
        _goal = 3;
        title.value = 'Marigolds for the ofrenda';
        detail.value = 'Send marigold rain onto the tree ofrenda (×3)';
      case MissionId.mariachi:
        _goal = 1;
        title.value = 'Wake the mariachi';
        detail.value = 'Play music so the plaza dances';
    }
    goal.value = _goal;
    progress.value = 0;
  }

  /// Petal toy / burst near the ofrenda tree.
  bool reportOfrendaPetals() {
    if (current != MissionId.marigolds || _completePending) return false;
    return _bump();
  }

  /// Music toy used.
  bool reportMariachi() {
    if (current != MissionId.mariachi || _completePending) return false;
    return _bump();
  }

  bool _bump() {
    _progress = (_progress + 1).clamp(0, _goal);
    progress.value = _progress;
    if (_progress >= _goal) {
      _completePending = true;
      completedFlash.value = true;
      return true;
    }
    return false;
  }

  /// Advance to the next mission after celebration.
  void advanceAfterCelebration() {
    completedFlash.value = false;
    _completePending = false;
    if (current == MissionId.marigolds) {
      _set(MissionId.mariachi);
    } else {
      // Loop soft chores so the plaza always has a little goal.
      _set(MissionId.marigolds);
    }
  }
}
