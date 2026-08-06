import 'package:flame/components.dart';

import '../data/character_config.dart';

/// A resident's animated sprite, data-driven from its character.json --
/// direct Dart port of the JS prototype's CharacterAnimationController
/// (Softsheeply/DayoftheDead, src/animation.js). Every animation the
/// character has is pre-loaded on onLoad; play(name) swaps the active one.
///
/// Deliberately *not* using Flame's `SpriteAnimationGroupComponent` (which
/// needs a fixed enum of states) -- character.json's animation set is
/// arbitrary per character (Pepita has ~20 named animations, Xolo has far
/// fewer, future characters will differ again), so a plain string-keyed
/// map keeps this genuinely reusable across the roster without a
/// hardcoded enum needing to grow for every character's quirks. This
/// mirrors the JS version's data-driven design on purpose.
class Resident extends PositionComponent {
  final CharacterConfig config;
  String direction;

  final Map<String, SpriteAnimation> _animations = {};
  late final SpriteAnimationComponent _visual;
  String _currentAnimationName = '';

  Resident({required this.config, required Vector2 position})
      : direction = config.defaultDirection,
        super(position: position, size: Vector2(128, 128), anchor: Anchor.bottomCenter);

  String get currentAnimationName => _currentAnimationName;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (final entry in config.animations.entries) {
      final def = entry.value;
      final sprites = await Future.wait(
        def.paths.map((path) => Sprite.load('${config.id}/$path')),
      );
      _animations[entry.key] = SpriteAnimation.spriteList(
        sprites,
        stepTime: 1 / def.fps,
        loop: def.loop,
      );
    }

    _visual = SpriteAnimationComponent(
      size: Vector2(128, 128),
      anchor: Anchor.bottomCenter,
    );
    add(_visual);
    play('idle_$direction');
  }

  /// Plays the named animation if this resident actually has it. Falls back
  /// to `${name}_down`, matching playAction's own fallback naming in the JS
  /// version. Silently no-ops (doesn't throw) if neither exists -- same
  /// "graceful degradation for a resident missing an animation" contract as
  /// resident.js's playAction, so a minimal placeholder character can't
  /// crash the game by lacking an action.
  void play(String name) {
    final resolvedName = _animations.containsKey(name) ? name : '${name}_down';
    final animation = _animations[resolvedName];
    if (animation == null) return;
    _currentAnimationName = resolvedName;
    _visual.animation = animation;
  }
}
