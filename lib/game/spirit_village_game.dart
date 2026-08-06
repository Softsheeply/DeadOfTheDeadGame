import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/character_config.dart';
import 'petal_burst.dart';
import 'resident.dart';
import 'village_backdrop.dart';

/// Spirit Village -- living Día de los Muertos plaza with Pocket God style
/// touch toys (tap / drag / fling). Residents keep wandering when idle.
class SpiritVillageGame extends FlameGame {
  final List<Resident> residents = [];
  VillageBackdrop? backdrop;
  bool _residentsReady = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = VillageBackdrop(size: size.clone());
    await add(backdrop!);

    await _spawnResident(
      assetPath: 'assets/images/pepita/character.json',
      position: Vector2(size.x * 0.42, size.y * 0.72),
    );
    await _spawnResident(
      assetPath: 'assets/images/abuela_rosa/character.json',
      position: Vector2(size.x * 0.62, size.y * 0.76),
    );

    _residentsReady = true;
  }

  Future<void> _spawnResident({
    required String assetPath,
    required Vector2 position,
  }) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final config = CharacterConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
    final resident = Resident(config: config, position: position)
      ..worldBounds = size.clone()
      ..onPetalBurst = (pos, {int count = 14}) => spawnPetals(pos, count: count);
    residents.add(resident);
    await add(resident);
  }

  void spawnPetals(Vector2 position, {int count = 14}) {
    add(PetalBurst(position: position, count: count));
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
