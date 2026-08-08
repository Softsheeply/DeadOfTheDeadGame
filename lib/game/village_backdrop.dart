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
  /// Kept below shop doors / roofs so feet stay on plaza stone.
  static const double roadLeft = 0.08;
  static const double roadRight = 0.94;
  static const double roadTop = 0.66;
  static const double roadBottom = 0.88;

  /// Soft fountain exclusion (UV of painted image) so wander prefers cobble rim.
  static const Offset fountainCenterUv = Offset(0.575, 0.62);
  static const double fountainRadiusX = 0.05;
  static const double fountainRadiusY = 0.07;

  /// Solid obstacles residents must walk around (UV ellipses).
  static const List<(Offset center, double rx, double ry)> blockedEllipses = [
    (fountainCenterUv, fountainRadiusX, fountainRadiusY),
    (Offset(0.48, 0.72), 0.045, 0.045), // central tree planter base
    // River under the bridge + south bend — keep feet out of the water.
    (Offset(0.11, 0.89), 0.12, 0.065),
    (Offset(0.19, 0.92), 0.09, 0.05),
    (Offset(0.07, 0.86), 0.06, 0.05),
    // Doghouse + Xolo on the stoop (roof ~0.69–0.72, base/dog ~0.84).
    // Tall enough that feet cannot slip over the roof band on the north road.
    (Offset(0.682, 0.770), 0.070, 0.090),
    // Grave plot + fence (right of doghouse).
    (Offset(0.78, 0.82), 0.085, 0.07),
  ];

  /// Interesting plaza stops residents like to visit (UV of painted image).
  /// All sit on open cobble in front of buildings — not on doors/roofs.
  static const List<Offset> hotspotUvs = [
    Offset(0.14, 0.74), // floristería front
    Offset(0.28, 0.75), // panadería
    Offset(0.40, 0.78), // west of tree
    Offset(0.58, 0.80), // fountain south rim
    Offset(0.66, 0.74), // mariachi stage apron
    Offset(0.76, 0.76), // church steps
    Offset(0.88, 0.76), // mercado
    Offset(0.22, 0.82), // bridge approach
    Offset(0.48, 0.84), // plaza center south
  ];

  /// Bench / rest UVs (purple bench near fountain, etc.).
  static const List<Offset> restSpotUvs = [
    Offset(0.62, 0.78), // bench east of fountain
    Offset(0.36, 0.80), // west plaza rest
    Offset(0.82, 0.78), // near mercado
  ];

  /// Ofrenda / tree planter — mission target.
  static const Offset ofrendaUv = Offset(0.50, 0.72);

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

  bool isBlocked(Vector2 point) {
    if (drawRect == Rect.zero) return false;
    for (final zone in blockedEllipses) {
      final cx = drawRect.left + drawRect.width * zone.$1.dx;
      final cy = drawRect.top + drawRect.height * zone.$1.dy;
      final rx = drawRect.width * zone.$2;
      final ry = drawRect.height * zone.$3;
      if (rx <= 0 || ry <= 0) continue;
      final nx = (point.x - cx) / rx;
      final ny = (point.y - cy) / ry;
      if (nx * nx + ny * ny < 1) return true;
    }
    return false;
  }

  bool isWalkable(Vector2 point, {bool allowAirborneLift = false}) {
    final road = roadRect;
    final minY = allowAirborneLift ? road.top - road.height * 0.8 : road.top;
    if (point.x < road.left ||
        point.x > road.right ||
        point.y < minY ||
        point.y > road.bottom) {
      return false;
    }
    if (allowAirborneLift && point.y < road.top) return true;
    return !isBlocked(point);
  }

  Vector2 clampToRoad(Vector2 point, {bool allowAirborneLift = false}) {
    return clampToWalkable(point, allowAirborneLift: allowAirborneLift);
  }

  /// Clamp onto the cobble band and push out of trees / fountain / river.
  Vector2 clampToWalkable(Vector2 point, {bool allowAirborneLift = false}) {
    final road = roadRect;
    final minY = allowAirborneLift ? road.top - road.height * 0.8 : road.top;
    var result = Vector2(
      point.x.clamp(road.left, road.right),
      point.y.clamp(minY, road.bottom),
    );
    if (allowAirborneLift && result.y < road.top) return result;
    if (drawRect == Rect.zero) return result;

    for (var attempt = 0; attempt < 10; attempt++) {
      var blocked = false;
      for (final zone in blockedEllipses) {
        final cx = drawRect.left + drawRect.width * zone.$1.dx;
        final cy = drawRect.top + drawRect.height * zone.$1.dy;
        final rx = drawRect.width * zone.$2;
        final ry = drawRect.height * zone.$3;
        if (rx <= 0 || ry <= 0) continue;
        final nx = (result.x - cx) / rx;
        final ny = (result.y - cy) / ry;
        final d2 = nx * nx + ny * ny;
        if (d2 >= 1) continue;
        blocked = true;
        // Prefer pushing toward open plaza south of buildings.
        if (d2 < 1e-6) {
          result = Vector2(cx, cy + ry * 1.2);
        } else {
          final d = sqrt(d2);
          result = Vector2(
            cx + nx / d * rx * 1.18,
            cy + ny / d * ry * 1.18,
          );
        }
        result = Vector2(
          result.x.clamp(road.left, road.right),
          result.y.clamp(minY, road.bottom),
        );
      }
      if (!blocked) return result;
    }

    // Last resort: walk toward the road midline until clear.
    final mid = Vector2(road.center.dx, road.center.dy);
    for (var i = 0; i < 12; i++) {
      result += (mid - result) * 0.2;
      result = Vector2(
        result.x.clamp(road.left, road.right),
        result.y.clamp(minY, road.bottom),
      );
      if (!isBlocked(result)) return result;
    }
    return Vector2(road.center.dx, road.bottom - 4);
  }

  /// True if the open segment [from]→[to] dips into a solid blocker.
  bool segmentBlocked(Vector2 from, Vector2 to, {double samplePx = 10}) {
    final dist = from.distanceTo(to);
    if (dist < 1) return isBlocked(to);
    final steps = max(2, (dist / samplePx).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final p = Vector2(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t,
      );
      if (isBlocked(p)) return true;
    }
    return false;
  }

  /// First blocked ellipse the segment enters, in world space, or null.
  (Vector2 center, double rx, double ry)? firstBlockerOnSegment(
    Vector2 from,
    Vector2 to,
  ) {
    if (drawRect == Rect.zero) return null;
    final dist = from.distanceTo(to);
    final steps = max(2, (dist / 8).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final p = Vector2(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t,
      );
      for (final zone in blockedEllipses) {
        final cx = drawRect.left + drawRect.width * zone.$1.dx;
        final cy = drawRect.top + drawRect.height * zone.$1.dy;
        final rx = drawRect.width * zone.$2;
        final ry = drawRect.height * zone.$3;
        if (rx <= 0 || ry <= 0) continue;
        final nx = (p.x - cx) / rx;
        final ny = (p.y - cy) / ry;
        if (nx * nx + ny * ny < 1) {
          return (Vector2(cx, cy), rx, ry);
        }
      }
    }
    return null;
  }

  /// Walkable points that skirt a blocker: N/S/E/W just outside the ellipse.
  List<Vector2> skirtCandidates(Vector2 center, double rx, double ry) {
    const pad = 1.28;
    final raw = <Vector2>[
      Vector2(center.x, center.y + ry * pad), // south — usually open cobble
      Vector2(center.x, center.y - ry * pad), // north
      Vector2(center.x + rx * pad, center.y), // east
      Vector2(center.x - rx * pad, center.y), // west
      Vector2(center.x + rx * pad * 0.75, center.y + ry * pad * 0.75),
      Vector2(center.x - rx * pad * 0.75, center.y + ry * pad * 0.75),
    ];
    return [
      for (final p in raw)
        if (isWalkable(p)) clampToWalkable(p),
    ];
  }

  /// Path from [from] to [to]: direct if clear, else skirt then destination.
  List<Vector2> routeToward(Vector2 from, Vector2 to) {
    final dest = clampToWalkable(to);
    if (!segmentBlocked(from, dest)) return [dest];

    final hit = firstBlockerOnSegment(from, dest);
    if (hit == null) return [dest];

    final candidates = skirtCandidates(hit.$1, hit.$2, hit.$3);
    Vector2? best;
    var bestScore = double.infinity;
    for (final skirt in candidates) {
      // Prefer skirts that clear both legs of the trip.
      if (segmentBlocked(from, skirt)) continue;
      final viaBlocked = segmentBlocked(skirt, dest);
      final score = from.distanceTo(skirt) +
          skirt.distanceTo(dest) +
          (viaBlocked ? 80 : 0);
      if (score < bestScore) {
        bestScore = score;
        best = skirt;
      }
    }
    if (best == null) {
      // No clean skirt — pick nearest walkable candidate anyway.
      for (final skirt in candidates) {
        final score = from.distanceTo(skirt);
        if (score < bestScore) {
          bestScore = score;
          best = skirt;
        }
      }
    }
    if (best == null) return [dest];
    if (best.distanceTo(dest) < 10) return [best];
    return [best, dest];
  }

  Vector2 randomRoadPoint(Random random) {
    final road = roadRect;
    for (var attempt = 0; attempt < 16; attempt++) {
      final point = Vector2(
        road.left + random.nextDouble() * road.width,
        road.top + random.nextDouble() * road.height,
      );
      if (isWalkable(point)) return point;
    }
    return clampToWalkable(Vector2(road.center.dx, road.center.dy));
  }

  /// World-space hotspot with a little jitter so paths don't stack perfectly.
  Vector2 randomHotspot(Random random) {
    final uv = hotspotUvs[random.nextInt(hotspotUvs.length)];
    final point = uvToWorld(uv);
    return clampToWalkable(
      point +
          Vector2(
            (random.nextDouble() - 0.5) * 28,
            (random.nextDouble() - 0.5) * 16,
          ),
    );
  }

  Vector2 uvToWorld(Offset uv) {
    if (drawRect == Rect.zero) {
      return Vector2(size.x * uv.dx, size.y * uv.dy);
    }
    return Vector2(
      drawRect.left + drawRect.width * uv.dx,
      drawRect.top + drawRect.height * uv.dy,
    );
  }

  List<Vector2> hotspotWorldPoints() =>
      hotspotUvs.map(uvToWorld).map(clampToWalkable).toList(growable: false);

  List<Vector2> restSpotWorldPoints() =>
      restSpotUvs.map(uvToWorld).map(clampToWalkable).toList(growable: false);

  Vector2 get ofrendaWorld => clampToWalkable(uvToWorld(ofrendaUv));

  bool nearOfrenda(Vector2 point, {double radiusFactor = 0.09}) {
    if (drawRect == Rect.zero) return false;
    final o = ofrendaWorld;
    final r = drawRect.width * radiusFactor;
    return point.distanceTo(o) <= r;
  }

  /// Suggested character height so people sit under door height on the art.
  double get personDisplaySize {
    if (drawRect == Rect.zero) return 64;
    return (drawRect.height * 0.18).clamp(44.0, 64.0);
  }

  double get dogDisplaySize => (personDisplaySize * 0.78).clamp(36.0, 52.0);

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
