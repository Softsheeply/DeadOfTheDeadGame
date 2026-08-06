import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/spirit_village_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Dead of the Dead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF160D29),
      ),
      home: const SpiritVillageApp(),
    ),
  );
}

class SpiritVillageApp extends StatelessWidget {
  const SpiritVillageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: SpiritVillageGame()),
          const IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _HintBanner(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC2B163F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66F39A3C)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Tap · drag · fling the spirits  ·  they keep living if you don’t',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFF1D1),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
