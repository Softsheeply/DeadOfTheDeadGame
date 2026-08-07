import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../data/character_config.dart';
import 'ambient_critters.dart';
import 'cast_roster.dart';
import 'petal_burst.dart';
import 'resident.dart';
import 'toys.dart';
import 'village_atmosphere.dart';
import 'village_backdrop.dart';
import 'village_decor.dart';

enum VillageToy { wind, petals, music, panDulce }

/// Spirit Village -- living Día de los Muertos plaza with Pocket God toys.
class SpiritVillageGame extends FlameGame with TapCallbacks {
  final List<Resident> residents = [];
  final Map<String, Resident> _residentsById = {};
  final CastRoster castRoster = CastRoster();
  VillageBackdrop? backdrop;
  VillageAtmosphere? atmosphere;
  VillageDecor? decor;
  AmbientCritters? critters;
  PanDulceTreat? activeTreat;
  bool _residentsReady = false;
  bool musicPlaying = false;
  double _musicTimer = 0;
  final Random _random = Random();
  final ValueNotifier<bool> isNight = ValueNotifier<bool>(true);
  final ValueNotifier<String> toyStatus = ValueNotifier<String>('');
  final ValueNotifier<int> castRevision = ValueNotifier<int>(0);
  bool castPanelOpen = false;
  final ValueNotifier<bool> castPanelOpenListenable = ValueNotifier<bool>(false);

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

    await castRoster.load();

    for (final member in kPlazaCast) {
      if (castRoster.isOnPlaza(member.id)) {
        await _spawnCastMember(member, animateEntrance: false);
      }
    }

    castRoster.addListener(_onCastRosterChanged);
    _syncResidentBounds();
    _residentsReady = true;
    _bumpCastRevision();
  }

  void _onCastRosterChanged() {
    // Roster toggles are driven through [setCastPresent] so we can animate.
  }

  @override
  void onTapDown(TapDownEvent event) {
    final building = decor?.hitTest(event.localPosition);
    if (building != null) {
      toyStatus.value = '${building.label}: ${building.status}';
      return;
    }
    if (_tapNearFountain(event.localPosition)) {
      atmosphere?.splashFountain(intensity: 1.15);
      spawnPetals(event.localPosition.clone(), count: 8);
      toyStatus.value = 'The fountain burps marigold mist!';
    }
  }

  bool _tapNearFountain(Vector2 worldPoint) {
    final draw = backdrop?.drawRect;
    if (draw == null || draw == Rect.zero) return false;
    final fx = draw.left + draw.width * VillageBackdrop.fountainCenterUv.dx;
    final fy = draw.top + draw.height * VillageBackdrop.fountainCenterUv.dy;
    final nx = (worldPoint.x - fx) / (draw.width * VillageBackdrop.fountainRadiusX * 1.8);
    final ny = (worldPoint.y - fy) / (draw.height * VillageBackdrop.fountainRadiusY * 1.8);
    return nx * nx + ny * ny <= 1;
  }

  void toggleCastPanel() {
    castPanelOpen = !castPanelOpen;
    castPanelOpenListenable.value = castPanelOpen;
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
      ..wanderHotspots = backdrop?.hotspotWorldPoints() ?? const []
      ..preferredHotspots = _preferredHotspotsFor(member)
      ..onPetalBurst = (pos, {int count = 14}) => spawnPetals(pos, count: count);

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

  void _syncResidentBounds() {
    final road = roadRect;
    final hotspots = backdrop?.hotspotWorldPoints() ?? const <Vector2>[];
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
      resident.wanderHotspots = hotspots;
      if (member != null) {
        resident.preferredHotspots = _preferredHotspotsFor(member);
        final side = _displaySizeFor(member.kind);
        if ((resident.size.x - side.x).abs() > 1) {
          resident.setDisplaySize(side);
        }
      }
      if (!resident.allowOffRoad) {
        resident.position = _walkClamp(resident.position);
      }
    }
  }

  void spawnPetals(Vector2 position, {int count = 14}) {
    add(PetalBurst(position: position, count: count));
  }

  void toggleDayNight() {
    backdrop?.toggleDayNight();
    isNight.value = backdrop?.isNight ?? true;
    toyStatus.value =
        isNight.value ? 'Night settles over the plaza' : 'Morning light fills the plaza';
  }

  void useToy(VillageToy toy) {
    switch (toy) {
      case VillageToy.wind:
        _castWind();
      case VillageToy.petals:
        _castPetalRain();
      case VillageToy.music:
        _castMusic();
      case VillageToy.panDulce:
        _castPanDulce();
    }
  }

  void _castWind() {
    add(WindGust(size: size.clone()));
    final sign = _random.nextBool() ? 1.0 : -1.0;
    atmosphere?.applyGust(directionSign: sign);
    for (final resident in residents) {
      resident.applyWind(directionSign: sign);
    }
    // A couple of leaf-scatter petal pops so the gust feels physical.
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
    final road = roadRect;
    for (var i = 0; i < 10; i++) {
      final pos = Vector2(
        road.left + _random.nextDouble() * road.width,
        road.top + _random.nextDouble() * road.height,
      );
      spawnPetals(pos, count: 16);
    }
    for (final resident in residents) {
      if (resident.config.id != 'xolo' && resident.config.id != 'gato') {
        resident.applyDancePulse();
      }
    }
    atmosphere?.splashFountain(intensity: 0.4);
    toyStatus.value = 'Marigold rain!';
  }

  void _castMusic() {
    musicPlaying = true;
    _musicTimer = 4.0;
    add(MusicNotesBurst(size: size.clone()));
    for (final resident in residents) {
      resident.applyDancePulse();
    }
    toyStatus.value = 'Mariachi fills the air — everyone dances!';
  }

  void _castPanDulce() {
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

  @override
  void update(double dt) {
    super.update(dt);

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
          break;
        }
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    backdrop?.resizeTo(size);
    atmosphere?.resizeTo(size);
    critters?.resizeTo(size);
    if (_residentsReady) {
      _syncResidentBounds();
    }
  }

  @override
  void onRemove() {
    castRoster.removeListener(_onCastRosterChanged);
    super.onRemove();
  }
}

extension on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}
