import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../data/character_config.dart';

/// A resident's animated sprite + movement/wandering + Pocket God style
/// tap / drag / fling interactions. Data-driven from character.json.
class Resident extends PositionComponent with TapCallbacks, DragCallbacks {
  final CharacterConfig config;
  String direction;

  /// Set by the game after this resident is added, so _moveRandomly has
  /// somewhere to wander within.
  Vector2? worldBounds;

  /// Optional juice hook -- SpiritVillageGame wires this to PetalBurst.
  void Function(Vector2 position, {int count})? onPetalBurst;

  Vector2? _target;
  bool _busy = false;
  bool _held = false;
  bool _airborne = false;
  Vector2 _velocity = Vector2.zero();
  Vector2 _dragVelocity = Vector2.zero();
  double _squash = 1;
  double _dizzyTimer = 0;
  final Random _random = Random();
  double _behaviourTimer = 0;

  final Map<String, SpriteAnimation> _animations = {};
  SpriteAnimationComponent? _visual;
  String _currentAnimationName = '';

  Resident({required this.config, required Vector2 position})
      : direction = config.defaultDirection,
        super(
          position: position,
          size: Vector2(128, 128),
          anchor: Anchor.bottomCenter,
        ) {
    _behaviourTimer = _nextDelay();
  }

