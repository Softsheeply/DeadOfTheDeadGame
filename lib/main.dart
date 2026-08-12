import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/cast_roster.dart';
import 'game/plaza_mission.dart';
import 'game/plaza_tutorial.dart';
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
    return ValueListenableBuilder<bool>(
      valueListenable: game.photoMode,
      builder: (context, photo, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (!photo) ...[
              SafeArea(
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
                      left: 24,
                      right: 24,
                      bottom: 118,
                      child: _TutorialBead(game: game),
                    ),
                    Positioned(
                      top: 10,
                      left: 12,
                      child: _MissionCard(game: game),
                    ),
                    Positioned(
                      top: 58,
                      left: 12,
                      child: _MissionLogPanel(game: game),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 72,
                      child: _MissionRewardToast(game: game),
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MapButton(game: game),
                          const SizedBox(width: 8),
                          _MuteButton(game: game),
                          const SizedBox(width: 8),
                          _SettingsButton(game: game),
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
                    Positioned(
                      top: 58,
                      right: 12,
                      child: _SettingsPanel(game: game),
                    ),
                    Positioned(
                      top: 58,
                      right: 12,
                      child: _WorldMapPanel(game: game),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 130,
                      child: _CastBioSheet(game: game),
                    ),
                  ],
                ),
              ),
            ] else
              Positioned(
                top: 10,
                right: 12,
                child: _PhotoModeExit(game: game),
              ),
            _MainMenuOverlay(game: game),
          ],
        );
      },
    );
  }
}

class _MainMenuOverlay extends StatelessWidget {
  const _MainMenuOverlay({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.showMainMenu,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        return ColoredBox(
          color: const Color(0xDD120A24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Day of the Dead',
                      style: TextStyle(
                        color: Color(0xFFF39A3C),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Living Festival Plaza',
                      style: TextStyle(color: Color(0xFFFFF1D1), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _MenuButton(
                      label: 'Enter plaza',
                      icon: Icons.play_arrow_rounded,
                      primary: true,
                      onTap: game.startPlaza,
                    ),
                    const SizedBox(height: 10),
                    _MenuButton(
                      label: 'World map',
                      icon: Icons.map_rounded,
                      onTap: () {
                        game.startPlaza();
                        game.toggleWorldMap();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: primary ? const Color(0xFF733D91) : const Color(0xF21A0F2C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xAAF39A3C)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFF1D1), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFFF1D1),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.toggleWorldMap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xF21A0F2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x88F39A3C)),
        ),
        child: const Icon(Icons.map_rounded, color: Color(0xFFFFF1D1), size: 20),
      ),
    );
  }
}

