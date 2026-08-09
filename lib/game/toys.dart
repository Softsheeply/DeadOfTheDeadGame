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
    // Soft glow so the treat reads as a toy target.
    canvas.drawCircle(
      Offset(0, y),
      16,
      Paint()
        ..color = const Color(0xFFFFE0A0).withValues(alpha: 0.22 + 0.1 * sin(_bob))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, y), width: 22, height: 14),
      bread,
    );
    canvas.drawCircle(Offset(-4, y - 2), 2.2, sugar);
    canvas.drawCircle(Offset(3, y - 3), 2.0, sugar);
    canvas.drawCircle(Offset(0, y + 1), 1.8, sugar);
  }
}

/// Floating music notes that drift up during the mariachi toy.
class MusicNotesBurst extends PositionComponent {
  MusicNotesBurst({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: 45);

  final Random _random = Random();
  late final List<_Note> _notes;
  double _age = 0;
  static const double lifetime = 3.6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _notes = List.generate(14, (i) {
      return _Note(
        offset: Vector2(
          size.x * (0.18 + _random.nextDouble() * 0.64),
          size.y * (0.55 + _random.nextDouble() * 0.3),
        ),
        speed: 35 + _random.nextDouble() * 55,
        sway: 18 + _random.nextDouble() * 22,
        phase: _random.nextDouble() * pi * 2,
        scale: 0.7 + _random.nextDouble() * 0.7,
        color: i.isEven ? const Color(0xFFFFE066) : const Color(0xFFED5791),
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final note in _notes) {
      note.offset.y -= note.speed * dt;
      note.offset.x += sin(_age * 2.2 + note.phase) * note.sway * dt * 0.35;
    }
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - (_age / lifetime)).clamp(0.0, 1.0);
    for (final note in _notes) {
      canvas.save();
      canvas.translate(note.offset.x, note.offset.y);
      canvas.scale(note.scale);
      canvas.rotate(sin(_age * 3 + note.phase) * 0.25);
      final paint = Paint()
        ..color = note.color.withValues(alpha: 0.75 * fade);
      // Stem
      canvas.drawLine(
        const Offset(4, -10),
        const Offset(4, 6),
        paint
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
      // Note head
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 6), width: 9, height: 6),
        Paint()..color = note.color.withValues(alpha: 0.85 * fade),
      );
      // Flag
      final flag = Path()
        ..moveTo(4, -10)
        ..quadraticBezierTo(14, -6, 10, 0)
        ..lineTo(4, -2)
        ..close();
      canvas.drawPath(
        flag,
        Paint()..color = note.color.withValues(alpha: 0.7 * fade),
      );
      canvas.restore();
    }
  }
}

class _Note {
  _Note({
    required this.offset,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.scale,
    required this.color,
  });

  Vector2 offset;
  final double speed;
  final double sway;
  final double phase;
  final double scale;
  final Color color;
}

/// Quick sparkle pop used when someone claims pan dulce.
class SparkleBurst extends PositionComponent {
  SparkleBurst({required Vector2 position, this.count = 12})
      : super(
          position: position,
          size: Vector2.zero(),
          priority: 50,
        );

  final int count;
  final Random _random = Random();
  late final List<_Spark> _sparks;
  double _age = 0;
  static const double lifetime = 0.7;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sparks = List.generate(count, (_) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 60 + _random.nextDouble() * 120;
      return _Spark(
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        size: 2 + _random.nextDouble() * 3,
        color: Color.lerp(
          const Color(0xFFFFE066),
          const Color(0xFFFFF1D1),
          _random.nextDouble(),
        )!,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final spark in _sparks) {
      spark.velocity.y += 180 * dt;
      spark.offset += spark.velocity * dt;
    }
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = (1 - (_age / lifetime)).clamp(0.0, 1.0);
    for (final spark in _sparks) {
      canvas.drawCircle(
        Offset(spark.offset.x, spark.offset.y),
        spark.size * fade,
        Paint()..color = spark.color.withValues(alpha: 0.9 * fade),
      );
    }
  }
}

class _Spark {
  _Spark({
    required this.velocity,
    required this.size,
    required this.color,
  }) : offset = Vector2.zero();

  Vector2 offset;
  Vector2 velocity;
  final double size;
  final Color color;
}

/// Expanding golden ring when the lantern toy sweeps the plaza.
class LanternRipple extends PositionComponent {
  LanternRipple({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: 42);

  double _age = 0;
  static const double lifetime = 1.4;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / lifetime).clamp(0.0, 1.0);
    final fade = (1 - t).clamp(0.0, 1.0);
    final center = Offset(size.x * 0.5, size.y * 0.58);
    final shortest = size.x < size.y ? size.x : size.y;
    final radius = shortest * (0.12 + t * 0.42);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.fromRGBO(255, 224, 102, 0.22 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * fade,
    );
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()
        ..color = Color.fromRGBO(255, 241, 209, 0.12 * fade)
        ..style = PaintingStyle.fill,
    );
  }
}
