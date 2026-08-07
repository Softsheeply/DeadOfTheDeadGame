import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/spirit_village_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    MaterialApp(
      title: 'Day of the Dead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120A24),
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

/// Slim bottom toy bar — keeps the plaza visible.
class VillageHud extends StatelessWidget {
  const VillageHud({required this.game, super.key});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: _BottomToyBar(game: game),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 78,
            child: _ToyStatus(game: game),
          ),
        ],
      ),
    );
  }
}

class _BottomToyBar extends StatelessWidget {
  const _BottomToyBar({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xF21A0F2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x88F39A3C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToyChip(
              icon: Icons.air_rounded,
              label: 'Wind',
              onTap: () => game.useToy(VillageToy.wind),
            ),
          ),
          Expanded(
            child: _ToyChip(
              icon: Icons.local_florist_rounded,
              label: 'Petals',
              onTap: () => game.useToy(VillageToy.petals),
            ),
          ),
          Expanded(
            child: _ToyChip(
              icon: Icons.music_note_rounded,
              label: 'Music',
              onTap: () => game.useToy(VillageToy.music),
            ),
          ),
          Expanded(
            child: _ToyChip(
              icon: Icons.cake_rounded,
              label: 'Pan dulce',
              onTap: () => game.useToy(VillageToy.panDulce),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<bool>(
            valueListenable: game.isNight,
            builder: (context, night, _) {
              return GestureDetector(
                onTap: game.toggleDayNight,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1B55),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xAAF39A3C)),
                  ),
                  child: Icon(
                    night ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                    color: night ? const Color(0xFFF4C15A) : const Color(0xFFB8D4FF),
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToyChip extends StatelessWidget {
  const _ToyChip({
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFF1D1), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE7D2FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xCC1A0F2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFF1D1), fontSize: 11),
            ),
          ),
        );
      },
    );
  }
}
