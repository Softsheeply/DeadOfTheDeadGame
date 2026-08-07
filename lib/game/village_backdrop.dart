import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

/// Full-bleed Spirit Village backdrop with day/night painted variants.
///
/// Uses *contain* fit so the whole plaza is visible (letterboxed), which
/// reads as more zoomed-out than cover-cropping into the fountain.
class VillageBackdrop extends PositionComponent {
  VillageBackdrop({required Vector2 size})
      : super(size: size, position: Vector2.zero(), priority: -100);

  static const String dayAsset = 'village/spirit_village_plaza_day.png';
  static const String nightAsset = 'village/spirit_village_plaza_night.png';

  /// Walkable cobble band as fractions of the painted image (not the screen).
  /// Wider plaza roam so residents cross fountain rim, stalls, and bridge approach.
  static const double roadLeft = 0.06;
  static const double roadRight = 0.94;
  static const double roadTop = 0.48;
  static const double roadBottom = 0.90;

  /// Soft fountain exclusion (UV of painted image) so wander prefers cobble rim.
  static const Offset fountainCenterUv = Offset(0.575, 0.62);
  static const double fountainRadiusX = 0.045;
  static const double fountainRadiusY = 0.055;

  Sprite? _day;
  Sprite? _night;
  bool isNight = true;
  double _blend = 1;
  double _blendTarget = 1;
  Rect drawRect = Rect.zero;

  /// 0 = full day art, 1 = full night art (animated during transitions).
  double get nightBlend => _blend;

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

  void setNight(bool night) {
    isNight = night;
    _blendTarget = night ? 1 : 0;
  }

  void toggleDayNight() => setNight(!isNight);

  /// Cobblestone road in game/world coordinates.
  Rect get roadRect {
    if (drawRect == Rect.zero) {
      return Rect.fromLTWH(size.x * 0.15, size.y * 0.62, size.x * 0.7, size.y * 0.2);
    }
    return Rect.fromLTRB(
      drawRect.left + drawRect.width * roadLeft,
      drawRect.top + drawRect.height * roadTop,
      drawRect.left + drawRect.width * roadRight,
      drawRect.top + drawRect.height * roadBottom,
    );
  }

  Vector2 clampToRoad(Vector2 point, {bool allowAirborneLift = false}) {
    final road = roadRect;
    final minY = allowAirborneLift ? road.top - road.height * 0.8 : road.top;
    return Vector2(
      point.x.clamp(road.left, road.right),
      point.y.clamp(minY, road.bottom),
    );
  }

  Vector2 randomRoadPoint(Random random) {
    final road = roadRect;
    // Prefer open cobble; reject fountain bowl samples a few times.
    for (var attempt = 0; attempt < 8; attempt++) {
      final point = Vector2(
        road.left + random.nextDouble() * road.width,
        road.top + random.nextDouble() * road.height,
      );
      if (!_insideFountain(point) || attempt == 7) return point;
    }
    return Vector2(road.center.dx, road.center.dy);
  }

  bool _insideFountain(Vector2 point) {
    if (drawRect == Rect.zero) return false;
    final fx = drawRect.left + drawRect.width * fountainCenterUv.dx;
    final fy = drawRect.top + drawRect.height * fountainCenterUv.dy;
    final nx = (point.x - fx) / (drawRect.width * fountainRadiusX);
    final ny = (point.y - fy) / (drawRect.height * fountainRadiusY);
    return nx * nx + ny * ny < 1;
  }

  /// Suggested character height so people sit under door height on the art.
  double get personDisplaySize {
    if (drawRect == Rect.zero) return 64;
    return (drawRect.height * 0.20).clamp(48.0, 72.0);
  }

  double get dogDisplaySize => (personDisplaySize * 0.78).clamp(40.0, 58.0);

  void _recomputeDrawRect() {
    final sprite = _night ?? _day;
    if (sprite == null || size.x <= 0 || size.y <= 0) {
      drawRect = Rect.zero;
      return;
    }
    final imgW = sprite.srcSize.x;
    final imgH = sprite.srcSize.y;
    // Contain = see the whole town (zoom out vs cover).
    final scale = min(size.x / imgW, size.y / imgH);
    final drawW = imgW * scale;
    final drawH = imgH * scale;
    drawRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: drawW,
      height: drawH,
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
    // Letterbox fill behind the contained plaza.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF120A24),
    );

    if (drawRect == Rect.zero) return;

    if (_blend < 1 && _day != null) {
      _day!.renderRect(canvas, drawRect);
    }
    if (_blend > 0 && _night != null) {
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, _blend);
      _night!.renderRect(canvas, drawRect, overridePaint: paint);
    }
  }
}