class _WorldMapPanel extends StatelessWidget {
  const _WorldMapPanel({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.worldMapOpen,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xF2140B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x88F39A3C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'World map',
                        style: TextStyle(
                          color: Color(0xFFF39A3C),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: game.toggleWorldMap,
                      child: const Icon(Icons.close_rounded, color: Color(0xFFC9B4E0), size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...game.worldMap.nodes.map((node) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          node.unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 14,
                          color: node.unlocked ? const Color(0xFF47C4BA) : const Color(0xFF887799),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.label,
                                style: TextStyle(
                                  color: node.unlocked
                                      ? const Color(0xFFFFF1D1)
                                      : const Color(0xFFAA99BB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                node.role,
                                style: const TextStyle(color: Color(0xFF887799), fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoModeExit extends StatelessWidget {
  const _PhotoModeExit({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: game.togglePhotoMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xF21A0F2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x88F39A3C)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_rounded, color: Color(0xFFF39A3C), size: 18),
            SizedBox(width: 6),
            Text(
              'Exit photo',
              style: TextStyle(
                color: Color(0xFFFFF1D1),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastBioSheet extends StatelessWidget {
  const _CastBioSheet({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: game.castBioId,
      builder: (context, id, _) {
        if (id == null) return const SizedBox.shrink();
        final bio = game.castJournal.bioFor(id);
        if (bio == null) return const SizedBox.shrink();
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xF2140B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xAAF39A3C)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bio.displayName,
                          style: const TextStyle(
                            color: Color(0xFFFFF1D1),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: game.dismissCastBio,
                        child: const Icon(Icons.close_rounded, color: Color(0xFFC9B4E0), size: 18),
                      ),
                    ],
                  ),
                  Text(
                    bio.role,
                    style: const TextStyle(color: Color(0xFFF39A3C), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio.bio,
                    style: const TextStyle(color: Color(0xFFC9B4E0), fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Likes: ${bio.likes}',
                    style: const TextStyle(color: Color(0xFF47C4BA), fontSize: 10, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          onTap: game.toggleMutePersisted,
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
    return GestureDetector(
      onTap: game.toggleMissionLog,
      child: AnimatedBuilder(
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
              Row(
                children: [
                  Text(
                    flash ? 'Done!' : 'Mission',
                    style: TextStyle(
                      color: flash ? const Color(0xFF47C4BA) : const Color(0xFFF39A3C),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.list_alt_rounded, color: Color(0x88F39A3C), size: 14),
                ],
              ),
              if (!flash && game.mission.currentSet == MissionSet.festival)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0x33733D91),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x66ED5791)),
                      ),
                      child: const Text(
                        'Festival',
                        style: TextStyle(
                          color: Color(0xFFED5791),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
      ),
    );
  }
}

class _MissionLogPanel extends StatelessWidget {
  const _MissionLogPanel({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.missionLogOpen,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        final steps = game.missionCatalog.steps;
        final currentIndex =
            steps.indexWhere((step) => step.id == game.mission.current);
        return Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xF2140B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x88F39A3C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mission log',
                        style: TextStyle(
                          color: Color(0xFFF39A3C),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: game.toggleMissionLog,
                      child: const Icon(Icons.close_rounded, color: Color(0xFFC9B4E0), size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed: ${game.prefs.missionsCompleted}',
                  style: const TextStyle(color: Color(0xFFC9B4E0), fontSize: 10),
                ),
                const SizedBox(height: 8),
                ...List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isCurrent = index == currentIndex;
                  final isDone = currentIndex >= 0 && index < currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCurrent
                              ? Icons.radio_button_checked_rounded
                              : isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_off_rounded,
                          size: 14,
                          color: isCurrent
                              ? const Color(0xFFF39A3C)
                              : isDone
                                  ? const Color(0xFF47C4BA)
                                  : const Color(0xFF887799),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: TextStyle(
                                  color: isCurrent
                                      ? const Color(0xFFFFF1D1)
                                      : isDone
                                          ? const Color(0xFFAA99BB)
                                          : const Color(0xFF887799),
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              if (isCurrent)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${game.mission.progress.value}/${game.mission.goal.value} · ${step.detail}',
                                    style: const TextStyle(
                                      color: Color(0xFFC9B4E0),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MissionRewardToast extends StatelessWidget {
  const _MissionRewardToast({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MissionRewardToast?>(
      valueListenable: game.rewardToast,
      builder: (context, toast, _) {
        if (toast == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xEE3A1B55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF47C4BA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x6647C4BA),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${toast.setLabel} complete!',
                    style: const TextStyle(
                      color: Color(0xFF47C4BA),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    toast.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFF1D1),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
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
                                  GestureDetector(
                                    onTap: () => game.showCastBio(member.id),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        size: 16,
                                        color: Color(0xFFF39A3C),
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
              label: 'Treat',
              onTap: () => game.useToy(VillageToy.panDulce),
            ),
          ),
          Expanded(
            child: _ToyChip(
              icon: Icons.light_mode_rounded,
              label: 'Lantern',
              onTap: () => game.useToy(VillageToy.lantern),
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

class _TutorialBead extends StatelessWidget {
  const _TutorialBead({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.tutorialStep,
      builder: (context, step, _) {
        final bead = PlazaTutorial.stepAt(step);
        if (bead == null) return const SizedBox.shrink();
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xF21A0F2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xAAF39A3C)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bead.icon, color: const Color(0xFFF39A3C), size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          bead.message,
                          style: const TextStyle(
                            color: Color(0xFFFFF1D1),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < PlazaTutorial.stepCount; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: EdgeInsets.only(right: i < PlazaTutorial.stepCount - 1 ? 5 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == step
                                ? const Color(0xFF47C4BA)
                                : const Color(0x55FFF1D1),
                          ),
                        ),
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: game.skipAllTutorial,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Skip all',
                            style: TextStyle(
                              color: Color(0x99FFF1D1),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: game.dismissTutorial,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Got it',
                            style: TextStyle(
                              color: Color(0xFF47C4BA),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.settingsOpen,
      builder: (context, open, _) {
        return GestureDetector(
          onTap: game.toggleSettings,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xF21A0F2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x88F39A3C)),
            ),
            child: Icon(
              open ? Icons.close_rounded : Icons.settings_rounded,
              color: const Color(0xFFFFF1D1),
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.game});

  final SpiritVillageGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.settingsOpen,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: Container(
            width: 240,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                  'Settings',
                  style: TextStyle(
                    color: Color(0xFFF39A3C),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: game.audio.muted,
                  builder: (context, muted, _) {
                    return _SettingsToggle(
                      label: 'Mute audio',
                      value: muted,
                      onChanged: (v) => game.setMutedPersisted(v),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: game.reduceMotion,
                  builder: (context, value, _) {
                    return _SettingsToggle(
                      label: 'Reduce motion',
                      value: value,
                      onChanged: game.setReduceMotion,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: game.photoMode,
                  builder: (context, value, _) {
                    return _SettingsToggle(
                      label: 'Photo mode',
                      value: value,
                      onChanged: (_) => game.togglePhotoMode(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Missions completed: ${game.prefs.missionsCompleted}',
                  style: const TextStyle(color: Color(0xFFC9B4E0), fontSize: 10),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Day of the Dead\nSoftsheeply · plaza prototype',
                  style: TextStyle(color: Color(0xFFC9B4E0), fontSize: 10, height: 1.35),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFF1D1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFFF39A3C),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

