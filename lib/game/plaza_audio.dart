import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Soft plaza bed + toy stingers. Fails soft if audio can't load (CI / mute HW).
class PlazaAudio {
  PlazaAudio();

  bool enabled = true;
  bool _ready = false;
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  static const bed = 'plaza_bed.wav';
  static const wind = 'sfx_wind.wav';
  static const petals = 'sfx_petals.wav';
  static const music = 'sfx_music.wav';
  static const treat = 'sfx_treat.wav';
  static const mission = 'sfx_mission.wav';

  Future<void> load() async {
    try {
      await FlameAudio.audioCache.loadAll([
        bed,
        wind,
        petals,
        music,
        treat,
        mission,
      ]);
      _ready = true;
      if (enabled && !muted.value) {
        await FlameAudio.bgm.play(bed, volume: 0.28);
      }
    } catch (_) {
      _ready = false;
    }
  }

  void toggleMute() {
    muted.value = !muted.value;
    if (!_ready) return;
    if (muted.value) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
      // If bed never started, try again.
      if (enabled) {
        FlameAudio.bgm.play(bed, volume: 0.28);
      }
    }
  }

  Future<void> setMuted(bool value) async {
    if (muted.value == value) return;
    muted.value = value;
    if (!_ready) return;
    if (muted.value) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
      if (enabled) {
        FlameAudio.bgm.play(bed, volume: 0.28);
      }
    }
  }

  void playSfx(String file, {double volume = 0.55}) {
    if (!_ready || muted.value || !enabled) return;
    try {
      FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }

  void windSfx() => playSfx(wind, volume: 0.45);
  void petalsSfx() => playSfx(petals, volume: 0.5);
  void musicSfx() => playSfx(music, volume: 0.55);
  void treatSfx() => playSfx(treat, volume: 0.5);
  void missionSfx() => playSfx(mission, volume: 0.6);
  void grabSfx() => playSfx(treat, volume: 0.35);
  void dropSfx({bool flung = false}) =>
      playSfx(flung ? wind : petals, volume: flung ? 0.4 : 0.35);

  Future<void> dispose() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }
}
