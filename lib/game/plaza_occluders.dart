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
    // Fountain south rim — characters north of this draw behind the bowl.
    _OccluderDef(
      uv: Offset(0.575, 0.66),
      sortUvY: 0.70,
      radiusX: 0.07,
      radiusY: 0.035,
      color: Color(0xFF6A8FA8),
      alpha: 0.22,
    ),
    // Tree planter / trunk base.
    _OccluderDef(
      uv: Offset(0.50, 0.62),
      sortUvY: 0.73,
      radiusX: 0.045,
      radiusY: 0.05,
      color: Color(0xFF4A3A28),
      alpha: 0.28,
    ),
    // Bridge rail / arch.
    _OccluderDef(
      uv: Offset(0.16, 0.82),
      sortUvY: 0.86,
      radiusX: 0.07,
      radiusY: 0.03,
      color: Color(0xFF7A6A58),
      alpha: 0.25,
    ),
  ];

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
