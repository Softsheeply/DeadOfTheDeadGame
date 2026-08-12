import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/character_config.dart';

void main() {
  test('CharacterConfig.fromJson parses the shape used by the JS prototype', () {
    final config = CharacterConfig.fromJson({
      'id': 'pepita',
      'displayName': 'Pepita',
      'role': 'florist',
      'defaultDirection': 'down',
      'movement': {'walkSpeed': 55, 'skipSpeed': 75},
      'animations': {
        'idle_down': {
          'frames': 6,
          'fps': 6,
          'loop': true,
          'paths': ['idle/down/pepita_idle_down_00.png'],
        },
        'throw_petals': {
          'frames': 8,
          'fps': 12,
          'loop': false,
          'paths': ['actions/throw_petals/pepita_throw_petals_00.png'],
          'events': {'4': 'spawn_petals'},
        },
      },
    });

    expect(config.id, 'pepita');
    expect(config.displayName, 'Pepita');
    expect(config.movement['walkSpeed'], 55.0);
    expect(config.animations['idle_down']!.frames, 6);
    expect(config.animations['idle_down']!.loop, true);
    expect(config.animations['throw_petals']!.events['4'], 'spawn_petals');
  });

  test('animationFor falls back to <name>_down, matching the JS prototype\'s playAction', () {
    final config = CharacterConfig.fromJson({
      'id': 'pepita',
      'displayName': 'Pepita',
      'role': 'florist',
      'defaultDirection': 'down',
      'movement': {'walkSpeed': 55, 'skipSpeed': 75},
      'animations': {
        'wave_down': {
          'frames': 1,
          'fps': 1,
          'loop': false,
          'paths': ['wave_down.png'],
        },
      },
    });

    expect(config.animationFor('wave_down'), isNotNull);
    expect(config.animationFor('wave'), isNotNull, reason: 'should fall back to wave_down');
    expect(config.animationFor('sit'), isNull, reason: 'no sit or sit_down animation exists');
  });

  test('CharacterConfig parses frameHeight and feet anchors', () {
    final config = CharacterConfig.fromJson({
      'id': 'pepita',
      'displayName': 'Pepita',
      'role': 'florist',
      'defaultDirection': 'down',
      'frameHeight': 192,
      'anchors': {
        'feet': [96, 188],
      },
      'movement': {'walkSpeed': 54, 'skipSpeed': 72},
      'animations': {
        'idle_down': {
          'frames': 1,
          'fps': 1,
          'loop': true,
          'paths': ['idle/down/pepita_idle_down_00.png'],
        },
      },
    });

    expect(config.frameHeight, 192);
    expect(config.feetAnchorX, 96);
    expect(config.feetAnchorY, 188);
  });

  test('CharacterConfig movement accepts boolean flags', () {
    final config = CharacterConfig.fromJson({
      'id': 'pepita',
      'displayName': 'Pepita',
      'role': 'florist',
      'defaultDirection': 'down',
      'movement': {
        'walkSpeed': 46,
        'walkTwoFrameFallback': false,
      },
      'animations': {
        'idle_down': {
          'frames': 1,
          'fps': 1,
          'loop': true,
          'paths': ['idle/down/pepita_idle_down_00.png'],
        },
      },
    });

    expect(config.movement['walkSpeed'], 46);
    expect(config.movement['walkTwoFrameFallback'], false);
  });
}
