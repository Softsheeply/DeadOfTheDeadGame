import 'package:flame/components.dart';
import 'package:flame/game.dart';
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
    },
  });
}

void main() {
  test('hitbox covers the visible body, not the old top-left ghost', () {
    final resident = Resident(
      config: _minimalConfig(),
      position: Vector2(400, 400),
    )..size = Vector2(64, 64);

    // Feet at (400,400), box extends up to y=336. Torso/head must be hittable.
    expect(resident.containsPoint(Vector2(400, 368)), isTrue);
    expect(resident.containsPoint(Vector2(400, 336)), isTrue);
    expect(resident.containsPoint(Vector2(400, 400)), isTrue); // pad includes feet

    // Pre-fix sprite parked at parent top-left — that world point is outside.
    expect(resident.containsPoint(Vector2(336, 272)), isFalse);
  });

  test('bottomCenter child must be placed at local (w/2, h), not (0,0)', () async {
    final game = FlameGame();
    await game.onLoad();
    game.onGameResize(Vector2(800, 600));

    final parent = PositionComponent(
      position: Vector2(400, 400),
      size: Vector2(64, 64),
      anchor: Anchor.bottomCenter,
    );
    game.add(parent);
    await game.ready();

    final wrong = PositionComponent(
      size: Vector2(64, 64),
      anchor: Anchor.bottomCenter,
      position: Vector2.zero(),
    );
    final right = PositionComponent(
      size: Vector2(64, 64),
      anchor: Anchor.bottomCenter,
      position: Vector2(32, 64),
    );
    parent.add(wrong);
    parent.add(right);
    await game.ready();

    // Wrong layout drifts up-left; correct layout shares the parent's center.
    expect(wrong.absoluteCenter.x, isNot(closeTo(400, 0.5)));
    expect(right.absoluteCenter, Vector2(400, 368));
  });
}
