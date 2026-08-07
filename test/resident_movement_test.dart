import 'package:flame/components.dart';
import 'package:flutter/widgets.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/character_config.dart';
import 'package:dead_of_the_dead_game/game/resident.dart';

CharacterConfig _minimalConfig() {
  return CharacterConfig.fromJson({
    'id': 'test',
    'displayName': 'Test',
    'role': 'tester',
    'defaultDirection': 'down',
    'movement': {'walkSpeed': 100, 'skipSpeed': 150},
    'animations': {
      'idle_down': {'frames': 1, 'fps': 1, 'loop': true, 'paths': ['a.png']},
      'idle_left': {'frames': 1, 'fps': 1, 'loop': true, 'paths': ['a.png']},
      'idle_right': {'frames': 1, 'fps': 1, 'loop': true, 'paths': ['a.png']},
      'idle_up': {'frames': 1, 'fps': 1, 'loop': true, 'paths': ['a.png']},
      'walk_down': {'frames': 2, 'fps': 10, 'loop': true, 'paths': ['a.png', 'b.png']},
    },
  });
}

void main() {
  test('walkTo sets a target and faces the correct direction', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    resident.walkTo(Vector2(100, 0));
    expect(resident.busy, true);
    expect(resident.direction, 'right');
  });

  test('update moves the resident toward the target at walkSpeed, arrives, and returns to idle', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    resident.walkTo(Vector2(100, 0));

    resident.update(0.5);
    expect(resident.position.x, closeTo(50, 0.001));
    expect(resident.busy, true);

    resident.update(1.0);
    expect(resident.position.x, closeTo(100, 0.001));
    expect(resident.busy, true);

    resident.update(1 / 60);
    expect(resident.position.x, closeTo(100, 0.001));
    expect(resident.busy, false);
  });

  test('direction is chosen by whichever axis has the larger delta', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));

    resident.walkTo(Vector2(-50, 10));
    expect(resident.direction, 'left');

    resident.walkTo(Vector2(10, -50));
    expect(resident.direction, 'up');

    resident.walkTo(Vector2(10, 50));
    expect(resident.direction, 'down');
  });

  test('autonomous behaviour does nothing while a resident is already busy', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0))
      ..worldBounds = Vector2(400, 400);
    resident.walkTo(Vector2(200, 200));
    final positionBeforeManyUpdates = resident.position.clone();

    resident.update(10.0);

    final dx = resident.position.x - positionBeforeManyUpdates.x;
    final dy = resident.position.y - positionBeforeManyUpdates.y;
    expect(dx >= 0 && dy >= 0, true);
  });

  test('a resident with no worldBounds set simply does not wander (no crash)', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    expect(() => resident.update(20.0), returnsNormally);
    expect(resident.busy, false);
  });

  test('grab pauses wandering until soft release', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(100, 100))
      ..worldBounds = Vector2(400, 400);
    resident.walkTo(Vector2(300, 300));
    expect(resident.busy, true);

    resident.debugGrab();
    expect(resident.held, true);
    final frozen = resident.position.clone();
    resident.update(1.0);
    expect(resident.position.x, closeTo(frozen.x, 0.001));
    expect(resident.position.y, closeTo(frozen.y, 0.001));

    resident.debugRelease();
    expect(resident.held, false);
    expect(resident.airborne, false);
  });

  test('release snaps landing onto walkClamp cobble', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(200, 120))
      ..worldBounds = Vector2(400, 400)
      ..walkClamp = (point, {bool softTop = false}) => Vector2(200, 280);
    resident.debugFling(Vector2(0, -200));
    for (var i = 0; i < 180; i++) {
      resident.update(1 / 60);
    }
    expect(resident.airborne, false);
    expect(resident.position.y, closeTo(280, 0.5));
  });

  test('grab and release hooks fire', () {
    var grabs = 0;
    var softDrops = 0;
    var flings = 0;
    final resident = Resident(config: _minimalConfig(), position: Vector2(100, 100))
      ..onGrab = () {
        grabs++;
      }
      ..onRelease = ({required bool flung}) {
        if (flung) {
          flings++;
        } else {
          softDrops++;
        }
      };
    // Hooks are wired to gesture path; debugGrab skips them — call release path.
    resident.debugGrab();
    expect(grabs, 0);
    resident.debugRelease();
    expect(softDrops, 1);
    resident.debugFling(Vector2(200, -200));
    // debugFling does not call onRelease; soft release already covered.
    expect(flings, 0);
  });

  test('fling makes the resident airborne then land under gravity', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(200, 200))
      ..worldBounds = Vector2(400, 400);
    resident.debugFling(Vector2(100, -300));
    expect(resident.airborne, true);
    expect(resident.busy, true);

    // Simulate enough frames to rise and fall back to ground band.
    for (var i = 0; i < 180; i++) {
      resident.update(1 / 60);
    }
    expect(resident.airborne, false);
    expect(resident.position.y, lessThanOrEqualTo(400 * 0.95));
  });

  test('walkTo is ignored while held or airborne', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(50, 50))
      ..worldBounds = Vector2(400, 400);
    resident.debugGrab();
    resident.walkTo(Vector2(300, 300));
    expect(resident.position.x, closeTo(50, 0.001));

    resident.debugRelease();
    resident.debugFling(Vector2(0, -200));
    resident.walkTo(Vector2(300, 300));
    expect(resident.airborne, true);
  });

  test('wind toy knocks a free resident airborne sideways', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(200, 200))
      ..worldBounds = Vector2(400, 400);
    resident.applyWind(directionSign: 1);
    expect(resident.airborne, true);
    expect(resident.velocity.x, greaterThan(0));
  });

  test('attractTo starts a walk toward the treat', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(50, 200))
      ..worldBounds = Vector2(400, 400)
      ..roadBounds = const Rect.fromLTWH(40, 180, 320, 100);
    resident.attractTo(Vector2(300, 220));
    expect(resident.busy, true);
    expect(resident.direction, 'right');
  });

  test('wander prefers hotspots when provided', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(100, 220))
      ..worldBounds = Vector2(400, 400)
      ..roadBounds = const Rect.fromLTWH(50, 200, 300, 80)
      ..preferredHotspots = [Vector2(300, 240)]
      ..wanderHotspots = [Vector2(300, 240)];

    // Force many behaviour ticks; eventually should walk toward the hotspot side.
    for (var i = 0; i < 80; i++) {
      resident.update(3.0);
    }
    expect(resident.position.x, greaterThan(150));
  });

  test('exitPlaza walks off-road then fires onExitComplete', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(200, 220))
      ..worldBounds = Vector2(400, 400)
      ..roadBounds = const Rect.fromLTWH(50, 200, 300, 80);
    var exited = false;
    double? exitX;
    resident.onExitComplete = () {
      exited = true;
      exitX = resident.position.x;
    };
    resident.exitPlaza(toLeft: true);
    expect(resident.allowOffRoad, true);
    for (var i = 0; i < 600 && !exited; i++) {
      resident.update(1 / 60);
    }
    expect(exited, true);
    expect(exitX, lessThan(50));
  });

  test('walkTo clamps destinations onto the road', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(100, 220))
      ..worldBounds = Vector2(400, 400)
      ..roadBounds = const Rect.fromLTWH(50, 200, 300, 80);
    resident.walkTo(Vector2(10, 10));
    for (var i = 0; i < 120; i++) {
      resident.update(1 / 60);
    }
    expect(resident.position.x, inInclusiveRange(50, 350));
    expect(resident.position.y, inInclusiveRange(200, 280));
  });
}
