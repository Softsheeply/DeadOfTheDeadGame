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

/// Data-driven plaza buildings + FX markers loaded from decor_markers.json.
class VillageDecor extends Component {
  VillageDecor({required this.backdrop});

  final VillageBackdrop backdrop;
  final List<PlazaBuilding> buildings = [];
  final List<DecorFxMarker> fxMarkers = [];

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
  }

  PlazaBuilding? hitTest(Vector2 worldPoint) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return null;

    for (final building in buildings) {
      final center = Offset(
        draw.left + draw.width * building.centerUv.dx,
        draw.top + draw.height * building.centerUv.dy,
      );
      final halfW = draw.width * building.hitSize.width * 0.5;
      final halfH = draw.height * building.hitSize.height * 0.5;
      final rect = Rect.fromLTRB(
        center.dx - halfW,
        center.dy - halfH,
        center.dx + halfW,
        center.dy + halfH,
      );
      if (rect.contains(Offset(worldPoint.x, worldPoint.y))) {
        return building;
      }
    }
    return null;
  }
}
