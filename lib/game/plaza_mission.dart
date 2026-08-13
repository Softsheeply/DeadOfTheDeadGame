import 'package:flutter/foundation.dart';

import '../data/mission_catalog.dart';

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

/// Plaza mission progress — titles/goals/triggers from [MissionCatalog].
class PlazaMission {
  PlazaMission(this.catalog) {
    _set(MissionId.marigolds);
  }

  final MissionCatalog catalog;

  final ValueNotifier<String> title = ValueNotifier<String>('');
  final ValueNotifier<String> detail = ValueNotifier<String>('');
  final ValueNotifier<int> progress = ValueNotifier<int>(0);
  final ValueNotifier<int> goal = ValueNotifier<int>(3);
  final ValueNotifier<bool> completedFlash = ValueNotifier<bool>(false);
  final ValueNotifier<int> completedCount = ValueNotifier<int>(0);

  MissionId current = MissionId.marigolds;
  int _progress = 0;
  int _goal = 3;
  bool _completePending = false;

  int get rawProgress => _progress;

  String get currentSetLabel => catalog.isLoaded ? catalog.setLabel(current) : 'Welcome';

  MissionSet get currentSet =>
      catalog.isLoaded && catalog.defFor(current).setId == 'festival'
          ? MissionSet.festival
          : MissionSet.welcome;

  void _set(MissionId id) {
    current = id;
    _progress = 0;
    _completePending = false;
    completedFlash.value = false;
    if (catalog.isLoaded) {
      final def = catalog.defFor(id);
      _goal = def.goal;
      title.value = def.title;
      detail.value = def.detail;
    } else {
      _goal = 3;
      title.value = 'Plaza mission';
      detail.value = 'Explore the festival';
    }
    goal.value = _goal;
    progress.value = 0;
  }

  void restore(MissionId id, int savedProgress) {
    _set(id);
    _progress = savedProgress.clamp(0, _goal);
    progress.value = _progress;
    if (_progress >= _goal) {
      _progress = 0;
      progress.value = 0;
    }
  }

  bool reportOfrendaPetals() => _report('ofrenda_petals');

  bool reportOfrendaTap() => _report('ofrenda_tap');

  bool reportMariachi() => _report('mariachi');

  bool reportXoloFed() => _report('xolo_fed');

  bool reportCandleLit() => _report('candle_lit');

  bool _report(String trigger) {
    if (_completePending || !catalog.isLoaded) return false;
    if (!catalog.defFor(current).triggers.contains(trigger)) return false;
    return _bump();
  }

  bool _bump() {
    _progress = (_progress + 1).clamp(0, _goal);
    progress.value = _progress;
    if (_progress >= _goal) {
      _completePending = true;
      completedFlash.value = true;
      completedCount.value++;
      return true;
    }
    return false;
  }

  void advanceAfterCelebration() {
    completedFlash.value = false;
    _completePending = false;
    final next = catalog.nextId(current);
    _set(next ?? MissionId.marigolds);
  }
}
