import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'village_backdrop.dart';

/// Living plaza overlays: water, candles, buildings, papel, smoke, fireflies.
///
/// Drawn in image space via [VillageBackdrop.drawRect] so markers stay locked
/// to the painted plaza when the screen letterboxes or resizes.
class VillageAtmosphere extends PositionComponent {
  VillageAtmosphere({required this.backdrop})
      : super(priority: -40, position: Vector2.zero());

  final VillageBackdrop backdrop;
  final Random _random = Random(7);

  late final List<_WaterBody> _waters;
  late final List<_Candle> _candles;
  late final List<_BuildingLight> _lights;
  late final List<_PapelFlag> _papel;
  late final List<_SmokePuff> _smoke;
  late final List<_Firefly> _fireflies;
  late final List<_DriftPetal> _petals;
  double _time = 0;
  double _wind = 0;
  double _windSign = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = backdrop.size.clone();

    _waters = [
      _WaterBody(
        center: const Offset(0.575, 0.60),
        radiusX: 0.055,
        radiusY: 0.045,
        rippleCount: 4,
        speed: 1.15,
      ),
      _WaterBody(
        center: const Offset(0.575, 0.655),
        radiusX: 0.035,
        radiusY: 0.028,
        rippleCount: 3,
        speed: 0.95,
      ),
      _WaterBody(
        center: const Offset(0.13, 0.88),
        radiusX: 0.07,
        radiusY: 0.022,
        rippleCount: 3,
        speed: 1.35,
      ),
      _WaterBody(
        center: const Offset(0.20, 0.90),
        radiusX: 0.05,
        radiusY: 0.018,
        rippleCount: 2,
        speed: 1.2,
      ),
    ];

    _candles = [
      for (var i = 0; i < 6; i++)
        _Candle(
          uv: Offset(0.06 + i * 0.035, 0.78 + (i.isEven ? 0.01 : -0.01)),
          phase: i * 0.7,
          strength: 0.9,
        ),
      for (var i = 0; i < 5; i++)
        _Candle(
          uv: Offset(0.50 + i * 0.03, 0.68 + (i % 2) * 0.02),
          phase: 1.2 + i * 0.55,
          strength: 1.05,
        ),
      _Candle(uv: const Offset(0.32, 0.72), phase: 0.4, strength: 0.85),
      _Candle(uv: const Offset(0.38, 0.76), phase: 1.1, strength: 0.85),
      _Candle(uv: const Offset(0.44, 0.70), phase: 2.0, strength: 0.85),
      _Candle(uv: const Offset(0.70, 0.74), phase: 2.6, strength: 0.85),
      _Candle(uv: const Offset(0.78, 0.70), phase: 3.3, strength: 0.85),
      _Candle(uv: const Offset(0.84, 0.76), phase: 4.1, strength: 0.9),
      _Candle(uv: const Offset(0.46, 0.42), phase: 0.2, strength: 1.2, radius: 18),
      _Candle(uv: const Offset(0.50, 0.38), phase: 1.0, strength: 1.15, radius: 16),
      _Candle(uv: const Offset(0.54, 0.44), phase: 1.8, strength: 1.2, radius: 17),
    ];

    _lights = [
      _BuildingLight(
        uv: const Offset(0.115, 0.46),
        size: const Size(0.028, 0.035),
        color: const Color(0xFFFFC46A),
        flicker: true,
      ),
      _BuildingLight(
        uv: const Offset(0.275, 0.50),
        size: const Size(0.04, 0.05),
        color: const Color(0xFFFF8A3A),
        flicker: true,
        breathe: true,
        dayVisible: true,
      ),
      _BuildingLight(
        uv: const Offset(0.62, 0.48),
        size: const Size(0.05, 0.03),
        color: const Color(0xFFFFB87A),
        breathe: true,
      ),
      _BuildingLight(
        uv: const Offset(0.74, 0.48),
        size: const Size(0.03, 0.055),
        color: const Color(0xFFFFD27A),
        flicker: true,
      ),
      _BuildingLight(
        uv: const Offset(0.74, 0.34),
        size: const Size(0.02, 0.025),
        color: const Color(0xFFFFE0A0),
        flicker: true,
      ),
      _BuildingLight(
        uv: const Offset(0.90, 0.46),
        size: const Size(0.025, 0.03),
        color: const Color(0xFFFFC070),
        flicker: true,
      ),
    ];

