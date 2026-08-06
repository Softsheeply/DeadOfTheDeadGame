import 'package:flame/components.dart';
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

// These exercise Resident's movement/behaviour logic directly (walkTo,
// update) without going through Flame's asset-loading component lifecycle
// (onLoad needs a real/faked asset bundle for Sprite.load) -- possible
// because _visual is nullable and play() no-ops safely when it's unset,
// same "testable without the rendering half" split the JS prototype's
// logic.mjs test suite used.
void main() {
  test('walkTo sets a target and faces the correct direction', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    resident.walkTo(Vector2(100, 0));
    expect(resident.busy, true);
    expect(resident.direction, 'right');
  });

  test('update moves the resident toward the target at walkSpeed, arrives, and returns to idle', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    resident.walkTo(Vector2(100, 0)); // walkSpeed 100/s from _minimalConfig

    resident.update(0.5); // half a second -> 50 units
    expect(resident.position.x, closeTo(50, 0.001));
    expect(resident.busy, true, reason: 'should not have arrived yet');

    resident.update(1.0); // steps exactly onto the target, but arrival is checked at the
                          // *start* of the next call (matches the JS prototype's identical quirk)
    expect(resident.position.x, closeTo(100, 0.001));
    expect(resident.busy, true, reason: 'not yet detected as arrived within the same call that reaches it');

    resident.update(1 / 60); // next frame: distance is now ~0, so this call detects arrival
    expect(resident.position.x, closeTo(100, 0.001));
    expect(resident.busy, false, reason: 'should be idle again once arrival is detected');
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

    // Feed a large dt that would normally exceed the behaviour timer window
    // (2-6s) many times over -- since the resident is mid-walkTo (busy),
    // the behaviour picker must not fire and stomp on the existing target.
    resident.update(10.0);

    // Position should have moved toward (200,200), not been reset by a
    // fresh _moveRandomly picking a different point mid-flight.
    final dx = resident.position.x - positionBeforeManyUpdates.x;
    final dy = resident.position.y - positionBeforeManyUpdates.y;
    expect(dx >= 0 && dy >= 0, true, reason: 'should still be progressing toward the original target, not a new one');
  });

  test('a resident with no worldBounds set simply does not wander (no crash)', () {
    final resident = Resident(config: _minimalConfig(), position: Vector2(0, 0));
    // No worldBounds assigned. Feed enough time to trigger many behaviour
    // rolls; _moveRandomly should just return early every time.
    expect(() => resident.update(20.0), returnsNormally);
    expect(resident.busy, false);
  });
}
