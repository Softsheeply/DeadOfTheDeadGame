import 'dart:math';

import 'package:flame/components.dart';

import '../data/character_config.dart';

/// A resident's animated sprite + basic movement/wandering, data-driven
/// from its character.json -- Dart port of the JS prototype's
/// CharacterAnimationController (src/animation.js) plus the movement half
/// of resident.js and the weighted-pick half of behaviour.js.
///
/// Deliberately *not* using Flame's `SpriteAnimationGroupComponent` (which
/// needs a fixed enum of states) -- character.json's animation set is
/// arbitrary per character (Pepita has ~20 named animations, Xolo has far
/// fewer, future characters will differ again), so a plain string-keyed
/// map keeps this genuinely reusable across the roster without a
/// hardcoded enum needing to grow for every character's quirks. This
/// mirrors the JS version's data-driven design on purpose.
///
/// No obstacle avoidance or pathfinding yet -- matches the JS prototype's
/// own build order, where residents wandered randomly for a long while
/// before src/navigation.js (obstacles) and the later grid-BFS pathfinder
/// existed at all. That's the next Flutter pass, not this one.
class Resident extends PositionComponent {
  final CharacterConfig config;
  String direction;

  /// Set by the game after this resident is added, so _moveRandomly has
  /// somewhere to wander within. Using the play area size, not the exact
  /// obstacle-aware nav band the JS version eventually grew -- that's
  /// still ahead of this phase.
  Vector2? worldBounds;

  Vector2? _target;
  bool _busy = false;
  final Random _random = Random();
  double _behaviourTimer = 0;

  final Map<String, SpriteAnimation> _animations = {};
  // Nullable rather than `late` on purpose: play()/movement/behaviour logic
  // should be safely unit-testable without going through Flame's full
  // asset-loading component lifecycle (Sprite.load needs a real or faked
  // asset bundle). A Resident that hasn't had onLoad() run yet just has no
  // visual to update -- play() becomes a no-op instead of throwing.
  SpriteAnimationComponent? _visual;
  String _currentAnimationName = '';

  Resident({required this.config, required Vector2 position})
      : direction = config.defaultDirection,
        super(position: position, size: Vector2(128, 128), anchor: Anchor.bottomCenter) {
    _behaviourTimer = _nextDelay();
  }

  String get currentAnimationName => _currentAnimationName;
  bool get busy => _busy;

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

    final visual = SpriteAnimationComponent(
      size: Vector2(128, 128),
      anchor: Anchor.bottomCenter,
    );
    _visual = visual;
    add(visual);
    play('idle_$direction');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_target != null) {
      _updateMovement(dt);
    } else {
      _updateBehaviour(dt);
    }
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
    _visual?.animation = animation;
  }

  // -- Autonomous behaviour: port of behaviour.js's weighted picker --------
  // JS used 2000-6000ms; dt here is in seconds, so 2.0-6.0.
  double _nextDelay() => 2.0 + _random.nextDouble() * 4.0;

  void _updateBehaviour(double dt) {
    if (_busy) return;
    _behaviourTimer -= dt;
    if (_behaviourTimer > 0) return;
    _behaviourTimer = _nextDelay();
    // idle_down/left/right/up + walk_down/left/right/up are all that's
    // ported so far, so the weighted table is just idle vs. walk for now
    // (skip/smell_flowers/etc. come back once their animations do).
    if (_random.nextDouble() < 0.5) {
      _setIdle();
    } else {
      _moveRandomly();
    }
  }

  void _moveRandomly() {
    final bounds = worldBounds;
    if (bounds == null) return;
    const margin = 70.0;
    final x = margin + _random.nextDouble() * (bounds.x - margin * 2);
    final y = bounds.y * 0.5 + _random.nextDouble() * (bounds.y * 0.35);
    walkTo(Vector2(x, y));
  }

  /// Sets a movement target -- the public seam for both autonomous
  /// wandering (_moveRandomly) and, later, interactions/hotspots
  /// commanding a resident to approach a specific point (mirrors
  /// resident.js's beginInteractionApproach in the JS prototype).
  void walkTo(Vector2 destination) {
    _target = destination;
    _busy = true;
    _updateDirection();
    play('walk_$direction');
  }

  void _updateDirection() {
    final target = _target;
    if (target == null) return;
    final dx = target.x - position.x;
    final dy = target.y - position.y;
    direction = dx.abs() > dy.abs() ? (dx < 0 ? 'left' : 'right') : (dy < 0 ? 'up' : 'down');
  }

  // -- Movement: port of resident.js's updateMovement -----------------------

  void _updateMovement(double dt) {
    final target = _target!;
    final dx = target.x - position.x;
    final dy = target.y - position.y;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 2) {
      position.setFrom(target);
      _target = null;
      _busy = false;
      _setIdle();
      return;
    }
    final speed = config.movement['walkSpeed'] ?? 55.0;
    final step = min(distance, speed * dt);
    position.x += dx / distance * step;
    position.y += dy / distance * step;
  }

  void _setIdle() {
    _target = null;
    _busy = false;
    play('idle_$direction');
  }
}