    const papelColors = [
      Color(0xFFED5791),
      Color(0xFFF39A3C),
      Color(0xFF47C4BA),
      Color(0xFF733D91),
      Color(0xFFFFE066),
      Color(0xFF5B8CFF),
    ];
    _papel = [
      for (var row = 0; row < 2; row++)
        for (var i = 0; i < 14; i++)
          _PapelFlag(
            uv: Offset(0.12 + i * 0.055, 0.14 + row * 0.055 + (i.isEven ? 0.01 : 0)),
            color: papelColors[(i + row * 3) % papelColors.length],
            phase: i * 0.45 + row,
            width: 0.018 + (i % 3) * 0.003,
            height: 0.04 + (i % 2) * 0.01,
          ),
    ];

    _smoke = List.generate(10, (i) {
      return _SmokePuff(
        origin: const Offset(0.30, 0.30),
        age: i / 10,
        drift: 0.4 + _random.nextDouble() * 0.4,
      );
    });

    _fireflies = List.generate(18, (i) {
      return _Firefly(
        uv: Offset(0.15 + _random.nextDouble() * 0.7, 0.35 + _random.nextDouble() * 0.45),
        phase: _random.nextDouble() * pi * 2,
        speed: 0.15 + _random.nextDouble() * 0.25,
      );
    });

