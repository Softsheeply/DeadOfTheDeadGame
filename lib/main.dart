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
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          SafeArea(
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
                    child: _DayNightButton(game: _game),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: _ToyTray(game: _game),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: _ToyStatus(game: _game),
                  ),
                ),
              ],
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xDD2B163F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x99F39A3C), width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(
                night ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: night ? const Color(0xFFF4C15A) : const Color(0xFFB8D4FF),
                size: 28,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE241033),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x66F39A3C)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final toy in toys)
              _ToyButton(
                icon: toy.$2,
                label: toy.$3,
                onTap: () => game.useToy(toy.$1),
              ),
          ],
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
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A1B55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x55ED5791)),
                ),
                child: Icon(icon, color: const Color(0xFFFFF1D1), size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE7D2FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
        return AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 200),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xAA1A0F2C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFFFFF1D1), fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}
