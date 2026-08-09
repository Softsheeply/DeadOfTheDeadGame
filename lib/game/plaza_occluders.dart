import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'village_backdrop.dart';

/// Painted props sit in the backdrop; these soft caps sell depth so villagers
/// can walk "behind" fountain / tree / bridge when their feet are north of
/// the occluder's sort line.
class PlazaOccluders extends PositionComponent {
  PlazaOccluders({required this.backdrop})
      : super(position: Vector2.zero(), priority: 0);

  final VillageBackdrop backdrop;

  static const _defs = <_OccluderDef>[
    _OccluderDef(
      uv: Offset(0.575, 0.66),
      sortUvY: 0.695,
      radiusX: 0.075,
      radiusY: 0.038,
      color: Color(0xFF6A8FA8),
      alpha: 0.24,
    ),
    _OccluderDef(
      uv: Offset(0.50, 0.615),
      sortUvY: 0.725,
      radiusX: 0.048,
      radiusY: 0.052,
      color: Color(0xFF4A3A28),
      alpha: 0.30,
    ),
    _OccluderDef(
      uv: Offset(0.48, 0.705),
      sortUvY: 0.745,
      radiusX: 0.035,
      radiusY: 0.04,
      color: Color(0xFF3D5028),
      alpha: 0.26,
    ),
    _OccluderDef(
      uv: Offset(0.16, 0.82),
      sortUvY: 0.855,
      radiusX: 0.072,
      radiusY: 0.032,
      color: Color(0xFF7A6A58),
      alpha: 0.27,
    ),
  ];

  /// Caps draw priority so feet north of a sort line tuck behind props.
  int depthPriorityForFeet(double feetY) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return (feetY * 10).round();
    var priority = (feetY * 10).round();
    for (final def in _defs) {
      final lineY = draw.top + draw.height * def.sortUvY;
      final occluderPriority = lineY.round();
      if (feetY < lineY + 8) {
        priority = min(priority, occluderPriority - 3);
      }
    }
    return priority;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = backdrop.size.clone();
    for (final def in _defs) {
      await add(_OccluderSprite(backdrop: backdrop, def: def));
    }
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
    for (final child in children) {
      if (child is _OccluderSprite) child.refresh();
    }
  }
}

class _OccluderDef {
  const _OccluderDef({
    required this.uv,
    required this.sortUvY,
    required this.radiusX,
    required this.radiusY,
    required this.color,
    required this.alpha,
  });

  final Offset uv;
  final double sortUvY;
  final double radiusX;
  final double radiusY;
  final Color color;
  final double alpha;
}

class _OccluderSprite extends PositionComponent {
  _OccluderSprite({required this.backdrop, required this.def})
      : super(anchor: Anchor.center);

  final VillageBackdrop backdrop;
  final _OccluderDef def;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    refresh();
  }

  void refresh() {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return;
    position = Vector2(
      draw.left + draw.width * def.uv.dx,
      draw.top + draw.height * def.uv.dy,
    );
    size = Vector2(draw.width * def.radiusX * 2, draw.height * def.radiusY * 2);
    // Feet-line sort: higher Y draws later (on top).
    priority = (draw.top + draw.height * def.sortUvY).round();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = def.color.withValues(alpha: def.alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.x * 0.7, height: size.y * 0.55),
      Paint()..color = def.color.withValues(alpha: def.alpha * 1.3),
    );
  }
}