    _petals = List.generate(12, (i) {
      return _DriftPetal(
        uv: Offset(_random.nextDouble(), 0.2 + _random.nextDouble() * 0.6),
        phase: _random.nextDouble() * pi * 2,
        speed: 0.03 + _random.nextDouble() * 0.05,
        color: Color.lerp(
          const Color(0xFFF39A3C),
          const Color(0xFFED5791),
          _random.nextDouble(),
        )!,
      );
    });
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
  }

  /// Brief gust from the Wind toy — papel and smoke lean harder.
  void applyGust({required double directionSign}) {
    _windSign = directionSign >= 0 ? 1 : -1;
    _wind = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_wind > 0) {
      _wind = max(0, _wind - dt * 0.55);
    }
    for (final light in _lights) {
      light.update(dt, _random, _time);
    }
    for (final puff in _smoke) {
      puff.age += dt * 0.22 * puff.drift;
      if (puff.age >= 1) {
        puff.age -= 1;
        puff.drift = 0.4 + _random.nextDouble() * 0.45;
      }
    }
    for (final fly in _fireflies) {
      fly.uv = Offset(
        (fly.uv.dx + sin(_time * fly.speed + fly.phase) * dt * 0.02).clamp(0.08, 0.92),
        (fly.uv.dy + cos(_time * fly.speed * 0.8 + fly.phase) * dt * 0.015).clamp(0.28, 0.82),
      );
    }
    final windPush = (0.015 + _wind * 0.05) * _windSign;
    for (final petal in _petals) {
      var x = petal.uv.dx + windPush * dt * 4 + sin(_time + petal.phase) * dt * 0.01;
      x %= 1.0;
      if (x < 0) x += 1;
      var y = petal.uv.dy + petal.speed * dt;
      if (y > 0.9) {
        x = _random.nextDouble();
        y = 0.18 + _random.nextDouble() * 0.1;
      }
      petal.uv = Offset(x, y);
    }
  }

  @override
  void render(Canvas canvas) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return;

    final night = backdrop.nightBlend;
    _renderPapel(canvas, draw);
    _renderWater(canvas, draw);
    _renderSmoke(canvas, draw);
    _renderDriftPetals(canvas, draw);

    if (night > 0.02) {
      _renderCandles(canvas, draw, night);
      _renderBuildingLights(canvas, draw, night);
      _renderFireflies(canvas, draw, night);
    } else {
      _renderBuildingLights(canvas, draw, 0.3, dayOnly: true);
    }
  }

  void _renderPapel(Canvas canvas, Rect draw) {
    final swayAmp = 0.12 + _wind * 0.35;
    for (final flag in _papel) {
      final anchor = Offset(
        draw.left + draw.width * flag.uv.dx,
        draw.top + draw.height * flag.uv.dy,
      );
      final sway =
          sin(_time * 2.2 + flag.phase) * swayAmp + _wind * 0.25 * _windSign;
      final w = draw.width * flag.width;
      final h = draw.height * flag.height;

      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(sway);
      final path = Path()
        ..moveTo(-w * 0.5, 0)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * 0.35, h)
        ..lineTo(-w * 0.35, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = flag.color.withValues(alpha: 0.82),
      );
      // Tiny punched hole suggestion (no clear blend — keeps letterbox intact).
      canvas.drawCircle(
        Offset(0, h * 0.38),
        w * 0.14,
        Paint()..color = const Color(0x55FFF8E8),
      );
      canvas.restore();
    }
  }

  void _renderSmoke(Canvas canvas, Rect draw) {
    for (final puff in _smoke) {
      final t = puff.age;
      final x = draw.left +
          draw.width * (puff.origin.dx + t * 0.03 * _windSign + sin(_time + t * 8) * 0.008);
      final y = draw.top + draw.height * (puff.origin.dy - t * 0.12);
      final radius = draw.width * (0.012 + t * 0.02);
      final alpha = (1 - t) * 0.22;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = const Color(0xFFD8C8B8).withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8),
      );
    }
  }

  void _renderDriftPetals(Canvas canvas, Rect draw) {
    for (final petal in _petals) {
      final pos = Offset(
        draw.left + draw.width * petal.uv.dx,
        draw.top + draw.height * petal.uv.dy,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(_time * 0.8 + petal.phase);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 4),
        Paint()..color = petal.color.withValues(alpha: 0.55),
      );
      canvas.restore();
    }
  }

  void _renderFireflies(Canvas canvas, Rect draw, double night) {
    for (final fly in _fireflies) {
      final pulse = 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * 5 + fly.phase));
      final pos = Offset(
        draw.left + draw.width * fly.uv.dx,
        draw.top + draw.height * fly.uv.dy,
      );
      final alpha = night * pulse;
      canvas.drawCircle(
        pos,
        5,
        Paint()
          ..color = const Color(0xFFB8FF7A).withValues(alpha: 0.18 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        pos,
        1.6,
        Paint()..color = const Color(0xFFE8FFB0).withValues(alpha: 0.85 * alpha),
      );
    }
  }

  void _renderWater(Canvas canvas, Rect draw) {
    for (final body in _waters) {
      final cx = draw.left + draw.width * body.center.dx;
      final cy = draw.top + draw.height * body.center.dy;
      final rx = draw.width * body.radiusX;
      final ry = draw.height * body.radiusY;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        Paint()
          ..color = const Color(0xFF6EC8FF)
              .withValues(alpha: 0.10 + 0.06 * sin(_time * body.speed))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      for (var i = 0; i < body.rippleCount; i++) {
        final phase = (_time * body.speed + i * 0.85) % 1.0;
        final expand = 0.35 + phase * 0.75;
        final alpha = (1 - phase) * 0.28;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: rx * 2 * expand,
            height: ry * 2 * expand,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = const Color(0xFFB8ECFF).withValues(alpha: alpha),
        );
      }
    }
  }

  void _renderCandles(Canvas canvas, Rect draw, double night) {
    for (final candle in _candles) {
      final pos = Offset(
        draw.left + draw.width * candle.uv.dx,
        draw.top + draw.height * candle.uv.dy,
      );
      final flicker = 0.78 +
          0.22 *
              sin(_time * 6.5 + candle.phase) *
              sin(_time * 3.1 + candle.phase * 0.7);
      final radius = candle.radius * (0.9 + 0.15 * flicker) * (0.85 + 0.15 * night);
      final alpha = night * candle.strength * flicker;

      canvas.drawCircle(
        pos,
        radius * 1.8,
        Paint()
          ..color = const Color(0xFFFF9A3C).withValues(alpha: 0.12 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.9),
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = const Color(0xFFFFD27A).withValues(alpha: 0.35 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45),
      );
      canvas.drawCircle(
        pos,
        max(1.5, radius * 0.22),
        Paint()..color = const Color(0xFFFFF2C8).withValues(alpha: 0.75 * alpha),
      );
    }
  }

  void _renderBuildingLights(
    Canvas canvas,
    Rect draw,
    double night, {
    bool dayOnly = false,
  }) {
    for (final light in _lights) {
      if (dayOnly && !light.dayVisible) continue;

      final strength = light.dayVisible
          ? max(night, dayOnly ? 0.35 : night) * light.alpha
          : night * light.alpha;
      if (strength < 0.02) continue;

      final rect = Rect.fromCenter(
        center: Offset(
          draw.left + draw.width * light.uv.dx,
          draw.top + draw.height * light.uv.dy,
        ),
        width: draw.width * light.size.width,
        height: draw.height * light.size.height,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(rect.width * 0.35),
          const Radius.circular(6),
        ),
        Paint()
          ..color = light.color.withValues(alpha: 0.18 * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = light.color.withValues(alpha: 0.55 * strength),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(rect.width * 0.25),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: 0.35 * strength),
      );
    }
  }
}

