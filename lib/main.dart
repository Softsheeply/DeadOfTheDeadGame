import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/cast_roster.dart';
import 'game/spirit_village_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      backgroundColor: const Color(0xFF120A24),
      body: GameWidget(
        game: _game,
        loadingBuilder: (_) => const ColoredBox(
          color: Color(0xFF120A24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFF39A3C)),
          ),
        ),
        errorBuilder: (_, error) => ColoredBox(
          color: const Color(0xFF120A24),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Plaza failed to load:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFF1D1), fontSize: 13),
              ),
            ),
          ),
        ),
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
          Positioned(
            top: 10,
            left: 12,
            child: _MissionCard(game: game),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MuteButton(game: game),
                const SizedBox(width: 8),
                _CastButton(game: game),
              ],
            ),
          ),
          Positioned(
            top: 58,
            right: 12,
            child: _CastPanel(game: game),
          ),
        ],
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.audio.muted,
      builder: (context, muted, _) {
        return GestureDetector(
          onTap: game.audio.toggleMute,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xF21A0F2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x88F39A3C)),
            ),
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: const Color(0xFFFFF1D1),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        game.mission.title,
        game.mission.detail,
        game.mission.progress,
        game.mission.goal,
        game.mission.completedFlash,
      ]),
      builder: (context, _) {
        final flash = game.mission.completedFlash.value;
        return Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: flash ? const Color(0xF23A1B55) : const Color(0xF21A0F2C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: flash ? const Color(0xFF47C4BA) : const Color(0x88F39A3C),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flash ? 'Done!' : 'Mission',
                style: TextStyle(
                  color: flash ? const Color(0xFF47C4BA) : const Color(0xFFF39A3C),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game.mission.title.value,
                style: const TextStyle(
                  color: Color(0xFFFFF1D1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game.mission.detail.value,
                style: const TextStyle(color: Color(0xFFC9B4E0), fontSize: 10),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: game.mission.goal.value == 0
                            ? 0
                            : game.mission.progress.value / game.mission.goal.value,
                        minHeight: 5,
                        backgroundColor: const Color(0x443A1B55),
                        color: const Color(0xFFF39A3C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${game.mission.progress.value}/${game.mission.goal.value}',
                    style: const TextStyle(
                      color: Color(0xFFFFF1D1),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CastButton extends StatelessWidget {
  const _CastButton({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.castPanelOpenListenable,
      builder: (context, open, _) {
        return GestureDetector(
          onTap: game.toggleCastPanel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF21A0F2C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x88F39A3C)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  open ? Icons.groups_rounded : Icons.group_add_rounded,
                  color: const Color(0xFFFFF1D1),
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Cast',
                  style: TextStyle(
                    color: Color(0xFFFFF1D1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CastPanel extends StatelessWidget {
  const _CastPanel({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.castPanelOpenListenable,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: game.castRevision,
          builder: (context, _, child) {
            return Material(
              color: Colors.transparent,
              child: Container(
                width: 220,
                constraints: const BoxConstraints(maxHeight: 320),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  color: const Color(0xF2140B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x88F39A3C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Plaza cast',
                      style: TextStyle(
                        color: Color(0xFFF39A3C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to invite or send off-screen',
                      style: TextStyle(color: Color(0xFFC9B4E0), fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: kPlazaCast.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final member = kPlazaCast[index];
                          final on = game.castRoster.isOnPlaza(member.id);
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => game.toggleCastMember(member.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: on
                                    ? const Color(0x553A1B55)
                                    : const Color(0x221A0F2C),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: on
                                      ? const Color(0xAA47C4BA)
                                      : const Color(0x44555555),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    on
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 16,
                                    color: on
                                        ? const Color(0xFF47C4BA)
                                        : const Color(0xFF887799),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      member.displayName,
                                      style: TextStyle(
                                        color: on
                                            ? const Color(0xFFFFF1D1)
                                            : const Color(0xFFAA99BB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    on ? 'On' : 'Off',
                                    style: TextStyle(
                                      color: on
                                          ? const Color(0xFF47C4BA)
                                          : const Color(0xFF887799),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
