import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/spirit_village_game.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Dead of the Dead',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF160D29),
        body: GameWidget(game: SpiritVillageGame()),
      ),
    ),
  );
}
