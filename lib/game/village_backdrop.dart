import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

/// Full-bleed Spirit Village backdrop with day/night painted variants.
class VillageBackdrop extends PositionComponent {
  VillageBackdrop({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: -100);

  static const String dayAsset = 'village/spirit_village_plaza_day.png';
  static const String nightAsset = 'village/spirit_village_plaza_night.png';

  Sprite? _day;
  Sprite? _night;
  bool isNight = true;
  double _blend = 1; // 0 = day, 1 = night
  double _blendTarget = 1;
  Rect _drawRect = Rect.zero;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _day = Sprite(await Flame.images.load(dayAsset));
    _night = Sprite(await Flame.images.load(nightAsset));
    _recomputeDrawRect();
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
    _recomputeDrawRect();
  }

  /// Animate toward day (false) or night (true) over ~1.2s.
  void setNight(bool night) {
    isNight = night;
    _blendTarget = night ? 1 : 0;
  }

  void toggleDayNight() => setNight(!isNight);

  void _recomputeDrawRect() {
    final sprite = _night ?? _day;
    if (sprite == null || size.x <= 0 || size.y <= 0) {
      _drawRect = Rect.zero;
      return;
    }
    final imgW = sprite.srcSize.x;
    final imgH = sprite.srcSize.y;
    final scale = max(size.x / imgW, size.y / imgH);
    _drawRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: imgW * scale,
      height: imgH * scale,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if ((_blend - _blendTarget).abs() < 0.001) {
      _blend = _blendTarget;
      return;
    }
    final dir = _blendTarget > _blend ? 1.0 : -1.0;
    _blend = (_blend + dir * dt / 1.2).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_drawRect == Rect.zero) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF1A0F3A),
      );
      return;
    }

    if (_blend < 1 && _day != null) {
      _day!.renderRect(canvas, _drawRect);
    }
    if (_blend > 0 && _night != null) {
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, _blend);
      _night!.renderRect(canvas, _drawRect, overridePaint: paint);
    }

    final vignetteStrength = 0.25 + 0.35 * _blend;
    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x00000000),
          Color.fromRGBO(0, 0, 0, 0.18 * vignetteStrength),
          Color.fromRGBO(12, 6, 24, vignetteStrength),
        ],
        stops: const [0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignette);
  }
}
