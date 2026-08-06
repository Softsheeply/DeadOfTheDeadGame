import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Hand-painted-feeling Día de los Muertos plaza backdrop.
/// Modular art from `assets/reference/` will replace these drawn layers
/// once buildings/props are sliced into game-ready PNGs.
class VillageBackdrop extends PositionComponent {
  VillageBackdrop({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: -100);

  final Random _random = Random(7);
  late final List<_Marigold> _marigolds;
  late final List<_Lantern> _lanterns;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _marigolds = List.generate(28, (_) {
      return _Marigold(
        offset: Vector2(
          _random.nextDouble() * size.x,
          size.y * (0.58 + _random.nextDouble() * 0.38),
        ),
        radius: 3 + _random.nextDouble() * 5,
        hueShift: _random.nextDouble(),
      );
    });
    _lanterns = [
      _Lantern(Offset(size.x * 0.18, size.y * 0.52)),
      _Lantern(Offset(size.x * 0.82, size.y * 0.50)),
      _Lantern(Offset(size.x * 0.50, size.y * 0.46)),
    ];
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Sky -- indigo night into warm festival glow near the horizon.
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF1A0F3A),
          Color(0xFF3A1B6E),
          Color(0xFF7A3B8E),
          Color(0xFFE07A3A),
        ],
        stops: const [0.0, 0.45, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.62));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.62), sky);

    // Soft moon.
    final moonCenter = Offset(w * 0.78, h * 0.14);
    canvas.drawCircle(
      moonCenter,
      28,
      Paint()..color = const Color(0x66FFF4C8),
    );
    canvas.drawCircle(
      moonCenter,
      18,
      Paint()..color = const Color(0xEEFFF8DE),
    );

    // Distant mountains.
    final mountainPaint = Paint()..color = const Color(0xFF241246);
    final mountains = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.15, h * 0.38)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.48, h * 0.34)
      ..lineTo(w * 0.68, h * 0.50)
      ..lineTo(w * 0.86, h * 0.36)
      ..lineTo(w, h * 0.48)
      ..lineTo(w, h * 0.62)
      ..lineTo(0, h * 0.62)
      ..close();
    canvas.drawPath(mountains, mountainPaint);

    // Ground plaza.
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF5C2E1E),
          Color(0xFF3A1A14),
          Color(0xFF24100E),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.55, w, h * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.45), ground);

    // Cobble path stripe.
    final pathPaint = Paint()..color = const Color(0x664A3428);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.78),
          width: w * 0.42,
          height: h * 0.28,
        ),
        const Radius.circular(80),
      ),
      pathPaint,
    );

    // Giant marigold tree (hero landmark silhouette).
    _drawMarigoldTree(canvas, Offset(w * 0.5, h * 0.58), w);

    // Simple stall silhouettes left/right.
    _drawStall(canvas, Offset(w * 0.12, h * 0.58));
    _drawStall(canvas, Offset(w * 0.88, h * 0.57), scale: 0.9, flip: true);

    // Ofrenda glow in the center-back.
    final ofrendaGlow = Paint()
      ..color = const Color(0x55F39A3C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.56),
        width: 120,
        height: 36,
      ),
      ofrendaGlow,
    );

    for (final lantern in _lanterns) {
      _drawLantern(canvas, lantern.anchor);
    }

    for (final flower in _marigolds) {
      final color = Color.lerp(
        const Color(0xFFF39A3C),
        const Color(0xFFED5791),
        flower.hueShift,
      )!;
      canvas.drawCircle(
        Offset(flower.offset.x, flower.offset.y),
        flower.radius,
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }

    // Soft vignette for pocket-god focus on the plaza.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x00000000),
          Color(0x66110A1C),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.62), radius: h * 0.85),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
  }

  void _drawMarigoldTree(Canvas canvas, Offset base, double w) {
    final trunk = Paint()..color = const Color(0xFF4A2A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base.translate(0, -36), width: 22, height: 80),
        const Radius.circular(8),
      ),
      trunk,
    );

    canvas.drawCircle(
      base.translate(0, -110),
      min(90, w * 0.16),
      Paint()..color = const Color(0xE6F0A23A),
    );
    canvas.drawCircle(
      base.translate(-48, -88),
      42,
      Paint()..color = const Color(0xE6ED5791),
    );
    canvas.drawCircle(
      base.translate(52, -92),
      46,
      Paint()..color = const Color(0xE6F39A3C),
    );
    canvas.drawCircle(
      base.translate(0, -140),
      38,
      Paint()..color = const Color(0xCC47C4BA),
    );
  }

  void _drawStall(
    Canvas canvas,
    Offset base, {
    double scale = 1,
    bool flip = false,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(flip ? -scale : scale, scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-40, -70, 80, 70),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF6B3A8C),
    );
    final roofPath = Path()
      ..moveTo(-48, -66)
      ..lineTo(0, -100)
      ..lineTo(48, -66)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFD4582A));
    canvas.drawRect(
      const Rect.fromLTWH(-22, -48, 18, 22),
      Paint()..color = const Color(0xAAFFE29A),
    );
    canvas.restore();
  }

  void _drawLantern(Canvas canvas, Offset anchor) {
    canvas.drawLine(
      anchor,
      anchor.translate(0, -46),
      Paint()
        ..color = const Color(0xFF2B2131)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      anchor.translate(0, -52),
      14,
      Paint()
        ..color = const Color(0x88F39A3C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: anchor.translate(0, -52),
          width: 16,
          height: 22,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF4C15A),
    );
  }
}

class _Marigold {
  final Vector2 offset;
  final double radius;
  final double hueShift;

  const _Marigold({
    required this.offset,
    required this.radius,
    required this.hueShift,
  });
}

class _Lantern {
  final Offset anchor;

  const _Lantern(this.anchor);
}
