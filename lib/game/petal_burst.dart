import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Short-lived marigold/petal burst for family-friendly Pocket God juice.
class PetalBurst extends PositionComponent {
  PetalBurst({required Vector2 position, this.count = 14})
      : super(position: position, priority: 50);

  final int count;
  final Random _random = Random();
  late final List<_Petal> _petals;
  double _age = 0;
  static const double _lifetime = 0.9;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _petals = List.generate(count, (_) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 60 + _random.nextDouble() * 140;
      return _Petal(
        velocity: Vector2(cos(angle), sin(angle) - 0.6) * speed,
        color: Color.lerp(
          const Color(0xFFF39A3C),
          const Color(0xFFED5791),
          _random.nextDouble(),
        )!,
        size: 3 + _random.nextDouble() * 4,
        spin: (_random.nextDouble() - 0.5) * 8,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final petal in _petals) {
      petal.velocity.y += 220 * dt;
      petal.offset += petal.velocity * dt;
      petal.rotation += petal.spin * dt;
    }
    if (_age >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - (_age / _lifetime)).clamp(0.0, 1.0);
    for (final petal in _petals) {
      canvas.save();
      canvas.translate(petal.offset.x, petal.offset.y);
      canvas.rotate(petal.rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: petal.size * 1.6,
          height: petal.size,
        ),
        Paint()..color = petal.color.withValues(alpha: 0.85 * fade),
      );
      canvas.restore();
    }
  }
}

class _Petal {
  Vector2 offset = Vector2.zero();
  Vector2 velocity;
  Color color;
  double size;
  double spin;
  double rotation = 0;

  _Petal({
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
  });
}
