import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'village_backdrop.dart';

/// Tiny ambient butterflies / spark-bugs until real sprite packs arrive.
class AmbientCritters extends PositionComponent {
  AmbientCritters({required this.backdrop})
      : super(priority: 20, position: Vector2.zero());

  final VillageBackdrop backdrop;
  final Random _random = Random(21);
  late final List<_Critter> _critters;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = backdrop.size.clone();
    _critters = List.generate(10, (i) {
      return _Critter(
        uv: Offset(0.15 + _random.nextDouble() * 0.7, 0.25 + _random.nextDouble() * 0.45),
        phase: _random.nextDouble() * pi * 2,
        speed: 0.12 + _random.nextDouble() * 0.2,
        color: i.isEven ? const Color(0xFFF39A3C) : const Color(0xFF5B8CFF),
        wingSpan: 5 + _random.nextDouble() * 3,
      );
    });
  }

  void resizeTo(Vector2 newSize) => size.setFrom(newSize);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final c in _critters) {
      c.uv = Offset(
        (c.uv.dx + sin(_time * c.speed + c.phase) * dt * 0.03).clamp(0.08, 0.92),
        (c.uv.dy + cos(_time * c.speed * 1.1 + c.phase) * dt * 0.02).clamp(0.2, 0.75),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return;
    final night = backdrop.nightBlend;
    for (final c in _critters) {
      final pos = Offset(
        draw.left + draw.width * c.uv.dx,
        draw.top + draw.height * c.uv.dy,
      );
      final flap = 0.55 + 0.45 * sin(_time * 14 + c.phase);
      final alpha = 0.55 + 0.35 * night;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(sin(_time * c.speed + c.phase) * 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-c.wingSpan * flap, 0), width: c.wingSpan, height: c.wingSpan * 0.55),
        Paint()..color = c.color.withValues(alpha: alpha),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.wingSpan * flap, 0), width: c.wingSpan, height: c.wingSpan * 0.55),
        Paint()..color = c.color.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset.zero,
        1.4,
        Paint()..color = const Color(0xFFFFF1D1).withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }
}

class _Critter {
  _Critter({
    required this.uv,
    required this.phase,
    required this.speed,
    required this.color,
    required this.wingSpan,
  });

  Offset uv;
  final double phase;
  final double speed;
  final Color color;
  final double wingSpan;
}
