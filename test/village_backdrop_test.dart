import 'dart:math';
import 'dart:ui' show Rect;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/village_backdrop.dart';

void main() {
  test('roadRect covers a wide plaza band from drawRect fractions', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);

    final road = backdrop.roadRect;
    expect(road.left, closeTo(1280 * VillageBackdrop.roadLeft, 0.01));
    expect(road.right, closeTo(1280 * VillageBackdrop.roadRight, 0.01));
    expect(road.top, closeTo(426 * VillageBackdrop.roadTop, 0.01));
    expect(road.bottom, closeTo(426 * VillageBackdrop.roadBottom, 0.01));
    expect(road.width / 1280, greaterThan(0.8));
    expect(road.height / 426, greaterThan(0.35));
  });

  test('randomRoadPoint stays inside the road and usually avoids fountain', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);
    final random = Random(42);
    var insideFountain = 0;
    for (var i = 0; i < 40; i++) {
      final p = backdrop.randomRoadPoint(random);
      expect(p.x, inInclusiveRange(backdrop.roadRect.left, backdrop.roadRect.right));
      expect(p.y, inInclusiveRange(backdrop.roadRect.top, backdrop.roadRect.bottom));
      final fx = 1280 * VillageBackdrop.fountainCenterUv.dx;
      final fy = 426 * VillageBackdrop.fountainCenterUv.dy;
      final nx = (p.x - fx) / (1280 * VillageBackdrop.fountainRadiusX);
      final ny = (p.y - fy) / (426 * VillageBackdrop.fountainRadiusY);
      if (nx * nx + ny * ny < 1) insideFountain++;
    }
    expect(insideFountain, lessThan(8));
  });

  test('nightBlend follows setNight target over time', () {
    final backdrop = VillageBackdrop(size: Vector2(800, 400));
    expect(backdrop.nightBlend, 1);
    backdrop.setNight(false);
    backdrop.update(0.6);
    expect(backdrop.nightBlend, lessThan(1));
    expect(backdrop.nightBlend, greaterThan(0));
    backdrop.update(2.0);
    expect(backdrop.nightBlend, 0);
  });
}
