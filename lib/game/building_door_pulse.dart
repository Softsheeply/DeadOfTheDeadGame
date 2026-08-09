import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Brief door-open squash at a building tap — no new art required.
class BuildingDoorPulse extends PositionComponent {
  BuildingDoorPulse({required Vector2 position, required this.tint})
      : super(
          position: position,
          size: Vector2(28, 36),
          anchor: Anchor.bottomCenter,
          priority: 46,
        );

  final Color tint;
  double _age = 0;
  static const double lifetime = 0.55;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0.0, 1.0);
    final open = sin(t * pi);
    final w = size.x * (0.85 + open * 0.15);
    final h = size.y * (0.55 + open * 0.35);
    final glow = Paint()
      ..color = tint.withValues(alpha: 0.25 * (1 - t))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h * 0.45), width: w + 8, height: h + 6),
        const Radius.circular(4),
      ),
      glow,
    );
    final door = Paint()..color = tint.withValues(alpha: 0.75 * (1 - t * 0.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -h * 0.45), width: w, height: h),
        const Radius.circular(3),
      ),
      door,
    );
    canvas.drawLine(
      Offset(0, -h * 0.45 - h / 2),
      Offset(0, -h * 0.45 + h / 2),
      Paint()
        ..color = const Color(0x66FFF1D1)
        ..strokeWidth = 1.2,
    );
  }
}

Color doorTintForBuilding(String id) {
  return switch (id) {
    'floristeria' => const Color(0xFF733D91),
    'panaderia' => const Color(0xFFE8B86D),
    'mariachi_stage' => const Color(0xFFED5791),
    'church' => const Color(0xFFB8D4FF),
    'mercado' => const Color(0xFFF39A3C),
    _ => const Color(0xFF47C4BA),
  };
}