  String get currentAnimationName => _currentAnimationName;
  bool get busy => _busy;
  bool get held => _held;
  bool get airborne => _airborne;
  Vector2 get velocity => _velocity.clone();

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
      size: size.clone(),
      anchor: Anchor.bottomCenter,
    );
    _visual = visual;
    add(visual);
    play('idle_$direction');
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = position.y.round();

    if (_dizzyTimer > 0) {
      _dizzyTimer -= dt;
    }

    if (_squash != 1) {
      _squash += (1 - _squash) * min(1, dt * 10);
      _visual?.scale = Vector2(2 - _squash, _squash);
    }

    if (_held) return;

    if (_airborne) {
      _updateAirborne(dt);
      return;
    }

    if (_target != null) {
      _updateMovement(dt);
    } else {
      _updateBehaviour(dt);
    }
  }

  /// Plays the named animation if this resident actually has it. Falls back
  /// to `${name}_down`, then to any idle, matching the JS prototype's
  /// graceful degradation for characters missing actions.
  void play(String name) {
    final resolvedName = _resolveAnimation(name);
    if (resolvedName == null) return;
    final animation = _animations[resolvedName];
    if (animation == null) return;
    _currentAnimationName = resolvedName;
    _visual?.animation = animation;
  }

  String? _resolveAnimation(String name) {
    if (_animations.containsKey(name)) return name;
    final down = '${name}_down';
    if (_animations.containsKey(down)) return down;
    if (_animations.containsKey('idle_$direction')) return 'idle_$direction';
    if (_animations.containsKey('idle_down')) return 'idle_down';
    return _animations.keys.isEmpty ? null : _animations.keys.first;
  }

  double _nextDelay() => 2.0 + _random.nextDouble() * 4.0;

  void _updateBehaviour(double dt) {
    if (_busy || _dizzyTimer > 0) return;
    _behaviourTimer -= dt;
    if (_behaviourTimer > 0) return;
    _behaviourTimer = _nextDelay();
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
    final usableWidth = max(1.0, bounds.x - margin * 2);
    final x = margin + _random.nextDouble() * usableWidth;
    // Keep feet on the painted plaza cobbles (lower band of the backdrop).
    final y = bounds.y * 0.68 + _random.nextDouble() * (bounds.y * 0.22);
    walkTo(Vector2(x, y));
  }

  void walkTo(Vector2 destination) {
    if (_held || _airborne) return;
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

  // -- Pocket God interactions --------------------------------------------

  @override
  void onTapUp(TapUpEvent event) {
    if (_held || _airborne) return;
    _reactToPoke();
  }

  void _reactToPoke() {
    _target = null;
    _busy = true;
    _squash = 0.72;
    _dizzyTimer = 0.35;
    play('idle_$direction');
    onPetalBurst?.call(position.clone()..y -= 40, count: 14);
    // Tiny hop so a tap feels alive even without special animations yet.
    _velocity = Vector2((_random.nextDouble() - 0.5) * 40, -160);
    _airborne = true;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _held = true;
    _airborne = false;
    _busy = true;
    _target = null;
    _velocity.setZero();
    _dragVelocity.setZero();
    _visual?.scale = Vector2.all(1.12);
    play('idle_$direction');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final previous = position.clone();
    position += event.localDelta;
    _clampToWorld();
    final now = position.clone();
    _dragVelocity = (now - previous) * 60;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _releaseWithFling(_dragVelocity);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _releaseWithFling(Vector2.zero());
  }

  void _releaseWithFling(Vector2 fling) {
    _held = false;
    _visual?.scale = Vector2.all(1);
    // Soften extreme flings so chaos stays cartoon, not mean.
    final capped = Vector2(
      fling.x.clamp(-520.0, 520.0),
      fling.y.clamp(-620.0, 200.0),
    );
    if (capped.length > 80) {
      _velocity = capped;
      _airborne = true;
      _busy = true;
      onPetalBurst?.call(position.clone()..y -= 30, count: 14);
    } else {
      _land();
    }
  }

  void _updateAirborne(double dt) {
    _velocity.y += 980 * dt;
    position += _velocity * dt;
    _clampToWorld(softTop: true);

    final groundY = _groundY();
    if (position.y >= groundY && _velocity.y > 0) {
      position.y = groundY;
      if (_velocity.length > 220) {
        // Cartoon bounce once, then settle.
        _velocity.y = -_velocity.y * 0.35;
        _velocity.x *= 0.7;
        _squash = 0.65;
        onPetalBurst?.call(position.clone()..y -= 20, count: 8);
      } else {
        _land();
      }
    }
  }

  void _land() {
    _airborne = false;
    _velocity.setZero();
    _busy = false;
    _dizzyTimer = 0.8;
    _squash = 0.8;
    _setIdle();
  }

  double _groundY() {
    final bounds = worldBounds;
    if (bounds == null) return position.y;
    return bounds.y * 0.90;
  }

  void _clampToWorld({bool softTop = false}) {
    final bounds = worldBounds;
    if (bounds == null) return;
    position.x = position.x.clamp(48, bounds.x - 48);
    final minY = softTop ? bounds.y * 0.25 : bounds.y * 0.62;
    position.y = position.y.clamp(minY, bounds.y * 0.95);
  }

  /// Test seam: start a fling without gesture events.
  void debugFling(Vector2 velocity) {
    _held = false;
    _busy = true;
    _target = null;
    _velocity = velocity.clone();
    _airborne = true;
  }

  /// Test seam: grab without gesture events.
  void debugGrab() {
    _held = true;
    _busy = true;
    _target = null;
    _airborne = false;
    _velocity.setZero();
  }

  void debugRelease() {
    _releaseWithFling(Vector2.zero());
  }

  // -- Toy reactions ------------------------------------------------------

  /// Gust of wind flings the resident lightly sideways.
  void applyWind({required double directionSign}) {
    if (_held) return;
    _target = null;
    _busy = true;
    _velocity = Vector2(directionSign * (220 + _random.nextDouble() * 160), -120);
    _airborne = true;
    _squash = 0.85;
    onPetalBurst?.call(position.clone()..y -= 24, count: 6);
  }

  /// Brief celebratory hop / spin-feel squash for mariachi music.
  void applyDancePulse() {
    if (_held || _airborne) return;
    _target = null;
    _busy = true;
    _dizzyTimer = 0.9;
    _squash = 0.7;
    _velocity = Vector2((_random.nextDouble() - 0.5) * 30, -140);
    _airborne = true;
    onPetalBurst?.call(position.clone()..y -= 36, count: 10);
  }

  /// Walk toward a treat / hotspot (used by pan dulce + Xolo chase).
  void attractTo(Vector2 destination) {
    if (_held || _airborne) return;
    walkTo(destination);
    _squash = 0.9;
  }
}