class _WaterBody {
  _WaterBody({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.rippleCount,
    required this.speed,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final int rippleCount;
  final double speed;
}

class _Candle {
  _Candle({
    required this.uv,
    required this.phase,
    required this.strength,
    this.radius = 10,
  });

  final Offset uv;
  final double phase;
  final double strength;
  final double radius;
}

class _BuildingLight {
  _BuildingLight({
    required this.uv,
    required this.size,
    required this.color,
    this.flicker = false,
    this.breathe = false,
    this.dayVisible = false,
  });

  final Offset uv;
  final Size size;
  final Color color;
  final bool flicker;
  final bool breathe;
  final bool dayVisible;
  double alpha = 1;
  double _nextFlicker = 0;
  double _flickerSample = 1;

  void update(double dt, Random random, double time) {
    var value = 1.0;
    if (breathe) {
      value *= 0.78 + 0.22 * sin(time * 1.35);
    }
    if (flicker) {
      _nextFlicker -= dt;
      if (_nextFlicker <= 0) {
        _nextFlicker = 0.12 + random.nextDouble() * 0.4;
        _flickerSample = 0.55 + random.nextDouble() * 0.45;
      }
      value *= _flickerSample;
    }
    alpha = value.clamp(0.4, 1.0);
  }
}

class _PapelFlag {
  _PapelFlag({
    required this.uv,
    required this.color,
    required this.phase,
    required this.width,
    required this.height,
  });

  final Offset uv;
  final Color color;
  final double phase;
  final double width;
  final double height;
}

class _SmokePuff {
  _SmokePuff({
    required this.origin,
    required this.age,
    required this.drift,
  });

  final Offset origin;
  double age;
  double drift;
}

class _Firefly {
  _Firefly({
    required this.uv,
    required this.phase,
    required this.speed,
  });

  Offset uv;
  final double phase;
  final double speed;
}

class _DriftPetal {
  _DriftPetal({
    required this.uv,
    required this.phase,
    required this.speed,
    required this.color,
  });

  Offset uv;
  final double phase;
  final double speed;
  final Color color;
}
