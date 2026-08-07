import 'package:flutter/foundation.dart';

/// Lightweight plaza mission progress for the soft-launch loop.
enum MissionId { marigolds, mariachi, feedXolo, candles }

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

  int get rawProgress => _progress;

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
      case MissionId.feedXolo:
        _goal = 1;
        title.value = 'Treat for Xolo';
        detail.value = 'Drop pan dulce and let Xolo claim it';
      case MissionId.candles:
        _goal = 5;
        title.value = 'Wake the candles';
        detail.value = 'Tap night candles around the plaza (×5)';
    }
    goal.value = _goal;
    progress.value = 0;
  }

  /// Restore from save. Progress is clamped; completed state is not restored mid-flash.
  void restore(MissionId id, int savedProgress) {
    _set(id);
    _progress = savedProgress.clamp(0, _goal);
    progress.value = _progress;
    if (_progress >= _goal) {
      // Avoid locking on a finished mission after relaunch.
      _progress = 0;
      progress.value = 0;
    }
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

  /// Xolo claimed pan dulce.
  bool reportXoloFed() {
    if (current != MissionId.feedXolo || _completePending) return false;
    return _bump();
  }

  /// Player lit a candle / lantern.
  bool reportCandleLit() {
    if (current != MissionId.candles || _completePending) return false;
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
    switch (current) {
      case MissionId.marigolds:
        _set(MissionId.mariachi);
      case MissionId.mariachi:
        _set(MissionId.feedXolo);
      case MissionId.feedXolo:
        _set(MissionId.candles);
      case MissionId.candles:
        _set(MissionId.marigolds);
    }
  }
}
