import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/character_config.dart';
import 'resident.dart';

/// The main game class -- Flutter/Flame equivalent of the JS prototype's
/// src/village.js + src/app.js combined. Phase 1 scope, matching how the
/// original JS build was sequenced: load one character's data, get them
/// rendering with a real idle animation. Behaviour/pathfinding/interactions/
/// hotspots/multi-resident all come in subsequent passes, same order they
/// were built in JS (see Softsheeply/DayoftheDead's docs/GAME_OVERVIEW.md
/// for the full roadmap this is porting).
class SpiritVillageGame extends FlameGame {
  late Resident pepita;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final jsonString = await rootBundle.loadString('assets/images/pepita/character.json');
    final config = CharacterConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

    pepita = Resident(config: config, position: Vector2(size.x / 2, size.y / 2));
    add(pepita);
  }
}
