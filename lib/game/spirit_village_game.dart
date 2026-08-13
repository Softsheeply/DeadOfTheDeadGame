import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/cast_journal.dart';
import '../data/character_config.dart';
import '../data/location_config.dart';
import '../data/mission_catalog.dart';
import '../data/world_map_config.dart';
import 'ambient_critters.dart';
import 'cast_roster.dart';
import 'ofrenda_marker.dart';
import 'petal_burst.dart';
import 'plaza_audio.dart';
import 'plaza_juice.dart';
import 'plaza_mission.dart';
import 'plaza_occluders.dart';
import 'plaza_prefs.dart';
import 'plaza_tutorial.dart';
import 'resident.dart';
import 'toys.dart';
import 'village_atmosphere.dart';
import 'village_backdrop.dart';
import 'village_decor.dart';

enum VillageToy { wind, petals, music, panDulce, lantern }

/// Brief toast payload when a plaza mission completes.
class MissionRewardToast {
  const MissionRewardToast({
    required this.title,
    required this.setLabel,
  });

  final String title;
  final String setLabel;
}

/// Spirit Village -- living Día de los Muertos plaza with Pocket God toys.
class SpiritVillageGame extends FlameGame with TapCallbacks {
  final List<Resident> residents = [];
  final Map<String, Resident> _residentsById = {};
  final CastRoster castRoster = CastRoster();
  final CastJournal castJournal = CastJournal();
  final PlazaAudio audio = PlazaAudio();
  final MissionCatalog missionCatalog = MissionCatalog();
  late final PlazaMission mission;
  final WorldMapConfig worldMap = WorldMapConfig();
  LocationConfig? location;
  final PlazaPrefs prefs = PlazaPrefs();
  VillageBackdrop? backdrop;
  VillageAtmosphere? atmosphere;
  VillageDecor? decor;
  AmbientCritters? critters;
  PlazaOccluders? occluders;
  PanDulceTreat? activeTreat;
  bool _residentsReady = false;
  bool musicPlaying = false;
  double _musicTimer = 0;
  double _missionCelebrateTimer = 0;
  double _rareEventTimer = 28;
  final Random _random = Random();
  final ValueNotifier<bool> isNight = ValueNotifier<bool>(true);
  final ValueNotifier<String> toyStatus = ValueNotifier<String>('');
  final ValueNotifier<int> castRevision = ValueNotifier<int>(0);
  bool castPanelOpen = false;
  final ValueNotifier<bool> castPanelOpenListenable = ValueNotifier<bool>(false);
  final ValueNotifier<int> tutorialStep = ValueNotifier<int>(0);
  final ValueNotifier<bool> settingsOpen = ValueNotifier<bool>(false);
  final ValueNotifier<bool> reduceMotion = ValueNotifier<bool>(false);
  final ValueNotifier<bool> photoMode = ValueNotifier<bool>(false);
  final ValueNotifier<String?> castBioId = ValueNotifier<String?>(null);
  final ValueNotifier<bool> showMainMenu = ValueNotifier<bool>(true);
  final ValueNotifier<bool> worldMapOpen = ValueNotifier<bool>(false);
  final ValueNotifier<bool> missionLogOpen = ValueNotifier<bool>(false);
  final ValueNotifier<MissionRewardToast?> rewardToast =
      ValueNotifier<MissionRewardToast?>(null);
  OfrendaMarker? _ofrendaMarker;
  double _benchChatTimer = 22;

  Resident? get xolo => _residentsById['xolo'];

  Rect get roadRect =>
      backdrop?.roadRect ??
      Rect.fromLTWH(size.x * 0.15, size.y * 0.62, size.x * 0.7, size.y * 0.2);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = VillageBackdrop(size: size.clone());
    await add(backdrop!);
    atmosphere = VillageAtmosphere(backdrop: backdrop!);
    await add(atmosphere!);
    decor = VillageDecor(backdrop: backdrop!);
    await add(decor!);
    critters = AmbientCritters(backdrop: backdrop!);
    await add(critters!);
    occluders = PlazaOccluders(backdrop: backdrop!);
    await add(occluders!);
    _ofrendaMarker = OfrendaMarker(backdrop: backdrop!);
    await add(_ofrendaMarker!);

