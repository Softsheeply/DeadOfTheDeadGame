import 'dart:convert';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/character_config.dart';
import 'petal_burst.dart';
import 'resident.dart';
import 'toys.dart';
import 'village_backdrop.dart';

enum VillageToy { wind, petals, music, panDulce }

/// Spirit Village -- living Día de los Muertos plaza with Pocket God toys.
class SpiritVillageGame extends FlameGame {
  final List<Resident> residents = [];
  VillageBackdrop? backdrop;
  PanDulceTreat? activeTreat;
  bool _residentsReady = false;
  bool musicPlaying = false;
  double _musicTimer = 0;
  final Random _random = Random();
  final ValueNotifier<bool> isNight = ValueNotifier<bool>(true);
  final ValueNotifier<String> toyStatus = ValueNotifier<String>('');

  Resident? get xolo {
    for (final r in residents) {
      if (r.config.id == 'xolo') return r;
    }
    return null;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = VillageBackdrop(size: size.clone());
    await add(backdrop!);

    await _spawnResident(
      assetPath: 'assets/images/pepita/character.json',
      position: Vector2(size.x * 0.38, size.y * 0.78),
      displaySize: Vector2(128, 128),
    );
    await _spawnResident(
      assetPath: 'assets/images/abuela_rosa/character.json',
      position: Vector2(size.x * 0.58, size.y * 0.82),
      displaySize: Vector2(128, 128),
    );
    await _spawnResident(
      assetPath: 'assets/images/xolo/character.json',
      position: Vector2(size.x * 0.48, size.y * 0.86),
      displaySize: Vector2(96, 96),
    );

    _residentsReady = true;
  }

  Future<void> _spawnResident({
    required String assetPath,
    required Vector2 position,
    required Vector2 displaySize,
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final config = CharacterConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
    final resident = Resident(config: config, position: position)
      ..size = displaySize
      ..worldBounds = size.clone()
      ..onPetalBurst = (pos, {int count = 14}) => spawnPetals(pos, count: count);
    residents.add(resident);
    await add(resident);
  }

  void spawnPetals(Vector2 position, {int count = 14}) {
    add(PetalBurst(position: position, count: count));
  }

  void toggleDayNight() {
    backdrop?.toggleDayNight();
    isNight.value = backdrop?.isNight ?? true;
    toyStatus.value = isNight.value ? 'Night settles over the plaza' : 'Morning light fills the plaza';
  }

  void useToy(VillageToy toy) {
    switch (toy) {
      case VillageToy.wind:
        _castWind();
      case VillageToy.petals:
        _castPetalRain();
      case VillageToy.music:
        _castMusic();
      case VillageToy.panDulce:
        _castPanDulce();
    }
  }

  void _castWind() {
    add(WindGust(size: size.clone()));
    final sign = _random.nextBool() ? 1.0 : -1.0;
    for (final resident in residents) {
      resident.applyWind(directionSign: sign);
    }
    toyStatus.value = 'A festival wind sweeps the plaza!';
  }

  void _castPetalRain() {
    for (var i = 0; i < 10; i++) {
      final pos = Vector2(
        40 + _random.nextDouble() * (size.x - 80),
        size.y * (0.45 + _random.nextDouble() * 0.4),
      );
      spawnPetals(pos, count: 16);
    }
    for (final resident in residents) {
      if (resident.config.id != 'xolo') {
        resident.applyDancePulse();
      }
    }
    toyStatus.value = 'Marigold rain!';
  }

  void _castMusic() {
    musicPlaying = true;
    _musicTimer = 4.0;
    for (final resident in residents) {
      resident.applyDancePulse();
    }
    toyStatus.value = 'Mariachi fills the air — everyone dances!';
  }

  void _castPanDulce() {
    activeTreat?.removeFromParent();
    final treatPos = Vector2(
      size.x * (0.25 + _random.nextDouble() * 0.5),
      size.y * (0.72 + _random.nextDouble() * 0.15),
    );
    final treat = PanDulceTreat(position: treatPos);
    activeTreat = treat;
    add(treat);

    final dog = xolo;
    if (dog != null) {
      dog.attractTo(treatPos);
    }
    for (final resident in residents) {
      if (resident.config.id == 'xolo') continue;
      if (_random.nextDouble() < 0.55) {
        resident.attractTo(treatPos + Vector2(_random.nextDouble() * 40 - 20, 10));
      }
    }
    toyStatus.value = 'Pan dulce! Xolo is on the case';
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (musicPlaying) {
      _musicTimer -= dt;
      if (_musicTimer <= 0) {
        musicPlaying = false;
      } else if (_musicTimer > 0 && _random.nextDouble() < dt * 1.2) {
        // Occasional dance pulses while music lasts.
        final dancers = residents.where((r) => !r.held && !r.airborne).toList();
        if (dancers.isNotEmpty) {
          dancers[_random.nextInt(dancers.length)].applyDancePulse();
        }
      }
    }

    final treat = activeTreat;
    if (treat != null && !treat.claimed) {
      final dog = xolo;
      if (dog != null && dog.position.distanceTo(treat.position) < 36) {
        treat.claimed = true;
        treat.removeFromParent();
        activeTreat = null;
        dog.applyDancePulse();
        spawnPetals(dog.position.clone()..y -= 20, count: 12);
        toyStatus.value = 'Xolo gobbled the pan dulce!';
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    backdrop?.resizeTo(size);
    if (_residentsReady) {
      for (final resident in residents) {
        resident.worldBounds = size.clone();
      }
    }
  }
}
