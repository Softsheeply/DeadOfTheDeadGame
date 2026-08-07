import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'village_backdrop.dart';

/// Living plaza overlays: water ripples, candle flicker, building glow.
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
  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = backdrop.size.clone();

    // UV fractions of the painted plaza (1280×426).
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
      // Stream under the stone bridge (bottom-left).
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
      // Bridge ofrenda
      for (var i = 0; i < 6; i++)
        _Candle(
          uv: Offset(0.06 + i * 0.035, 0.78 + (i.isEven ? 0.01 : -0.01)),
          phase: i * 0.7,
          strength: 0.9,
        ),
      // Fountain rim
      for (var i = 0; i < 5; i++)
        _Candle(
          uv: Offset(0.50 + i * 0.03, 0.68 + (i % 2) * 0.02),
          phase: 1.2 + i * 0.55,
          strength: 1.05,
        ),
      // Plaza ground candles
      _Candle(uv: const Offset(0.32, 0.72), phase: 0.4, strength: 0.85),
      _Candle(uv: const Offset(0.38, 0.76), phase: 1.1, strength: 0.85),
      _Candle(uv: const Offset(0.44, 0.70), phase: 2.0, strength: 0.85),
      _Candle(uv: const Offset(0.70, 0.74), phase: 2.6, strength: 0.85),
      _Candle(uv: const Offset(0.78, 0.70), phase: 3.3, strength: 0.85),
      _Candle(uv: const Offset(0.84, 0.76), phase: 4.1, strength: 0.9),
      // Tree lanterns
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
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    for (final light in _lights) {
      light.update(dt, _random, _time);
    }
  }

  @override
  void render(Canvas canvas) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return;

    final night = backdrop.nightBlend;
    _renderWater(canvas, draw);

    if (night > 0.02) {
      _renderCandles(canvas, draw, night);
      _renderBuildingLights(canvas, draw, night);
    } else {
      // Soft day ember for the bakery oven only.
      _renderBuildingLights(canvas, draw, 0.3, dayOnly: true);
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
