import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/village_backdrop.dart';

void _settle(VillageBackdrop backdrop) {
  for (var i = 0; i < 200; i++) {
    backdrop.update(0.05);
  }
}

void main() {
  test('celestial tap hit-test tracks sun in day mode', () {
    final backdrop = VillageBackdrop(size: Vector2(390, 844));
    backdrop.drawRect = const Rect.fromLTWH(0, 209, 390, 130);
    backdrop.setNight(false);
    _settle(backdrop);

    final sun = backdrop.celestialWorldCenter(isSun: true);
    expect(
      backdrop.hitTestCelestialTap(Vector2(sun.dx, sun.dy)),
      isTrue,
    );
    expect(
      backdrop.hitTestCelestialTap(Vector2(sun.dx + 80, sun.dy)),
      isFalse,
    );
  });

  test('celestial tap hit-test tracks moon in night mode', () {
    final backdrop = VillageBackdrop(size: Vector2(390, 844));
    backdrop.drawRect = const Rect.fromLTWH(0, 209, 390, 130);
    backdrop.setNight(true);
    _settle(backdrop);

    final moon = backdrop.celestialWorldCenter(isSun: false);
    expect(
      backdrop.hitTestCelestialTap(Vector2(moon.dx, moon.dy)),
      isTrue,
    );
    expect(
      backdrop.hitTestCelestialTap(Vector2(moon.dx + 80, moon.dy)),
      isFalse,
    );
  });
}
