import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Quick streak across the night sky — rare ambient event.
class ShootingStar extends PositionComponent {
  ShootingStar({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: 55);

  final Random _random = Random();
  late final Vector2 _start;
  late final Vector2 _end;
  double _age = 0;
  static const double lifetime = 1.1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final y = size.y * (0.08 + _random.nextDouble() * 0.18);
    _start = Vector2(size.x * (0.55 + _random.nextDouble() * 0.35), y);
    _end = Vector2(size.x * (_random.nextDouble() * 0.35), y + size.y * 0.08);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0.0, 1.0);
    final fade = t < 0.15 ? t / 0.15 : (1 - (t - 0.15) / 0.85).clamp(0.0, 1.0);
    final head = _start + (_end - _start) * t;
    final tail = head - (_end - _start).normalized() * (36 + 24 * (1 - t));
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x00FFF1D1),
          Color.fromRGBO(255, 241, 209, 0.85 * fade),
          const Color(0xFFFFE066),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromPoints(Offset(tail.x, tail.y), Offset(head.x, head.y)))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(tail.x, tail.y), Offset(head.x, head.y), paint);
    canvas.drawCircle(
      Offset(head.x, head.y),
      2.8 * fade,
      Paint()..color = Color.fromRGBO(255, 255, 220, 0.95 * fade),
    );
  }
}

/// Marigold balloon drifting overhead — rare ambient event.
class DriftBalloon extends PositionComponent {
  DriftBalloon({required Vector2 size, required this.color})
      : super(size: size, position: Vector2.zero(), priority: 48);

  final Color color;
  final Random _random = Random();
  late final Vector2 _offset;
  late final double _sway;
  late final double _phase;
  double _age = 0;
  static const double lifetime = 5.2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _offset = Vector2(
      size.x * (0.72 + _random.nextDouble() * 0.18),
      size.y * (0.72 + _random.nextDouble() * 0.12),
    );
    _sway = 16 + _random.nextDouble() * 18;
    _phase = _random.nextDouble() * pi * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _offset.y -= 28 * dt;
    _offset.x += sin(_age * 1.4 + _phase) * _sway * dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fadeIn = (_age / 0.5).clamp(0.0, 1.0);
    final fadeOut = (1 - (_age - (lifetime - 0.8)) / 0.8).clamp(0.0, 1.0);
    final alpha = min(fadeIn, fadeOut);
    canvas.save();
    canvas.translate(_offset.x, _offset.y);
    final stringPaint = Paint()
      ..color = Color.fromRGBO(255, 241, 209, 0.55 * alpha)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 10), const Offset(0, 34), stringPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 18, height: 22),
      Paint()..color = color.withValues(alpha: 0.88 * alpha),
    );
    canvas.drawCircle(
      const Offset(-3, -4),
      3,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * alpha),
    );
    canvas.restore();
  }
}

/// Building-specific flavor lines and cast affinities for tap reactions.
class PlazaBuildingReactions {
  const PlazaBuildingReactions._();

  static const castAffinity = <String, List<String>>{
    'floristeria': ['pepita', 'miguel', 'pinto'],
    'panaderia': ['chavo', 'don_mateo', 'abuela_rosa'],
    'mariachi_stage': ['tito', 'chavo', 'miguel'],
    'church': ['dona_luz', 'abuela_rosa'],
    'mercado': ['senor_cuervo', 'pinto', 'don_mateo'],
  };

  static String flavorLine(String buildingId, String defaultStatus) {
    return switch (buildingId) {
      'floristeria' => 'Marigolds spill from the doorway — Pepita’s kingdom.',
      'panaderia' => 'Warm pan dulce scent rolls into the cobble.',
      'mariachi_stage' => 'The stage hums — someone should play.',
      'church' => 'Candlelight breathes under the skull doorway.',
      'mercado' => 'Sugar skulls wink from the stalls.',
      _ => defaultStatus,
    };
  }

  static List<String> affinityFor(String buildingId) =>
      castAffinity[buildingId] ?? const [];
}

enum PlazaRareEventKind { shootingStar, balloon, paradeTease }

/// Picks a rare ambient event (~1 in 8 checks).
class PlazaRareEvents {
  const PlazaRareEvents._();

  static const minIntervalSeconds = 38.0;
  static const maxIntervalSeconds = 72.0;
  static const triggerChance = 0.14;

  static PlazaRareEventKind pickKind(Random random) {
    final roll = random.nextInt(3);
    return PlazaRareEventKind.values[roll];
  }

  static String statusLine(PlazaRareEventKind kind) {
    return switch (kind) {
      PlazaRareEventKind.shootingStar => 'A shooting star wishes over the plaza…',
      PlazaRareEventKind.balloon => 'A marigold balloon drifts overhead…',
      PlazaRareEventKind.paradeTease => 'Distant drums hint at a parade…',
    };
  }

  static Color balloonColor(Random random) {
    const palette = [
      Color(0xFFED5791),
      Color(0xFFF39A3C),
      Color(0xFF47C4BA),
      Color(0xFF733D91),
    ];
    return palette[random.nextInt(palette.length)];
  }
}
