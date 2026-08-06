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
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: _HintBanner(),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 12),
                child: _DayNightButton(game: game),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: _ToyTray(game: game),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: _ToyStatus(game: game),
              ),
            ),
          ],
        ),
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          'Tap · drag · fling  ·  toys below  ·  sun/moon above',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFF1D1),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _DayNightButton extends StatelessWidget {
  const _DayNightButton({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.isNight,
      builder: (context, night, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: game.toggleDayNight,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xEE2B163F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xAAF39A3C), width: 1.6),
              ),
              child: Icon(
                night ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: night ? const Color(0xFFF4C15A) : const Color(0xFFB8D4FF),
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToyTray extends StatelessWidget {
  const _ToyTray({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    const toys = [
      (VillageToy.wind, Icons.air_rounded, 'Wind'),
      (VillageToy.petals, Icons.local_florist_rounded, 'Petals'),
      (VillageToy.music, Icons.music_note_rounded, 'Music'),
      (VillageToy.panDulce, Icons.cookie_rounded, 'Pan dulce'),
    ];

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF2241033),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x88F39A3C), width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final toy in toys) ...[
                _ToyButton(
                  icon: toy.$2,
                  label: toy.$3,
                  onTap: () => game.useToy(toy.$1),
                ),
                if (toy != toys.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 74,
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC1A0F2C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFFFF1D1), fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
