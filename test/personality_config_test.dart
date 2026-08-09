import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/character_config.dart';
import 'package:dead_of_the_dead_game/game/plaza_tutorial.dart';

void main() {
  test('PersonalityDef.fromJson parses decision interval and behaviour weights', () {
    final personality = PersonalityDef.fromJson({
      'decisionIntervalMs': [2000, 6000],
      'autonomousBehaviours': [
        {'action': 'idle', 'weight': 0.5},
        {'action': 'walk', 'weight': 0.25},
        {'action': 'skip', 'weight': 0.1},
        {'action': 'wave', 'weight': 0.15},
      ],
    });

    expect(personality.decisionIntervalMs, [2000, 6000]);
    expect(personality.autonomousBehaviours.length, 4);
    expect(personality.autonomousBehaviours[2].action, 'skip');
    expect(personality.autonomousBehaviours[2].weight, 0.1);
  });

  test('CharacterConfig.fromJson attaches personality when present', () {
    final config = CharacterConfig.fromJson({
      'id': 'pepita',
      'displayName': 'Pepita',
      'role': 'florist',
      'defaultDirection': 'down',
      'movement': {'walkSpeed': 54, 'skipSpeed': 72},
      'personality': {
        'decisionIntervalMs': [2000, 6000],
        'autonomousBehaviours': [
          {'action': 'skip', 'weight': 0.1},
          {'action': 'walk', 'weight': 0.9},
        ],
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

    expect(config.personality.autonomousBehaviours.first.action, 'skip');
    expect(config.personality.decisionIntervalMs, [2000, 6000]);
  });

  test('CharacterConfig falls back to default personality when omitted', () {
    final config = CharacterConfig.fromJson({
      'id': 'test',
      'displayName': 'Test',
      'role': 'tester',
      'defaultDirection': 'down',
      'movement': {'walkSpeed': 55, 'skipSpeed': 75},
      'animations': {
        'idle_down': {
          'frames': 1,
          'fps': 1,
          'loop': true,
          'paths': ['a.png'],
        },
      },
    });

    expect(config.personality.autonomousBehaviours.isNotEmpty, true);
    expect(config.personality.decisionIntervalMs, PersonalityDef.fallback.decisionIntervalMs);
  });

  test('PlazaTutorial step helpers', () {
    expect(PlazaTutorial.stepCount, 4);
    expect(PlazaTutorial.isComplete(0), false);
    expect(PlazaTutorial.isComplete(4), true);
    expect(PlazaTutorial.stepAt(0)?.message, contains('Drag'));
    expect(PlazaTutorial.stepAt(99), isNull);
  });
}