    location = await LocationConfig.loadAsset('assets/data/locations/l1_festival_plaza.json');
    backdrop!.applyLocation(location!);
    occluders!.applyDefs(location!.occluders);

    // Decor loads markers; atmosphere reads fx for water/candles/smoke.
    atmosphere!.configureFromDecor(decor!);

    await missionCatalog.load();
    mission = PlazaMission(missionCatalog);
    await worldMap.load();

    await castRoster.load();
    await castJournal.load();
    await prefs.load();
    audio.muted.value = prefs.muted;
    reduceMotion.value = prefs.reduceMotion;
    mission.restore(prefs.missionId, prefs.missionProgress);
    mission.completedCount.value = prefs.missionsCompleted;
    tutorialStep.value = prefs.tutorialStep;
    showMainMenu.value = !prefs.mainMenuDismissed;

    await audio.load();

    for (final member in kPlazaCast) {
      if (castRoster.isOnPlaza(member.id)) {
        await _spawnCastMember(member, animateEntrance: false);
      }
    }

    castRoster.addListener(_onCastRosterChanged);
    _syncResidentBounds();
    _residentsReady = true;
    _bumpCastRevision();

    if (prefs.isNight != (backdrop?.isNight ?? true)) {
      backdrop?.setNight(prefs.isNight);
    }
    isNight.value = backdrop?.isNight ?? true;
    toyStatus.value = mission.detail.value;
  }

  void _onCastRosterChanged() {
    // Roster toggles are driven through [setCastPresent] so we can animate.
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (backdrop?.hitTestCelestialTap(event.localPosition) ?? false) {
      toggleDayNight();
      return;
    }
    if (atmosphere?.tryLightCandle(event.localPosition) ?? false) {
      spawnPetals(event.localPosition.clone(), count: 6);
      audio.petalsSfx();
      toyStatus.value = 'A candle flares brighter!';
      final done = mission.reportCandleLit();
      if (done) {
        _onMissionComplete();
      } else if (mission.current == MissionId.candles) {
        toyStatus.value =
            'Candles ${mission.progress.value}/${mission.goal.value} — keep lighting';
        _persistMission();
      }
      return;
    }
    final building = decor?.hitTest(event.localPosition);
    if (building != null) {
      _onBuildingTapped(building);
      return;
    }
    final interactable = decor?.hitTestInteractable(event.localPosition);
    if (interactable != null) {
      _onInteractableTapped(interactable, event.localPosition.clone());
      return;
    }
    if (backdrop?.nearOfrenda(event.localPosition) ?? false) {
      _onOfrendaTapped();
      return;
    }
  }

  void _onOfrendaTapped() {
    final ofrenda = backdrop?.ofrendaWorld;
    if (ofrenda == null) return;
    spawnPetals(ofrenda.clone(), count: 12);
    add(SparkleBurst(position: ofrenda.clone(), count: 14));
    audio.petalsSfx();
    final missionBump = mission.reportOfrendaTap();
    if (missionBump) {
      _onMissionComplete();
    } else if (mission.current == MissionId.ofrendaTribute) {
      toyStatus.value =
          'Ofrenda ${mission.progress.value}/${mission.goal.value} — keep honoring the tree';
      _persistMission();
    } else if (mission.current != MissionId.marigolds) {
      toyStatus.value = 'Marigolds settle on the ofrenda';
    }
    for (final resident in residents) {
      if (!resident.held && !resident.airborne && resident.position.distanceTo(ofrenda) < 200) {
        resident.glanceToward(ofrenda);
        break;
      }
    }
  }

  void toggleCastPanel() {
    castPanelOpen = !castPanelOpen;
    castPanelOpenListenable.value = castPanelOpen;
    if (castPanelOpen) settingsOpen.value = false;
  }

  Future<void> setCastPresent(String id, bool present) async {
    if (castRoster.isOnPlaza(id) == present) return;
    await castRoster.setOnPlaza(id, present);
    if (present) {
      await _bringOnPlaza(id);
    } else {
      _sendOffPlaza(id);
    }
    _bumpCastRevision();
  }

  Future<void> toggleCastMember(String id) =>
      setCastPresent(id, !castRoster.isOnPlaza(id));

  void _bumpCastRevision() => castRevision.value++;

  Future<void> _bringOnPlaza(String id) async {
    final existing = _residentsById[id];
    if (existing != null && existing.isMounted) {
      existing.onExitComplete = null;
      existing.allowOffRoad = false;
      final dest = backdrop?.randomHotspot(_random) ?? roadRect.center.toVector2();
      existing.enterPlaza(dest, fromLeft: _random.nextBool());
      return;
    }
    final member = kPlazaCast.firstWhere((m) => m.id == id);
    await _spawnCastMember(member, animateEntrance: true);
  }

  void _sendOffPlaza(String id) {
    final resident = _residentsById[id];
    if (resident == null) return;
    final toLeft = resident.position.x < size.x * 0.5;
    resident.onExitComplete = () {
      resident.removeFromParent();
      residents.remove(resident);
      _residentsById.remove(id);
      _bumpCastRevision();
      toyStatus.value = '${resident.config.displayName} left the plaza';
    };
    resident.exitPlaza(toLeft: toLeft);
    toyStatus.value = '${resident.config.displayName} is heading off…';
  }

  Future<void> _spawnCastMember(
    CastMemberInfo member, {
    required bool animateEntrance,
  }) async {
    final jsonString = await rootBundle.loadString(member.assetPath);
    final config = CharacterConfig.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
    final displaySize = _displaySizeFor(member.kind);
    final dest = backdrop?.randomHotspot(_random) ??
        Vector2(
          roadRect.left + roadRect.width * (0.2 + _random.nextDouble() * 0.6),
          roadRect.top + roadRect.height * (0.3 + _random.nextDouble() * 0.5),
        );

    final resident = Resident(config: config, position: dest.clone())
      ..size = displaySize
      ..worldBounds = size.clone()
      ..roadBounds = roadRect
      ..walkClamp = _walkClamp
      ..routeToward = _routeToward
      ..wanderHotspots = (backdrop?.hotspotWorldPoints() ?? const [])
      ..preferredHotspots = _preferredHotspotsFor(member)
      ..restSpots = (backdrop?.restSpotWorldPoints() ?? const [])
      ..reduceMotion = reduceMotion.value
      ..depthPriority = (feetY) {
        return occluders?.depthPriorityForFeet(feetY) ?? (feetY * 10).round();
      }
      ..onPetalBurst = (pos, {int count = 14}) {
        spawnPetals(pos, count: count);
      }
      ..onIdleFlavor = (line) {
        toyStatus.value = line;
      }
      ..onGrab = () {
        audio.grabSfx();
        _maybeAdvanceTutorial(expectedStep: 0);
        toyStatus.value = 'Got ${config.displayName}!';
      }
      ..onRelease = ({required bool flung}) {
        audio.dropSfx(flung: flung);
        toyStatus.value = flung
            ? '${config.displayName} goes flying!'
            : '${config.displayName} lands softly';
      };

    residents.add(resident);
    _residentsById[member.id] = resident;
    await add(resident);

    if (animateEntrance) {
      resident.enterPlaza(dest, fromLeft: _random.nextBool());
      toyStatus.value = '${config.displayName} joins the plaza!';
    }
  }

  Vector2 _displaySizeFor(CastKind kind) {
    final person = backdrop?.personDisplaySize ?? 64;
    final dog = backdrop?.dogDisplaySize ?? 50;
    return switch (kind) {
      CastKind.person => Vector2.all(person),
      CastKind.dog => Vector2.all(dog),
      CastKind.cat => Vector2.all((dog * 0.92).clamp(36.0, 52.0)),
      CastKind.creature => Vector2.all((person * 0.85).clamp(44.0, 62.0)),
    };
  }

  List<Vector2> _preferredHotspotsFor(CastMemberInfo member) {
    final all = backdrop?.hotspotWorldPoints() ?? const <Vector2>[];
    if (all.isEmpty || member.preferredHotspotIndexes.isEmpty) return const [];
    return [
      for (final index in member.preferredHotspotIndexes)
        if (index >= 0 && index < all.length) all[index],
    ];
  }

  Vector2 _walkClamp(Vector2 point, {bool softTop = false}) {
    final bd = backdrop;
    if (bd == null) return point;
    return bd.clampToWalkable(point, allowAirborneLift: softTop);
  }

  List<Vector2> _routeToward(Vector2 from, Vector2 to) {
    final bd = backdrop;
    if (bd == null) return [to];
    return bd.routeToward(from, to);
  }

  void _syncResidentBounds() {
    final road = roadRect;
    final hotspots = backdrop?.hotspotWorldPoints() ?? const <Vector2>[];
    final rests = backdrop?.restSpotWorldPoints() ?? const <Vector2>[];
    for (final resident in residents) {
      CastMemberInfo? member;
      for (final m in kPlazaCast) {
        if (m.id == resident.config.id) {
          member = m;
          break;
        }
      }
      resident.worldBounds = size.clone();
      resident.roadBounds = road;
      resident.walkClamp = _walkClamp;
      resident.routeToward = _routeToward;
      resident.wanderHotspots = hotspots;
      resident.restSpots = rests;
      if (member != null) {
        resident.preferredHotspots = _preferredHotspotsFor(member);
        final side = _displaySizeFor(member.kind);
        if ((resident.size.x - side.x).abs() > 1) {
          resident.setDisplaySize(side);
        }
      }
      resident.reduceMotion = reduceMotion.value;
      resident.depthPriority = (feetY) => occluders?.depthPriorityForFeet(feetY) ?? (feetY * 10).round();
      if (!resident.allowOffRoad) {
        resident.position = _walkClamp(resident.position);
      }
    }
  }

  void spawnPetals(Vector2 position, {int count = 14}) {
    add(PetalBurst(position: position, count: count));
    if (backdrop?.nearOfrenda(position) ?? false) {
      _noteOfrendaPetals();
    }
  }

  void _noteOfrendaPetals() {
    if (_missionCelebrateTimer > 0) return;
    final done = mission.reportOfrendaPetals();
    _persistMission();
    if (done) {
      _onMissionComplete();
    } else if (mission.current == MissionId.marigolds) {
      toyStatus.value =
          'Ofrenda ${mission.progress.value}/${mission.goal.value} — keep the marigolds coming';
    }
  }

  void _persistMission() {
    prefs.saveMission(mission.current, mission.rawProgress);
  }

  void _onMissionComplete() {
    if (_missionCelebrateTimer > 0) return;
    audio.missionSfx();
    _missionCelebrateTimer = 2.4;
    final ofrenda = backdrop?.ofrendaWorld ?? size / 2;
    add(PetalBurst(position: ofrenda, count: 22));
    add(SparkleBurst(position: ofrenda.clone(), count: 20));
    for (final resident in residents) {
      if (!resident.held) resident.applyDancePulse();
    }
    rewardToast.value = MissionRewardToast(
      title: mission.title.value,
      setLabel: mission.currentSetLabel,
    );
    toyStatus.value = 'Mission complete! ${mission.title.value}';
    prefs.saveMissionsCompleted(mission.completedCount.value);
  }

  void startPlaza() {
    showMainMenu.value = false;
    prefs.setMainMenuDismissed(true);
    toyStatus.value = mission.detail.value;
  }

  void toggleWorldMap() {
    worldMapOpen.value = !worldMapOpen.value;
    if (worldMapOpen.value) {
      settingsOpen.value = false;
      castPanelOpenListenable.value = false;
      missionLogOpen.value = false;
    }
  }

  void toggleMissionLog() {
    missionLogOpen.value = !missionLogOpen.value;
    if (missionLogOpen.value) {
      settingsOpen.value = false;
      castPanelOpenListenable.value = false;
      worldMapOpen.value = false;
    }
  }

  bool get tutorialActive => !PlazaTutorial.isComplete(tutorialStep.value);

  void advanceTutorial() {
    if (!tutorialActive) return;
    tutorialStep.value++;
    prefs.setTutorialStep(tutorialStep.value);
  }

  void skipAllTutorial() {
    if (!tutorialActive) return;
    tutorialStep.value = PlazaTutorial.stepCount;
    prefs.setTutorialStep(tutorialStep.value);
  }

  void _maybeAdvanceTutorial({required int expectedStep}) {
    if (tutorialStep.value == expectedStep) {
      advanceTutorial();
    }
  }

  void dismissTutorial() => advanceTutorial();

  void toggleSettings() {
    settingsOpen.value = !settingsOpen.value;
    if (settingsOpen.value) {
      castPanelOpenListenable.value = false;
      missionLogOpen.value = false;
    }
  }

  Future<void> setReduceMotion(bool value) async {
    reduceMotion.value = value;
    for (final resident in residents) {
      resident.reduceMotion = value;
    }
    await prefs.setReduceMotion(value);
  }

  void showCastBio(String id) {
    castBioId.value = id;
    castPanelOpen = false;
    castPanelOpenListenable.value = false;
  }

  void dismissCastBio() => castBioId.value = null;

  void togglePhotoMode() {
    photoMode.value = !photoMode.value;
    if (photoMode.value) {
      settingsOpen.value = false;
      castPanelOpenListenable.value = false;
      toyStatus.value = 'Photo mode — tap settings to show UI';
    } else {
      toyStatus.value = mission.detail.value;
    }
  }

  Future<void> setMutedPersisted(bool value) async {
    await audio.setMuted(value);
    await prefs.setMuted(value);
  }

  void toggleMutePersisted() {
    audio.toggleMute();
    prefs.setMuted(audio.muted.value);
  }

  void toggleDayNight() {
    backdrop?.toggleDayNight();
    isNight.value = backdrop?.isNight ?? true;
    prefs.setNight(isNight.value);
    _maybeAdvanceTutorial(expectedStep: 1);
    toyStatus.value =
        isNight.value ? 'Night settles over the plaza' : 'Morning light fills the plaza';
  }

  void useToy(VillageToy toy) {
    _maybeAdvanceTutorial(expectedStep: 2);
    switch (toy) {
      case VillageToy.wind:
        _castWind();
      case VillageToy.petals:
        _castPetalRain();
      case VillageToy.music:
        _castMusic();
      case VillageToy.panDulce:
        _castPanDulce();
      case VillageToy.lantern:
        _castLantern();
    }
  }

  void _castWind() {
    audio.windSfx();
    add(WindGust(size: size.clone()));
    final sign = _random.nextBool() ? 1.0 : -1.0;
    atmosphere?.applyGust(directionSign: sign);
    backdrop?.applyGust(directionSign: sign);
    for (final resident in residents) {
      resident.applyWind(directionSign: sign);
    }
    final road = roadRect;
    for (var i = 0; i < 4; i++) {
      spawnPetals(
        Vector2(
          road.left + _random.nextDouble() * road.width,
          road.top + _random.nextDouble() * road.height * 0.6,
        ),
        count: 8,
      );
    }
    toyStatus.value = 'A festival wind sweeps the plaza!';
  }

  void _castPetalRain() {
    audio.petalsSfx();
    final road = roadRect;
    final ofrenda = backdrop?.ofrendaWorld;
    if (ofrenda != null) {
      spawnPetals(ofrenda.clone(), count: 18);
      spawnPetals(
        ofrenda + Vector2(_random.nextDouble() * 20 - 10, 8),
        count: 12,
      );
    }
    for (var i = 0; i < 8; i++) {
      final pos = Vector2(
        road.left + _random.nextDouble() * road.width,
        road.top + _random.nextDouble() * road.height,
      );
      spawnPetals(pos, count: 14);
    }
    for (final resident in residents) {
      if (resident.config.id != 'xolo' && resident.config.id != 'gato') {
        resident.applyDancePulse();
      }
    }
    atmosphere?.splashFountain(intensity: 0.4);
    backdrop?.splashFountainLayer(intensity: 0.4);
    toyStatus.value = 'Marigold rain!';
  }

  void _castMusic() {
    audio.musicSfx();
    musicPlaying = true;
    _musicTimer = 4.0;
    add(MusicNotesBurst(size: size.clone()));
    for (final resident in residents) {
      resident.applyDancePulse();
    }
    toyStatus.value = 'Mariachi fills the air — everyone dances!';
    final done = mission.reportMariachi();
    _persistMission();
    if (done) _onMissionComplete();
  }

  void _castPanDulce() {
    audio.treatSfx();
    activeTreat?.removeFromParent();
    final road = roadRect;
    final treatPos = Vector2(
      road.left + road.width * (0.2 + _random.nextDouble() * 0.6),
      road.top + road.height * (0.35 + _random.nextDouble() * 0.45),
    );
    final treat = PanDulceTreat(position: treatPos);
    activeTreat = treat;
    add(treat);
    spawnPetals(treatPos.clone()..y -= 10, count: 6);

    final dog = xolo;
    dog?.attractTo(treatPos);
    _residentsById['gato']?.attractTo(
      treatPos + Vector2(_random.nextDouble() * 20 - 10, 12),
    );
    for (final resident in residents) {
      if (resident.config.id == 'xolo' || resident.config.id == 'gato') continue;
      if (_random.nextDouble() < 0.55) {
        resident.attractTo(
          treatPos + Vector2(_random.nextDouble() * 30 - 15, 8),
        );
      }
    }
    toyStatus.value = 'Pan dulce! Who will claim it?';
  }

  void _castLantern() {
    audio.missionSfx();
    if (!(backdrop?.isNight ?? isNight.value)) {
      backdrop?.setNight(true);
      isNight.value = true;
      prefs.setNight(true);
    }
    add(LanternRipple(size: size.clone()));
    final positions = atmosphere?.rippleLanternGlow() ?? const [];
    var reports = 0;
    for (final pos in positions) {
      spawnPetals(pos.clone(), count: 5);
      add(SparkleBurst(position: pos.clone(), count: 6));
      if (reports >= 3) continue;
      final done = mission.reportCandleLit();
      reports++;
      if (done) {
        _onMissionComplete();
        break;
      }
    }
    if (reports > 0) {
      _persistMission();
    }
    toyStatus.value = positions.isEmpty
        ? 'Lantern glow ripples through the plaza'
        : 'Lantern light wakes ${positions.length} candles!';
  }

  void _onBuildingTapped(PlazaBuilding building) {
    final center = decor?.worldCenterForBuilding(building);
    if (center != null) {
      add(SparkleBurst(position: center.clone(), count: 16));
      spawnPetals(center.clone()..y -= 10, count: 10);
    }
    final flavor = PlazaBuildingReactions.flavorLine(building.id, building.status);
    toyStatus.value = '${building.label}: $flavor';
    if (center != null) {
      _reactCastToBuilding(building.id, center);
    }
    switch (building.id) {
      case 'mariachi_stage':
        add(MusicNotesBurst(size: size.clone()));
        audio.musicSfx();
        if (!musicPlaying) useToy(VillageToy.music);
      case 'panaderia':
        audio.treatSfx();
        atmosphere?.boostOvenSmoke(intensity: 1.2);
      case 'floristeria':
        audio.petalsSfx();
        spawnPetals(center ?? eventFallbackCenter(), count: 14);
      case 'church':
        audio.petalsSfx();
        atmosphere?.rippleLanternGlow();
      case 'mercado':
        audio.petalsSfx();
      default:
        audio.petalsSfx();
    }
  }

  Vector2 eventFallbackCenter() =>
      backdrop?.ofrendaWorld ?? (size / 2);

  void _onInteractableTapped(PlazaInteractable prop, Vector2 tapPoint) {
    final center = decor?.worldCenterForInteractable(prop);
    if (center != null) {
      add(SparkleBurst(position: center.clone(), count: 12));
    }
    switch (prop.kind) {
      case 'fountain':
        atmosphere?.splashFountain(intensity: 1.15);
        backdrop?.splashFountainLayer(intensity: 1.15);
        atmosphere?.rippleWaterAt(const Offset(0.575, 0.60), intensity: 1.1);
        spawnPetals(center?.clone() ?? tapPoint.clone(), count: 10);
        audio.petalsSfx();
        toyStatus.value = 'The fountain burps marigold mist!';
        for (final resident in residents) {
          if (!resident.held &&
              !resident.airborne &&
              resident.position.distanceTo(center ?? Vector2.zero()) < 180) {
            resident.glanceToward(center!);
            break;
          }
        }
      case 'water':
        atmosphere?.rippleWaterAt(const Offset(0.13, 0.88), intensity: 1.3);
        spawnPetals(center?.clone() ?? tapPoint.clone(), count: 6);
        audio.petalsSfx();
        toyStatus.value = 'River: ${prop.status}';
      case 'bench':
        audio.petalsSfx();
        toyStatus.value = '${prop.label}: ${prop.status}';
        _inviteSitAtBench(prop);
      default:
        toyStatus.value = '${prop.label}: ${prop.status}';
        audio.petalsSfx();
    }
  }

  void _inviteSitAtBench(PlazaInteractable bench) {
    final rests = backdrop?.restSpotWorldPoints() ?? const <Vector2>[];
    Vector2? spot;
    final index = bench.restIndex;
    if (index != null && index >= 0 && index < rests.length) {
      spot = rests[index];
    } else {
      spot = decor?.worldCenterForInteractable(bench);
    }
    final target = spot;
    if (target == null) return;

    final candidates = residents.where((r) => !r.held && !r.airborne && !r.isSitting).toList();
    if (candidates.isEmpty) return;
    candidates.sort((a, b) => a.position.distanceTo(target).compareTo(b.position.distanceTo(target)));
    final guest = candidates.first;
    guest.inviteSitAt(target);
    spawnPetals(target.clone()..y -= 8, count: 6);
  }

  void _reactCastToBuilding(String buildingId, Vector2 center) {
    const glanceRadius = 220.0;
    final affinity = PlazaBuildingReactions.affinityFor(buildingId);
    final candidates = residents
        .where((r) => !r.held && !r.airborne && r.position.distanceTo(center) < glanceRadius)
        .toList();
    if (candidates.isEmpty) return;

    final preferred = candidates.where((r) => affinity.contains(r.config.id)).toList();
    final pool = preferred.isNotEmpty ? preferred : candidates;
    pool.sort((a, b) => a.position.distanceTo(center).compareTo(b.position.distanceTo(center)));
    final reactCount = min(2, pool.length);
    for (var i = 0; i < reactCount; i++) {
      pool[i].glanceToward(center);
      if (buildingId == 'mariachi_stage' && _random.nextDouble() < 0.45) {
        pool[i].applyDancePulse();
      }
    }
  }

  void _tickRareEvents(double dt) {
    if (reduceMotion.value || residents.isEmpty) return;
    _rareEventTimer -= dt;
    if (_rareEventTimer > 0) return;
    _rareEventTimer = PlazaRareEvents.minIntervalSeconds +
        _random.nextDouble() *
            (PlazaRareEvents.maxIntervalSeconds - PlazaRareEvents.minIntervalSeconds);
    if (_random.nextDouble() > PlazaRareEvents.triggerChance) return;
    _triggerRareEvent(PlazaRareEvents.pickKind(_random));
  }

  void _triggerRareEvent(PlazaRareEventKind kind) {
    toyStatus.value = PlazaRareEvents.statusLine(kind);
    switch (kind) {
      case PlazaRareEventKind.shootingStar:
        add(ShootingStar(size: size.clone()));
      case PlazaRareEventKind.balloon:
        add(DriftBalloon(size: size.clone(), color: PlazaRareEvents.balloonColor(_random)));
        spawnPetals(
          Vector2(size.x * 0.78, size.y * 0.22),
          count: 6,
        );
      case PlazaRareEventKind.paradeTease:
        add(MusicNotesBurst(size: size.clone()));
        audio.musicSfx();
        for (final resident in residents) {
          if (!resident.held && !resident.airborne && _random.nextDouble() < 0.35) {
            resident.glanceToward(Vector2(size.x * 0.85, size.y * 0.45));
          }
        }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_missionCelebrateTimer > 0) {
      _missionCelebrateTimer -= dt;
      if (_missionCelebrateTimer <= 0) {
        mission.advanceAfterCelebration();
        _persistMission();
        rewardToast.value = null;
        toyStatus.value = 'Next: ${mission.detail.value}';
      }
    }

    _separateFromHeld();
    _tickRareEvents(dt);
    _tickBenchChats(dt);

    if (musicPlaying) {
      _musicTimer -= dt;
      if (_musicTimer <= 0) {
        musicPlaying = false;
      } else if (_random.nextDouble() < dt * 1.2) {
        final dancers = residents.where((r) => !r.held && !r.airborne).toList();
        if (dancers.isNotEmpty) {
          dancers[_random.nextInt(dancers.length)].applyDancePulse();
        }
      }
    }

    final treat = activeTreat;
    if (treat != null && !treat.claimed) {
      for (final id in ['xolo', 'gato']) {
        final critter = _residentsById[id];
        if (critter != null && critter.position.distanceTo(treat.position) < 28) {
          treat.claimed = true;
          treat.removeFromParent();
          activeTreat = null;
          critter.applyDancePulse();
          spawnPetals(critter.position.clone()..y -= 16, count: 12);
          add(SparkleBurst(position: critter.position.clone(), count: 16));
          toyStatus.value = '${critter.config.displayName} gobbled the pan dulce!';
          if (id == 'xolo') {
            final done = mission.reportXoloFed();
            _persistMission();
            if (done) _onMissionComplete();
          }
          break;
        }
      }
    }
  }

  void _tickBenchChats(double dt) {
    if (reduceMotion.value) return;
    _benchChatTimer -= dt;
    if (_benchChatTimer > 0) return;
    _benchChatTimer = 32 + _random.nextDouble() * 28;
    final sitting = residents.where((r) => r.isSitting).toList();
    if (sitting.length < 2) return;
    for (var i = 0; i < sitting.length; i++) {
      for (var j = i + 1; j < sitting.length; j++) {
        if (sitting[i].position.distanceTo(sitting[j].position) < 95) {
          toyStatus.value =
              '${sitting[i].config.displayName} and ${sitting[j].config.displayName} chat on the bench';
          return;
        }
      }
    }
  }

  /// Soft push so held toys don't stack invisibly on top of others.
  void _separateFromHeld() {
    const minDist = 34.0;
    for (final held in residents) {
      if (!held.held) continue;
      for (final other in residents) {
        if (identical(other, held) || other.held || other.airborne) continue;
        final delta = other.position - held.position;
        final dist = delta.length;
        if (dist >= minDist || dist < 0.001) continue;
        final push = delta.normalized() * (minDist - dist);
        other.position = _walkClamp(other.position + push);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    backdrop?.resizeTo(size);
    atmosphere?.resizeTo(size);
    critters?.resizeTo(size);
    occluders?.resizeTo(size);
    if (_residentsReady) {
      _syncResidentBounds();
    }
  }

  @override
  void onRemove() {
    castRoster.removeListener(_onCastRosterChanged);
    audio.dispose();
    super.onRemove();
  }
}

extension on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}
