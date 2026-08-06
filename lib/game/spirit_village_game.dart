import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/character_config.dart';
import 'resident.dart';

/// The main game class -- Flutter/Flame equivalent of the JS prototype's
/// src/village.js + src/app.js combined. Phase 2 scope: one character,
/// real idle animation, autonomous wandering (walk to a random point,
/// idle, repeat). No obstacles/pathfinding/multi-resident/interactions yet
/// -- same order those were added in the JS build (see
/// Softsheeply/DayoftheDead's docs/GAME_OVERVIEW.md for the full roadmap
/// this is porting).
class SpiritVillageGame extends FlameGame {
  late Resident pepita;
  bool _residentsReady = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final jsonString = await rootBundle.loadString('assets/images/pepita/character.json');
    final config = CharacterConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

    pepita = Resident(config: config, position: Vector2(size.x / 2, size.y / 2))
      ..worldBounds = size.clone();
    add(pepita);
    _residentsReady = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep wandering bounds in sync with the actual canvas size -- direct
    // callback for this in Flame, unlike the JS prototype which needed a
    // debounced window-resize listener + defensive re-check (see that
    // repo's README for the story behind why that mattered). Flame calls
    // onGameResize before onLoad finishes on startup, so guard against
    // touching `pepita` (a `late` field) before it's actually assigned.
    if (_residentsReady) pepita.worldBounds = size.clone();
  }
}
