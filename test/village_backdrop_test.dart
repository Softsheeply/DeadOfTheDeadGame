import 'dart:math';
import 'dart:ui' show Rect;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/village_backdrop.dart';

void main() {
  test('roadRect covers cobble band below building fronts', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);

    final road = backdrop.roadRect;
    expect(road.left, closeTo(1280 * VillageBackdrop.roadLeft, 0.01));
    expect(road.right, closeTo(1280 * VillageBackdrop.roadRight, 0.01));
    expect(road.top, closeTo(426 * VillageBackdrop.roadTop, 0.01));
    expect(road.bottom, closeTo(426 * VillageBackdrop.roadBottom, 0.01));
    expect(VillageBackdrop.roadTop, greaterThan(0.60));
    expect(road.width / 1280, greaterThan(0.75));
    expect(road.height / 426, greaterThan(0.18));
  });

  test('randomRoadPoint stays walkable and avoids fountain/tree/river', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);
    final random = Random(42);
    for (var i = 0; i < 50; i++) {
      final p = backdrop.randomRoadPoint(random);
      expect(backdrop.isWalkable(p), isTrue);
      expect(backdrop.isBlocked(p), isFalse);
    }
  });

  test('clampToWalkable pushes out of the tree planter', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);
    final insideTree = Vector2(1280 * 0.48, 426 * 0.72);
    expect(backdrop.isBlocked(insideTree), isTrue);
    final clamped = backdrop.clampToWalkable(insideTree);
    expect(backdrop.isBlocked(clamped), isFalse);
    expect(backdrop.isWalkable(clamped), isTrue);
  });

  test('doghouse and river stay blocked so cast cannot stand on them', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);

    final doghouse = Vector2(1280 * 0.80, 426 * 0.885);
    expect(backdrop.isBlocked(doghouse), isTrue);
    expect(backdrop.isWalkable(doghouse), isFalse);
    final offDoghouse = backdrop.clampToWalkable(doghouse);
    expect(backdrop.isBlocked(offDoghouse), isFalse);
    expect(backdrop.isWalkable(offDoghouse), isTrue);

    final river = Vector2(1280 * 0.12, 426 * 0.90);
    expect(backdrop.isBlocked(river), isTrue);
    expect(backdrop.isWalkable(river), isFalse);
    final offRiver = backdrop.clampToWalkable(river);
    expect(backdrop.isWalkable(offRiver), isTrue);
  });

  test('hotspotWorldPoints land on the walkable road', () {
    final backdrop = VillageBackdrop(size: Vector2(1280, 426))
      ..drawRect = const Rect.fromLTWH(0, 0, 1280, 426);
    final spots = backdrop.hotspotWorldPoints();
    expect(spots, isNotEmpty);
    for (final spot in spots) {
      expect(backdrop.isWalkable(spot), isTrue);
    }
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
