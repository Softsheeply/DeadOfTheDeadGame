import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Soft wind streaks that briefly blow across the plaza.
class WindGust extends PositionComponent {
  WindGust({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: 40);

  final Random _random = Random();
  late final List<_Streak> _streaks;
  double _age = 0;
  static const double lifetime = 1.6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _streaks = List.generate(18, (_) {
      return _Streak(
        offset: Vector2(
          -40 - _random.nextDouble() * 80,
          size.y * (0.35 + _random.nextDouble() * 0.55),
        ),
        length: 40 + _random.nextDouble() * 70,
        speed: 420 + _random.nextDouble() * 280,
        thickness: 1.5 + _random.nextDouble() * 2,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final streak in _streaks) {
      streak.offset.x += streak.speed * dt;
    }
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - (_age / lifetime)).clamp(0.0, 1.0);
    for (final streak in _streaks) {
      final paint = Paint()
        ..color = Color.fromRGBO(255, 241, 209, 0.35 * fade)
        ..strokeWidth = streak.thickness
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(streak.offset.x, streak.offset.y),
        Offset(streak.offset.x + streak.length, streak.offset.y - 6),
        paint,
      );
    }
  }
}

class _Streak {
  Vector2 offset;
  final double length;
  final double speed;
  final double thickness;

  _Streak({
    required this.offset,
    required this.length,
    required this.speed,
    required this.thickness,
  });
}

/// Floating pan dulce crumb that Xolo (or anyone) can chase.
class PanDulceTreat extends PositionComponent {
  PanDulceTreat({required Vector2 position})
      : super(
          position: position,
          size: Vector2(28, 28),
          anchor: Anchor.center,
          priority: 30,
        );

  double _bob = 0;
  bool claimed = false;

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final y = sin(_bob) * 3;
    final bread = Paint()..color = const Color(0xFFE8B86D);
    final sugar = Paint()..color = const Color(0xFFFFF1D1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: 22, height: 14),
      bread,
    );
    canvas.drawCircle(Offset(-4, y - 2), 2.2, sugar);
    canvas.drawCircle(Offset(3, y - 3), 2.0, sugar);
    canvas.drawCircle(Offset(0, y + 1), 1.8, sugar);
  }
}
