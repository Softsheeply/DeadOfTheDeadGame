import 'package:flutter/foundation.dart';

/// Lightweight plaza mission progress — two looping chore sets.
enum MissionId {
  marigolds,
  mariachi,
  feedXolo,
  candles,
  stageEncore,
  candlePath,
  treatRound,
  ofrendaTribute,
}

enum MissionSet { welcome, festival }

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

  MissionSet get currentSet => switch (current) {
        MissionId.marigolds ||
        MissionId.mariachi ||
        MissionId.feedXolo ||
        MissionId.candles =>
          MissionSet.welcome,
        _ => MissionSet.festival,
      };

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
      case MissionId.stageEncore:
        _goal = 2;
        title.value = 'Encore at the stage';
        detail.value = 'Play music twice for the plaza (×2)';
      case MissionId.candlePath:
        _goal = 8;
        title.value = 'Light the candle path';
        detail.value = 'Tap candles until the whole rim glows (×8)';
      case MissionId.treatRound:
        _goal = 2;
        title.value = 'Treat round';
        detail.value = 'Drop pan dulce twice — share the sweets (×2)';
      case MissionId.ofrendaTribute:
        _goal = 3;
        title.value = 'Honor the ofrenda';
        detail.value = 'Tap the tree ofrenda to leave marigolds (×3)';
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
      _progress = 0;
      progress.value = 0;
    }
  }

  bool reportOfrendaPetals() {
    if (_completePending) return false;
    if (current == MissionId.marigolds) return _bump();
    return false;
  }

  bool reportOfrendaTap() {
    if (_completePending) return false;
    if (current == MissionId.ofrendaTribute) return _bump();
    return false;
  }

  bool reportMariachi() {
    if (_completePending) return false;
    if (current == MissionId.mariachi || current == MissionId.stageEncore) {
      return _bump();
    }
    return false;
  }

  bool reportXoloFed() {
    if (_completePending) return false;
    if (current == MissionId.feedXolo || current == MissionId.treatRound) {
      return _bump();
    }
    return false;
  }

  bool reportCandleLit() {
    if (_completePending) return false;
    if (current == MissionId.candles || current == MissionId.candlePath) {
      return _bump();
    }
    return false;
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
        _set(MissionId.stageEncore);
      case MissionId.stageEncore:
        _set(MissionId.candlePath);
      case MissionId.candlePath:
        _set(MissionId.treatRound);
      case MissionId.treatRound:
        _set(MissionId.ofrendaTribute);
      case MissionId.ofrendaTribute:
        _set(MissionId.marigolds);
    }
  }
}
