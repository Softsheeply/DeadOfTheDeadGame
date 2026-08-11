import 'dart:convert';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'village_backdrop.dart';

class PlazaBuilding {
  PlazaBuilding({
    required this.id,
    required this.label,
    required this.centerUv,
    required this.hitSize,
    required this.status,
  });

  final String id;
  final String label;
  final Offset centerUv;
  final Size hitSize;
  final String status;
}

class DecorFxMarker {
  DecorFxMarker({
    required this.type,
    required this.uv,
    this.strength = 1,
    this.radius,
    this.size,
  });

  final String type;
  final Offset uv;
  final double strength;
  final Offset? radius;
  final Size? size;
}

/// Tappable plaza props: fountain, river, benches (data-driven).
class PlazaInteractable {
  PlazaInteractable({
    required this.id,
    required this.label,
    required this.kind,
    required this.centerUv,
    required this.hitSize,
    required this.status,
    this.restIndex,
  });

  final String id;
  final String label;
  final String kind;
  final Offset centerUv;
  final Size hitSize;
  final String status;

  /// Index into location restSpotUvs when [kind] is bench.
  final int? restIndex;
}

/// Data-driven plaza buildings + FX markers loaded from decor_markers.json.
class VillageDecor extends Component {
  VillageDecor({required this.backdrop});

  final VillageBackdrop backdrop;
  final List<PlazaBuilding> buildings = [];
  final List<DecorFxMarker> fxMarkers = [];
  final List<PlazaInteractable> interactables = [];

  static const assetPath = 'assets/images/village/decor_markers.json';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    for (final entry in (json['buildings'] as List<dynamic>)) {
      final map = entry as Map<String, dynamic>;
      final center = (map['center'] as List<dynamic>).cast<num>();
      final hit = (map['hitSize'] as List<dynamic>).cast<num>();
      buildings.add(
        PlazaBuilding(
          id: map['id'] as String,
          label: map['label'] as String,
          centerUv: Offset(center[0].toDouble(), center[1].toDouble()),
          hitSize: Size(hit[0].toDouble(), hit[1].toDouble()),
          status: map['status'] as String,
        ),
      );
    }

    for (final entry in (json['fx'] as List<dynamic>)) {
      final map = entry as Map<String, dynamic>;
      final uv = (map['uv'] as List<dynamic>).cast<num>();
      Offset? radius;
      Size? size;
      if (map['radius'] is List) {
        final r = (map['radius'] as List<dynamic>).cast<num>();
        radius = Offset(r[0].toDouble(), r[1].toDouble());
      }
      if (map['size'] is List) {
        final s = (map['size'] as List<dynamic>).cast<num>();
        size = Size(s[0].toDouble(), s[1].toDouble());
      }
      fxMarkers.add(
        DecorFxMarker(
          type: map['type'] as String,
          uv: Offset(uv[0].toDouble(), uv[1].toDouble()),
          strength: (map['strength'] as num?)?.toDouble() ?? 1,
          radius: radius,
          size: size,
        ),
      );
    }

    final rawInteractables = json['interactables'];
    if (rawInteractables is List<dynamic>) {
      for (final entry in rawInteractables) {
        final map = entry as Map<String, dynamic>;
        final center = (map['center'] as List<dynamic>).cast<num>();
        final hit = (map['hitSize'] as List<dynamic>).cast<num>();
        interactables.add(
          PlazaInteractable(
            id: map['id'] as String,
            label: map['label'] as String,
            kind: map['kind'] as String,
            centerUv: Offset(center[0].toDouble(), center[1].toDouble()),
            hitSize: Size(hit[0].toDouble(), hit[1].toDouble()),
            status: map['status'] as String,
            restIndex: (map['restIndex'] as num?)?.toInt(),
          ),
        );
      }
    }
  }

  PlazaBuilding? hitTest(Vector2 worldPoint) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return null;

    for (final building in buildings) {
      if (_hitRect(building.centerUv, building.hitSize, draw)
          .contains(Offset(worldPoint.x, worldPoint.y))) {
        return building;
      }
    }
    return null;
  }

  PlazaInteractable? hitTestInteractable(Vector2 worldPoint) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return null;

    for (final prop in interactables) {
      if (_hitRect(prop.centerUv, prop.hitSize, draw)
          .contains(Offset(worldPoint.x, worldPoint.y))) {
        return prop;
      }
    }
    return null;
  }

  Vector2? worldCenterForBuilding(PlazaBuilding building) =>
      worldCenterFor(building.centerUv);

  Vector2? worldCenterForInteractable(PlazaInteractable prop) =>
      worldCenterFor(prop.centerUv);

  Vector2? worldCenterFor(Offset centerUv) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return null;
    return Vector2(
      draw.left + draw.width * centerUv.dx,
      draw.top + draw.height * centerUv.dy,
    );
  }

  Rect _hitRect(Offset centerUv, Size hitSize, Rect draw) {
    final center = Offset(
      draw.left + draw.width * centerUv.dx,
      draw.top + draw.height * centerUv.dy,
    );
    final halfW = draw.width * hitSize.width * 0.5;
    final halfH = draw.height * hitSize.height * 0.5;
    return Rect.fromLTRB(
      center.dx - halfW,
      center.dy - halfH,
      center.dx + halfW,
      center.dy + halfH,
    );
  }
}
