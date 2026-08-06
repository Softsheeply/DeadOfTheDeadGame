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

class SpiritVillageApp extends StatefulWidget {
  const SpiritVillageApp({super.key});

  @override
  State<SpiritVillageApp> createState() => _SpiritVillageAppState();
}

class _SpiritVillageAppState extends State<SpiritVillageApp> {
  late final SpiritVillageGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpiritVillageGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) => VillageHud(game: game as SpiritVillageGame),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}

class VillageHud extends StatelessWidget {
  const VillageHud({required this.game, super.key});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 12,
            left: 16,
            right: 72,
            child: _HintBanner(),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: _CircleAction(
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFF4C15A),
              onTap: game.toggleDayNight,
            ),
          ),
          Positioned(
            top: 56,
            left: 12,
            right: 12,
            child: _ToyTray(game: game),
          ),
          Positioned(
            top: 150,
            left: 24,
            right: 24,
            child: _ToyStatus(game: game),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC2B163F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66F39A3C)),
      ),
      child: const Text(
          'Tap · drag · fling the spirits  ·  use toys  ·  tap sun for day/night',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFFFF1D1),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xF22B163F),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xAAF39A3C), width: 1.6),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _ToyTray extends StatelessWidget {
  const _ToyTray({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF2241033),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x88F39A3C), width: 1.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToyButton(
              icon: Icons.air_rounded,
              label: 'Wind',
              onTap: () => game.useToy(VillageToy.wind),
            ),
          ),
          Expanded(
            child: _ToyButton(
              icon: Icons.local_florist_rounded,
              label: 'Petals',
              onTap: () => game.useToy(VillageToy.petals),
            ),
          ),
          Expanded(
            child: _ToyButton(
              icon: Icons.music_note_rounded,
              label: 'Music',
              onTap: () => game.useToy(VillageToy.music),
            ),
          ),
          Expanded(
            child: _ToyButton(
              icon: Icons.cake_rounded,
              label: 'Pan dulce',
              onTap: () => game.useToy(VillageToy.panDulce),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToyButton extends StatelessWidget {
  const _ToyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3A1B55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66ED5791)),
              ),
              child: Icon(icon, color: const Color(0xFFFFF1D1), size: 25),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE7D2FF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToyStatus extends StatelessWidget {
  const _ToyStatus({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.toyStatus,
      builder: (context, text, _) {
        if (text.isEmpty) return const SizedBox.shrink();
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xCC1A0F2C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFF1D1), fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
