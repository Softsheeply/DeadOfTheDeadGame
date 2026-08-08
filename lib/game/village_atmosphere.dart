import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'village_backdrop.dart';
import 'village_decor.dart';

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
  late final List<_FountainJet> _jets;
  late final List<_WaterDroplet> _droplets;
  late final List<_RiverSpark> _riverSparks;
  late final List<_Candle> _candles;
  late final List<_BuildingLight> _lights;
  late final List<_PapelFlag> _papel;
  late final List<_SmokePuff> _smoke;
  late final List<_Firefly> _fireflies;
  late final List<_DriftPetal> _petals;
  late final List<_FallingLeaf> _leaves;
  late final List<_TreeCanopy> _trees;
  double _time = 0;
  /// Player wind toy strength 0..1.
  double _gust = 0;
  double _gustSign = 1;
  double _fountainSplash = 0;
  /// Gentle always-on breeze (±1), drifts slowly.
  double _breeze = 0.35;
  double _breezeTarget = 0.35;
  double _breezeTimer = 0;

  /// Combined wind amount for overlays (ambient + gust).
  double get _windStrength => (_breeze.abs() * 0.35 + _gust).clamp(0.0, 1.6);
  double get _windSign => _gust > 0.08 ? _gustSign : (_breeze >= 0 ? 1.0 : -1.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = backdrop.size.clone();

    // Painted plaza already has river + fountain water. Coded ripples/jets were
    // landing on cobble (yellow bridge puddles + red plaza spray) — disable
    // until FX can be clipped to a real water mask.
    _waters = const [];

    // Night-only warm lights — positions live in decor_markers.json.
    _candles = await _loadNightCandles();

    _lights = [
      _BuildingLight(
        uv: const Offset(0.115, 0.46),
        size: const Size(0.028, 0.035),
        color: const Color(0xFFFFC46A),
        flicker: true,
        breathe: true,
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
        breathe: true,
      ),
      _BuildingLight(
        uv: const Offset(0.74, 0.34),
        size: const Size(0.02, 0.025),
        color: const Color(0xFFFFE0A0),
        flicker: true,
        breathe: true,
      ),
      _BuildingLight(
        uv: const Offset(0.90, 0.46),
        size: const Size(0.025, 0.03),
        color: const Color(0xFFFFC070),
        flicker: true,
        breathe: true,
      ),
      _BuildingLight(
        uv: const Offset(0.48, 0.40),
        size: const Size(0.022, 0.028),
        color: const Color(0xFFFFB060),
        breathe: true,
        dayVisible: true,
      ),
      _BuildingLight(
        uv: const Offset(0.18, 0.52),
        size: const Size(0.02, 0.022),
        color: const Color(0xFFFFC878),
        flicker: true,
        breathe: true,
      ),
    ];

    // Painted papel picado is already in the backdrop art. Fake coded flags
    // double-stacked on top — leave empty until we have real animated sheets.
    _papel = const [];

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

    const leafColors = [
      Color(0xFFD97706),
      Color(0xFFB45309),
      Color(0xFFCA8A04),
      Color(0xFFA16207),
      Color(0xFF854D0E),
      Color(0xFF65A30D),
    ];
    _leaves = List.generate(16, (i) {
      return _FallingLeaf(
        uv: Offset(_random.nextDouble(), 0.12 + _random.nextDouble() * 0.55),
        phase: _random.nextDouble() * pi * 2,
        speed: 0.04 + _random.nextDouble() * 0.06,
        spin: 0.8 + _random.nextDouble() * 1.6,
        color: leafColors[i % leafColors.length],
        width: 5 + _random.nextDouble() * 4,
        height: 3 + _random.nextDouble() * 2.5,
      );
    });

    // Fountain/river particle FX disabled (see _waters note above).
    _jets = const [];
    _droplets = const [];
    _riverSparks = const [];

    // Soft canopy overlays that sway with breeze (tree is painted; this sells motion).
    _trees = [
      _TreeCanopy(
        uv: const Offset(0.50, 0.42),
        radiusX: 0.11,
        radiusY: 0.14,
        phase: 0.2,
        leafCount: 14,
      ),
      _TreeCanopy(
        uv: const Offset(0.47, 0.38),
        radiusX: 0.05,
        radiusY: 0.06,
        phase: 1.4,
        leafCount: 6,
      ),
      _TreeCanopy(
        uv: const Offset(0.54, 0.40),
        radiusX: 0.05,
        radiusY: 0.055,
        phase: 2.1,
        leafCount: 6,
      ),
    ];
  }

  _WaterDroplet _spawnDroplet({double seed = 0}) {
    final jet = _jets[_random.nextInt(_jets.length)];
    // Keep droplet arcs tight so spray doesn't look like puddles on cobble.
    final arc = 0.12 + _random.nextDouble() * 0.22;
    return _WaterDroplet(
      origin: jet.origin,
      angle: jet.angle + (_random.nextDouble() - 0.5) * 0.12,
      height: jet.height * (0.7 + _random.nextDouble() * 0.45),
      age: seed,
      life: 0.55 + _random.nextDouble() * 0.45,
      size: 1.2 + _random.nextDouble() * 1.6,
      arc: arc,
    );
  }

  /// Candles / lanterns from decor_markers — only drawn when nightBlend > 0.
  Future<List<_Candle>> _loadNightCandles() async {
    try {
      final raw = await rootBundle.loadString(VillageDecor.assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fx = (json['fx'] as List<dynamic>);
      final loaded = <_Candle>[];
      var phase = 0.0;
      for (final entry in fx) {
        final map = entry as Map<String, dynamic>;
        final type = map['type'] as String?;
        if (type != 'candle' && type != 'lantern') continue;
        final uv = (map['uv'] as List<dynamic>).cast<num>();
        final strength = (map['strength'] as num?)?.toDouble() ?? 1;
        var radius = type == 'lantern' ? 16.0 : 10.0;
        if (map['radius'] is List) {
          final r = (map['radius'] as List<dynamic>).cast<num>();
          radius = r[0].toDouble();
        }
        loaded.add(
          _Candle(
            uv: Offset(uv[0].toDouble(), uv[1].toDouble()),
            phase: phase,
            strength: strength,
            radius: radius,
            isLantern: type == 'lantern',
          ),
        );
        phase += 0.55;
      }
      if (loaded.isNotEmpty) return loaded;
    } catch (_) {
      // Fall through to built-in night ofrenda layout.
    }
    return [
      for (var i = 0; i < 6; i++)
        _Candle(
          uv: Offset(0.06 + i * 0.035, 0.78 + (i.isEven ? 0.01 : -0.01)),
          phase: i * 0.7,
          strength: 0.9,
        ),
      _Candle(uv: const Offset(0.46, 0.42), phase: 0.2, strength: 1.2, radius: 18, isLantern: true),
      _Candle(uv: const Offset(0.50, 0.38), phase: 1.0, strength: 1.15, radius: 16, isLantern: true),
      _Candle(uv: const Offset(0.54, 0.44), phase: 1.8, strength: 1.2, radius: 17, isLantern: true),
    ];
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
  }

  /// Brief gust from the Wind toy — flags/trees lean hard; ambient breeze keeps going.
  void applyGust({required double directionSign}) {
    _gustSign = directionSign >= 0 ? 1 : -1;
    _gust = 1.0;
    _breeze = directionSign >= 0 ? 1.0 : -1.0;
    splashFountain(intensity: 0.85);
  }

  /// Extra fountain thrash — wind toy or a tap on the fountain.
  void splashFountain({double intensity = 1}) {
    // Soft mist ring only — free jets/droplets spilled onto cobble.
    _fountainSplash = (_fountainSplash + intensity).clamp(0.0, 1.6);
  }

  /// Tap-to-light a nearby candle/lantern. Returns true if one was newly lit.
  bool tryLightCandle(Vector2 worldPoint, {double maxDist = 42}) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return false;
    _Candle? best;
    var bestDist = maxDist;
    for (final candle in _candles) {
      if (candle.playerLit) continue;
      final pos = Offset(
        draw.left + draw.width * candle.uv.dx,
        draw.top + draw.height * candle.uv.dy,
      );
      final d = (Offset(worldPoint.x, worldPoint.y) - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        best = candle;
      }
    }
    final hit = best;
    if (hit == null) return false;
    hit.playerLit = true;
    hit.glowBoost = 1.4;
    hit.strength = (hit.strength * 1.25).clamp(0.9, 1.8);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Ambient breeze slowly drifts left/right — always a little motion.
    _breezeTimer -= dt;
    if (_breezeTimer <= 0) {
      _breezeTimer = 2.5 + _random.nextDouble() * 4.5;
      _breezeTarget = (_random.nextBool() ? 1 : -1) * (0.25 + _random.nextDouble() * 0.55);
    }
    _breeze += (_breezeTarget - _breeze) * min(1, dt * 0.35);

    if (_gust > 0) {
      _gust = max(0, _gust - dt * 0.55);
    }
    if (_fountainSplash > 0) {
      _fountainSplash = max(0, _fountainSplash - dt * 0.9);
    }
    for (final candle in _candles) {
      if (candle.glowBoost > 0) {
        candle.glowBoost = max(0, candle.glowBoost - dt * 0.55);
      }
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
    final windPush = (0.012 + _windStrength * 0.05) * _windSign;
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
    final leafWind = (0.015 + _windStrength * 0.08) * _windSign;
    for (final leaf in _leaves) {
      var x = leaf.uv.dx +
          leafWind * dt * 3.5 +
          sin(_time * 1.4 + leaf.phase) * dt * 0.018;
      x %= 1.0;
      if (x < 0) x += 1;
      var y = leaf.uv.dy + leaf.speed * dt * (1 + _windStrength * 0.6);
      if (y > 0.92) {
        x = _random.nextDouble();
        y = 0.08 + _random.nextDouble() * 0.12;
      }
      leaf.uv = Offset(x, y);
    }
    for (final drop in _droplets) {
      drop.age += dt / drop.life;
      if (drop.age >= 1) {
        final fresh = _spawnDroplet();
        drop.origin = fresh.origin;
        drop.angle = fresh.angle;
        drop.height = fresh.height * (1 + _fountainSplash * 0.35);
        drop.age = 0;
        drop.life = fresh.life;
        drop.size = fresh.size;
        drop.arc = fresh.arc;
      }
    }
    for (final spark in _riverSparks) {
      final flowBoost = 1 + _windStrength * 0.35;
      spark.t += dt * spark.speed * flowBoost;
      if (spark.t >= 1) {
        spark.t -= 1;
        spark.lateral = (_random.nextDouble() - 0.5) * 0.75;
        spark.size = 1.2 + _random.nextDouble() * 2.2;
        spark.speed = 0.18 + _random.nextDouble() * 0.22;
        final rivers = [
          for (var i = 0; i < _waters.length; i++)
            if (_waters[i].kind == _WaterKind.river) i,
        ];
        spark.bodyIndex = rivers[_random.nextInt(rivers.length)];
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final draw = backdrop.drawRect;
    if (draw == Rect.zero) return;

    final night = backdrop.nightBlend;
    if (_papel.isNotEmpty) {
      _renderPapel(canvas, draw);
    }
    _renderTrees(canvas, draw);
    _renderWater(canvas, draw);
    _renderSmoke(canvas, draw);
    _renderDriftPetals(canvas, draw);
    _renderLeaves(canvas, draw);

    if (night > 0.02) {
      _renderCandles(canvas, draw, night);
      _renderBuildingLights(canvas, draw, night);
      _renderFireflies(canvas, draw, night);
    } else {
      _renderBuildingLights(canvas, draw, 0.3, dayOnly: true);
    }
  }

  void _renderPapel(Canvas canvas, Rect draw) {
    // Ambient sway always; player gust leans flags hard.
    final swayAmp = 0.08 + _breeze.abs() * 0.12 + _gust * 0.45;
    final lean = _breeze * 0.08 + _gust * 0.35 * _gustSign;
    for (final flag in _papel) {
      final anchor = Offset(
        draw.left + draw.width * flag.uv.dx,
        draw.top + draw.height * flag.uv.dy,
      );
      final sway =
          sin(_time * (1.6 + _breeze.abs()) + flag.phase) * swayAmp + lean;
      final w = draw.width * flag.width;
      final h = draw.height * flag.height * (1 + _gust * 0.08);

      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(sway);
      // Soft second fold so wind reads as fabric, not a rigid board.
      final flutter = sin(_time * 3.4 + flag.phase * 1.7) * (0.04 + _gust * 0.12);
      final path = Path()
        ..moveTo(-w * 0.5, 0)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * (0.35 + flutter), h)
        ..lineTo(-w * (0.35 - flutter), h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = flag.color.withValues(alpha: 0.82),
      );
      canvas.drawCircle(
        Offset(0, h * 0.38),
        w * 0.14,
        Paint()..color = const Color(0x55FFF8E8),
      );
      canvas.restore();
    }
  }

  void _renderTrees(Canvas canvas, Rect draw) {
    final sway =
        sin(_time * 1.15) * (0.025 + _breeze.abs() * 0.03) +
        _gust * 0.09 * _gustSign;
    for (final tree in _trees) {
      final cx = draw.left + draw.width * tree.uv.dx;
      final cy = draw.top + draw.height * tree.uv.dy;
      final rx = draw.width * tree.radiusX;
      final ry = draw.height * tree.radiusY;

      canvas.save();
      canvas.translate(cx, cy + ry * 0.85);
      canvas.rotate(sway * (0.7 + tree.phase * 0.1));
      canvas.translate(0, -ry * 0.85);

      // Soft canopy wash — sells sway without covering the painted trunk art.
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()
          ..color = const Color(0xFF3F7A3A).withValues(alpha: 0.07 + _gust * 0.04)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * 0.25),
      );

      for (var i = 0; i < tree.leafCount; i++) {
        final a = tree.phase + i * 0.9 + _time * 0.4;
        final ox = cos(a) * rx * (0.25 + (i % 5) * 0.12);
        final oy = sin(a * 0.85) * ry * (0.2 + (i % 4) * 0.1);
        final leafSway = sin(_time * 2.2 + a) * (2 + _gust * 5) * _windSign;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ox + leafSway, oy),
            width: 7 + (i % 3) * 2,
            height: 4 + (i % 2),
          ),
          Paint()
            ..color = Color.lerp(
              const Color(0xFF5FA84A),
              const Color(0xFFF39A3C),
              (i % 4) / 5,
            )!.withValues(alpha: 0.28 + _gust * 0.1),
        );
      }
      canvas.restore();
    }
  }

  void _renderSmoke(Canvas canvas, Rect draw) {
    for (final puff in _smoke) {
      final t = puff.age;
      final x = draw.left +
          draw.width *
              (puff.origin.dx +
                  t * 0.03 * _windSign +
                  sin(_time + t * 8) * 0.008);
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

  void _renderLeaves(Canvas canvas, Rect draw) {
    for (final leaf in _leaves) {
      final pos = Offset(
        draw.left + draw.width * leaf.uv.dx,
        draw.top + draw.height * leaf.uv.dy,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(_time * leaf.spin + leaf.phase);
      final path = Path()
        ..moveTo(0, -leaf.height)
        ..quadraticBezierTo(leaf.width, 0, 0, leaf.height)
        ..quadraticBezierTo(-leaf.width, 0, 0, -leaf.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = leaf.color.withValues(alpha: 0.62),
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
    // Mild splash bloom — large splashBoost made the bowl look like a plaza puddle.
    final splashBoost = 1 + _fountainSplash * 0.22;

    for (final body in _waters) {
      final cx = draw.left + draw.width * body.center.dx;
      final cy = draw.top + draw.height * body.center.dy;
      final rx = draw.width * body.radiusX * (body.kind == _WaterKind.fountain ? splashBoost : 1);
      final ry = draw.height * body.radiusY * (body.kind == _WaterKind.fountain ? splashBoost : 1);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        Paint()
          ..color = const Color(0xFF6EC8FF)
              .withValues(alpha: 0.10 + 0.06 * sin(_time * body.speed) +
                  (body.kind == _WaterKind.fountain ? _fountainSplash * 0.08 : 0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      if (body.kind == _WaterKind.fountain) {
        final sheenX = cx + sin(_time * body.speed * 0.7) * rx * 0.35;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(sheenX, cy - ry * 0.15),
            width: rx * 0.55,
            height: ry * 0.28,
          ),
          Paint()
            ..color = const Color(0xFFE8F8FF).withValues(alpha: 0.12 + _fountainSplash * 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      for (var i = 0; i < body.rippleCount; i++) {
        if (body.kind == _WaterKind.river) {
          // Downstream-traveling crescents instead of expanding rings.
          final phase = (_time * body.speed * 0.55 + i * 0.4) % 1.0;
          final flow = body.flow;
          final px = cx + flow.dx * rx * (phase * 2 - 1);
          final py = cy + flow.dy * ry * (phase * 2 - 1);
          final alpha = (1 - (phase - 0.5).abs() * 2) * 0.32;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(px, py),
              width: rx * (0.55 + phase * 0.35),
              height: ry * (0.45 + phase * 0.25),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3
              ..color = const Color(0xFFB8ECFF).withValues(alpha: alpha),
          );
        } else {
          final phase = (_time * body.speed + i * 0.85) % 1.0;
          final expand = 0.35 + phase * 0.75;
          final alpha = (1 - phase) * (0.28 + _fountainSplash * 0.15);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: rx * 2 * expand,
              height: ry * 2 * expand,
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 + _fountainSplash * 0.6
              ..color = const Color(0xFFB8ECFF).withValues(alpha: alpha),
          );
        }
      }
    }

    _renderFountainJets(canvas, draw);
    _renderDroplets(canvas, draw);
    _renderRiverSparks(canvas, draw);

    if (_fountainSplash > 0.05) {
      final fx = draw.left + draw.width * VillageBackdrop.fountainCenterUv.dx;
      final fy = draw.top + draw.height * VillageBackdrop.fountainCenterUv.dy;
      for (var i = 0; i < 3; i++) {
        final t = ((_time * 1.8 + i * 0.33) % 1.0);
        final r = draw.width * (0.03 + t * 0.06) * (0.8 + _fountainSplash * 0.4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fx, fy + draw.height * 0.01),
            width: r * 2.2,
            height: r * 1.2,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = const Color(0xFFD6F4FF)
                .withValues(alpha: (1 - t) * 0.35 * _fountainSplash.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _renderRiverSparks(Canvas canvas, Rect draw) {
    for (final spark in _riverSparks) {
      final body = _waters[spark.bodyIndex];
      final cx = draw.left + draw.width * body.center.dx;
      final cy = draw.top + draw.height * body.center.dy;
      final rx = draw.width * body.radiusX;
      final ry = draw.height * body.radiusY;
      final flow = body.flow;
      // Move along flow direction from upstream (-flow) to downstream (+flow).
      final t = spark.t;
      final along = t * 2 - 1;
      final perpX = -flow.dy;
      final perpY = flow.dx;
      final x = cx + flow.dx * rx * along + perpX * rx * spark.lateral * 0.55;
      final y = cy + flow.dy * ry * along + perpY * ry * spark.lateral * 0.55;
      final fade = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        spark.size,
        Paint()..color = const Color(0xFFE8F8FF).withValues(alpha: 0.45 * fade),
      );
      // Tiny streak in flow direction.
      canvas.drawLine(
        Offset(x, y),
        Offset(x + flow.dx * 6, y + flow.dy * 5),
        Paint()
          ..color = const Color(0xFFB8ECFF).withValues(alpha: 0.35 * fade)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderFountainJets(Canvas canvas, Rect draw) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final jet in _jets) {
      final ox = draw.left + draw.width * jet.origin.dx;
      final oy = draw.top + draw.height * jet.origin.dy;
      final pulse = 0.85 + 0.15 * sin(_time * 3.2 + jet.phase);
      final h = draw.height * jet.height * pulse * (1 + _fountainSplash * 0.45);
      final reach = draw.width * 0.028 * sin(jet.angle).abs().clamp(0.35, 1.0) +
          draw.width * 0.012;
      final tipX = ox + cos(jet.angle - pi / 2) * reach * (0.6 + 0.4 * pulse);
      final tipY = oy - h;
      final midX = (ox + tipX) * 0.5 + sin(_time * 2.4 + jet.phase) * 3;
      final midY = oy - h * 0.55;

      final path = Path()
        ..moveTo(ox, oy)
        ..quadraticBezierTo(midX, midY, tipX, tipY);

      paint
        ..strokeWidth = 2.2 + _fountainSplash * 0.8
        ..color = const Color(0xFF9EDFFF).withValues(alpha: 0.45 + _fountainSplash * 0.2);
      canvas.drawPath(path, paint);

      paint
        ..strokeWidth = 1.1
        ..color = const Color(0xFFEAF8FF).withValues(alpha: 0.55);
      canvas.drawPath(path, paint);

      // Soft mist at the jet tip.
      canvas.drawCircle(
        Offset(tipX, tipY),
        3.5 + _fountainSplash * 2,
        Paint()
          ..color = const Color(0xFFC8ECFF).withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _renderDroplets(Canvas canvas, Rect draw) {
    for (final drop in _droplets) {
      final t = drop.age.clamp(0.0, 1.0);
      // Parabolic arc: rise then fall back to the pool.
      final rise = 4 * t * (1 - t);
      final ox = draw.left + draw.width * drop.origin.dx;
      final oy = draw.top + draw.height * drop.origin.dy;
      final lateral = draw.width * 0.04 * sin(drop.angle) * t * drop.arc;
      final height = draw.height * drop.height * rise * (1 + _fountainSplash * 0.3);
      final x = ox + lateral + _gust * 6 * _gustSign * t;
      final y = oy - height;
      final alpha = (1 - t) * 0.75;
      canvas.drawCircle(
        Offset(x, y),
        drop.size * (0.7 + rise * 0.5),
        Paint()..color = const Color(0xFFB8ECFF).withValues(alpha: alpha),
      );
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
      final boost = 1 + candle.glowBoost;
      final radius =
          candle.radius * (0.9 + 0.15 * flicker) * (0.85 + 0.15 * night) * boost;
      // Player-lit candles stay faintly visible even in day.
      final dayFloor = candle.playerLit ? 0.35 : 0.0;
      final alpha = (night.clamp(dayFloor, 1.0)) * candle.strength * flicker * boost;

      // Warm ground pool — strongest at full night.
      canvas.drawCircle(
        pos,
        radius * 2.1,
        Paint()
          ..color = const Color(0xFFFF8A3A).withValues(alpha: 0.14 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.05),
      );
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = const Color(0xFFFFD27A).withValues(alpha: 0.38 * alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45),
      );
      canvas.drawCircle(
        pos,
        max(1.5, radius * 0.22),
        Paint()..color = const Color(0xFFFFF2C8).withValues(alpha: 0.8 * alpha),
      );

      // Tiny flame tip so night candles read as fire, not just glow blobs.
      if (!candle.isLantern) {
        final flameH = 4.5 + 2.5 * flicker;
        final flame = Path()
          ..moveTo(pos.dx, pos.dy - flameH)
          ..quadraticBezierTo(pos.dx + 2.2 * flicker, pos.dy - flameH * 0.35, pos.dx, pos.dy + 1)
          ..quadraticBezierTo(pos.dx - 2.2 * flicker, pos.dy - flameH * 0.35, pos.dx, pos.dy - flameH)
          ..close();
        canvas.drawPath(
          flame,
          Paint()..color = const Color(0xFFFFF6C8).withValues(alpha: 0.7 * alpha),
        );
        canvas.drawPath(
          flame,
          Paint()
            ..color = const Color(0xFFFF9A3C).withValues(alpha: 0.35 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
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

      final center = Offset(
        draw.left + draw.width * light.uv.dx,
        draw.top + draw.height * light.uv.dy,
      );
      // Soft circular glow — hard RRect slabs read as grey bars on the art.
      final radius = draw.width * ((light.size.width + light.size.height) * 0.5);

      canvas.drawCircle(
        center,
        radius * 2.4,
        Paint()
          ..color = light.color.withValues(alpha: 0.16 * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.2),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = light.color.withValues(alpha: 0.28 * strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45),
      );
      canvas.drawCircle(
        center,
        max(1.2, radius * 0.28),
        Paint()..color = const Color(0xFFFFF6D8).withValues(alpha: 0.4 * strength),
      );
    }
  }
}

enum _WaterKind { fountain, river }

class _WaterBody {
  _WaterBody({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.rippleCount,
    required this.speed,
    this.kind = _WaterKind.fountain,
    this.flow = Offset.zero,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final int rippleCount;
  final double speed;
  final _WaterKind kind;
  final Offset flow;
}

class _RiverSpark {
  _RiverSpark({
    required this.bodyIndex,
    required this.t,
    required this.lateral,
    required this.size,
    required this.speed,
  });

  int bodyIndex;
  double t;
  double lateral;
  double size;
  double speed;
}

class _TreeCanopy {
  _TreeCanopy({
    required this.uv,
    required this.radiusX,
    required this.radiusY,
    required this.phase,
    required this.leafCount,
  });

  final Offset uv;
  final double radiusX;
  final double radiusY;
  final double phase;
  final int leafCount;
}

class _FountainJet {
  _FountainJet({
    required this.origin,
    required this.angle,
    required this.height,
    required this.phase,
  });

  final Offset origin;
  final double angle;
  final double height;
  final double phase;
}

class _WaterDroplet {
  _WaterDroplet({
    required this.origin,
    required this.angle,
    required this.height,
    required this.age,
    required this.life,
    required this.size,
    required this.arc,
  });

  Offset origin;
  double angle;
  double height;
  double age;
  double life;
  double size;
  double arc;
}

class _Candle {
  _Candle({
    required this.uv,
    required this.phase,
    required this.strength,
    this.radius = 10,
    this.isLantern = false,
  });

  final Offset uv;
  final double phase;
  double strength;
  final double radius;
  final bool isLantern;
  bool playerLit = false;
  double glowBoost = 0;
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

class _FallingLeaf {
  _FallingLeaf({
    required this.uv,
    required this.phase,
    required this.speed,
    required this.spin,
    required this.color,
    required this.width,
    required this.height,
  });

  Offset uv;
  final double phase;
  final double speed;
  final double spin;
  final Color color;
  final double width;
  final double height;
}
