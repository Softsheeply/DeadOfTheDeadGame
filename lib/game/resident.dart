import 'dart:math';
import 'dart:ui' show BlurStyle, Canvas, Color, MaskFilter, Offset, Paint, Rect;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../data/character_config.dart';

/// A resident's animated sprite + movement/wandering + Pocket God style
/// tap / drag / fling interactions. Data-driven from character.json.
class Resident extends PositionComponent with TapCallbacks, DragCallbacks {
  final CharacterConfig config;
  String direction;

  /// Full playfield size (for fling gravity ground fallback).
  Vector2? worldBounds;

  /// Cobble road only -- wander, land, and drag clamps prefer this.
  Rect? roadBounds;

  /// Optional plaza-aware clamp (avoids trees, fountain, river, roofs).
  Vector2 Function(Vector2 point, {bool softTop})? walkClamp;

  /// Optional multi-point route around solid props (doghouse, fountain, …).
  List<Vector2> Function(Vector2 from, Vector2 to)? routeToward;

  /// Optional plaza destinations (florist, bakery, stage, …) for purposeful roam.
  List<Vector2> wanderHotspots = const [];

  /// Subset of [wanderHotspots] this resident likes to visit more often.
  List<Vector2> preferredHotspots = const [];

  /// Bench / rest spots for sit idle actions.
  List<Vector2> restSpots = const [];

  /// Fired with a short status line when an idle performance happens.
  void Function(String line)? onIdleFlavor;

  /// When true, clamps allow walking past the road edge (enter/exit plaza).
  bool allowOffRoad = false;

  /// Fired once when an exiting walk finishes off-screen.
  void Function()? onExitComplete;

  /// Optional juice hook -- SpiritVillageGame wires this to PetalBurst.
  void Function(Vector2 position, {int count})? onPetalBurst;

  /// Fired when the player starts dragging this resident.
  void Function()? onGrab;

  /// Fired when the player releases; [flung] is true for a real toss.
  void Function({required bool flung})? onRelease;

  /// When true, skip walk bob / idle breathing (accessibility).
  bool reduceMotion = false;

  Vector2? _target;
  final List<Vector2> _path = [];
  bool _busy = false;
  bool _held = false;
  bool _airborne = false;
  Vector2 _velocity = Vector2.zero();
  Vector2 _dragVelocity = Vector2.zero();
  double _squash = 1;
  double _dizzyTimer = 0;
  final Random _random = Random();
  double _behaviourTimer = 0;
  double _lifeTime = 0;
  double _idleActionTimer = 0;
  String? _idleAction;
  double _stuckTimer = 0;

  final Map<String, SpriteAnimation> _animations = {};
  SpriteAnimationComponent? _visual;
  String _currentAnimationName = '';
  double _walkDistance = 0;
  bool _skipping = false;
  static const double _directionDeadzone = 8;

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
      var fps = def.fps.toDouble();
      // Walk cycles: match frame rate to travel speed so feet don't skate.
      if (entry.key.startsWith('walk_') && sprites.length > 1) {
        final walkSpeed = config.movement['walkSpeed'] ?? 55.0;
        // Shorter stride → snappier leg cycles so feet read at plaza scale.
        const stridePixels = 36.0;
        final cyclesPerSecond = walkSpeed / stridePixels;
        fps = (cyclesPerSecond * sprites.length).clamp(8.0, 14.0);
      }
      if (entry.key.startsWith('skip_') && sprites.length > 1) {
        final skipSpeed = config.movement['skipSpeed'] ?? 72.0;
        const stridePixels = 36.0;
        final cyclesPerSecond = skipSpeed / stridePixels;
        fps = (cyclesPerSecond * sprites.length).clamp(10.0, 16.0);
      }
      _animations[entry.key] = SpriteAnimation.spriteList(
        sprites,
        stepTime: 1 / fps,
        loop: def.loop,
      );
    }

    final visual = SpriteAnimationComponent(
      size: size.clone(),
      anchor: Anchor.bottomCenter,
      // Must sit on the parent's local bottom-center. Position (0,0) with
      // bottomCenter wrongly parks the sprite at the parent's top-left, so
      // taps on the visible person miss the hitbox and pickup never starts.
      position: _visualHome,
    );
    _visual = visual;
    add(visual);
    play('idle_$direction');
  }

  /// Local feet point of the sprite inside this component's size box.
  Vector2 get _visualHome => Vector2(size.x / 2, size.y);

  void _setVisualOffset([Vector2? offset]) {
    final visual = _visual;
    if (visual == null) return;
    final o = offset ?? Vector2.zero();
    visual.position = _visualHome + o;
  }

  /// Slightly larger than the sprite so Pocket God grabs feel fair on phone.
  @override
  bool containsLocalPoint(Vector2 point) {
    const padX = 20.0;
    const padY = 12.0;
    return point.x >= -padX &&
        point.y >= -padY &&
        point.x <= size.x + padX &&
        point.y <= size.y + padY;
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = (position.y * 10).round();
    _lifeTime += dt;

    if (_dizzyTimer > 0) {
      _dizzyTimer -= dt;
    }

    if (_idleActionTimer > 0) {
      _idleActionTimer -= dt;
      _updateIdleAction(dt);
      if (_idleActionTimer <= 0) {
        _endIdleAction();
      }
      if (_squash != 1) {
        _squash += (1 - _squash) * min(1, dt * 10);
        if (_idleAction != 'sit') {
          _visual?.scale = Vector2(2 - _squash, _squash);
        }
      }
      return;
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

    // Soft idle breathing when the idle clip is a single held frame.
    if (!reduceMotion &&
        !_idleHasMultiFrameAnimation &&
        _target == null &&
        !_busy &&
        _dizzyTimer <= 0 &&
        (_squash - 1).abs() < 0.02) {
      final breath = 1 + 0.035 * sin(_lifeTime * 2.6);
      _visual?.scale = Vector2(2 - breath, breath);
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
  void setDisplaySize(Vector2 displaySize) {
    size = displaySize;
    final visual = _visual;
    if (visual != null) {
      visual.size = displaySize.clone();
      _setVisualOffset();
    }
  }

  void play(String name) {
    final resolvedName = _resolveAnimation(name);
    if (resolvedName == null) return;
    final animation = _animations[resolvedName];
    if (animation == null) return;
    // Don't reset the cycle when re-asserting the same walk/idle clip.
    if (_currentAnimationName == resolvedName && _visual?.animation == animation) {
      return;
    }
    _currentAnimationName = resolvedName;
    final visual = _visual;
    if (visual == null) return;
    visual.animation = animation;
    visual.playing = true;
    visual.animationTicker?.reset();
  }

  String? _resolveAnimation(String name) {
    if (_animations.containsKey(name)) return name;
    final down = '${name}_down';
    if (_animations.containsKey(down)) return down;
    if (_animations.containsKey('idle_$direction')) return 'idle_$direction';
    if (_animations.containsKey('idle_down')) return 'idle_down';
    return _animations.keys.isEmpty ? null : _animations.keys.first;
  }

  bool get _hasSkipAnimations =>
      _animations.keys.any((name) => name.startsWith('skip_'));

  bool get _idleHasMultiFrameAnimation {
    final name = _resolveAnimation('idle_$direction');
    if (name == null) return false;
    final anim = _animations[name];
    return anim != null && anim.frames.length > 1;
  }

  void _playMovementAnimation() {
    if (_skipping && _animations.containsKey('skip_$direction')) {
      play('skip_$direction');
    } else {
      play('walk_$direction');
    }
  }

  /// Pause between autonomous decisions — from character.json personality.
  double _nextDelay() {
    final interval = config.personality.decisionIntervalMs;
    if (interval.length >= 2) {
      final minS = interval[0] / 1000.0;
      final maxS = interval[1] / 1000.0;
      return minS + _random.nextDouble() * (maxS - minS);
    }
    return 0.6 + _random.nextDouble() * 1.8;
  }

  void _updateBehaviour(double dt) {
    if (_busy || _dizzyTimer > 0) return;
    _behaviourTimer -= dt;
    if (_behaviourTimer > 0) return;
    _behaviourTimer = _nextDelay();
    _performAutonomousAction(_pickAutonomousAction());
  }

  String _pickAutonomousAction() {
    final behaviours = config.personality.autonomousBehaviours;
    if (behaviours.isEmpty) return 'idle';
    final total = behaviours.fold<double>(0, (sum, entry) => sum + entry.weight);
    if (total <= 0) return behaviours.first.action;
    var roll = _random.nextDouble() * total;
    for (final entry in behaviours) {
      roll -= entry.weight;
      if (roll <= 0) return entry.action;
    }
    return behaviours.last.action;
  }

  void _performAutonomousAction(String action) {
    switch (action) {
      case 'idle':
        _setIdle();
      case 'walk':
        _moveRandomly(skip: false);
      case 'skip':
        _moveRandomly(skip: _hasSkipAnimations);
      case 'smell_flowers':
        _beginSmell();
      case 'arrange_bouquet':
        _beginArrangeBouquet();
      case 'wave':
        _beginWave();
      case 'sit':
        _beginSit();
      default:
        _moveRandomly(skip: false);
    }
  }

  void _beginArrangeBouquet() {
    _busy = true;
    _idleAction = 'smell';
    _idleActionTimer = 1.6;
    play('idle_$direction');
    _squash = 0.9;
    onPetalBurst?.call(position.clone()..y -= 32, count: 7);
    onIdleFlavor?.call('${config.displayName} arranges a bouquet');
  }

  void _beginWave() {
    _busy = true;
    _idleAction = 'wave';
    _idleActionTimer = 1.1;
    direction = 'down';
    play('idle_down');
    _squash = 0.78;
    onPetalBurst?.call(position.clone()..y -= 36, count: 6);
    onIdleFlavor?.call('${config.displayName} waves hello!');
  }

  void _beginSmell() {
    // Face florist / lean into flowers if we can walk there first.
    if (preferredHotspots.isNotEmpty && _random.nextDouble() < 0.55) {
      final spot = preferredHotspots.first;
      walkTo(spot);
      // After arrival behaviour will idle; schedule smell via timer on next idle.
    }
    _busy = true;
    _idleAction = 'smell';
    _idleActionTimer = 1.4;
    play('idle_$direction');
    _squash = 0.88;
    onPetalBurst?.call(position.clone()..y -= 28, count: 5);
    onIdleFlavor?.call('${config.displayName} smells the marigolds');
  }

  void _beginSit() {
    if (restSpots.isNotEmpty && _random.nextDouble() < 0.7) {
      final spot = restSpots[_random.nextInt(restSpots.length)];
      // Walk over, then sit when close — for simplicity sit in place if far.
      if (position.distanceTo(spot) < 40) {
        position.setFrom(spot);
      } else {
        walkTo(spot);
        return;
      }
    }
    _busy = true;
    _idleAction = 'sit';
    _idleActionTimer = 2.4 + _random.nextDouble() * 1.2;
    play('idle_$direction');
    _visual?.scale = Vector2(1.05, 0.82);
    onIdleFlavor?.call('${config.displayName} takes a little rest');
  }

  void _updateIdleAction(double dt) {
    final action = _idleAction;
    if (action == null) return;
    if (action == 'wave') {
      final pulse = 1 + 0.06 * sin(_lifeTime * 14);
      _visual?.scale = Vector2(2 - pulse, pulse);
    } else if (action == 'smell') {
      final lean = 0.9 + 0.05 * sin(_lifeTime * 3);
      _visual?.scale = Vector2(1.05, lean);
      _setVisualOffset(Vector2(sin(_lifeTime * 2) * 1.5, -1));
    } else if (action == 'sit') {
      _visual?.scale = Vector2(1.06, 0.8);
      _setVisualOffset();
    }
  }

  void _endIdleAction() {
    _idleAction = null;
    _idleActionTimer = 0;
    _busy = false;
    _squash = 1;
    _resetWalkVisual();
    _visual?.scale = Vector2.all(1);
    play('idle_$direction');
  }

  void _moveRandomly({required bool skip}) {
    final road = roadBounds;
    if (road != null && road.width > 8 && road.height > 8) {
      // Strong bias toward personal favorites (stage for mariachi, etc.).
      if (preferredHotspots.isNotEmpty && _random.nextDouble() < 0.62) {
        final spot = preferredHotspots[_random.nextInt(preferredHotspots.length)];
        walkTo(
          spot +
              Vector2(
                (_random.nextDouble() - 0.5) * 22,
                (_random.nextDouble() - 0.5) * 12,
              ),
          skip: skip,
        );
        return;
      }
      // Visit a named plaza stop often so the cast feels purposeful.
      if (wanderHotspots.isNotEmpty && _random.nextDouble() < 0.45) {
        final spot = wanderHotspots[_random.nextInt(wanderHotspots.length)];
        walkTo(
          spot +
              Vector2(
                (_random.nextDouble() - 0.5) * 24,
                (_random.nextDouble() - 0.5) * 14,
              ),
          skip: skip,
        );
        return;
      }
      // Bias toward longer crossings so people really roam the plaza.
      final fromEdge = _random.nextBool();
      late final double x;
      late final double y;
      if (fromEdge) {
        final edge = _random.nextInt(4);
        x = switch (edge) {
          0 => road.left + _random.nextDouble() * road.width * 0.2,
          1 => road.right - _random.nextDouble() * road.width * 0.2,
          _ => road.left + _random.nextDouble() * road.width,
        };
        y = switch (edge) {
          2 => road.top + _random.nextDouble() * road.height * 0.25,
          3 => road.bottom - _random.nextDouble() * road.height * 0.25,
          _ => road.top + _random.nextDouble() * road.height,
        };
      } else {
        x = road.left + _random.nextDouble() * road.width;
        y = road.top + _random.nextDouble() * road.height;
      }
      walkTo(Vector2(x, y), skip: skip);
      return;
    }
    final bounds = worldBounds;
    if (bounds == null) return;
    const margin = 70.0;
    final usableWidth = max(1.0, bounds.x - margin * 2);
    final x = margin + _random.nextDouble() * usableWidth;
    final y = bounds.y * 0.68 + _random.nextDouble() * (bounds.y * 0.18);
    walkTo(Vector2(x, y), skip: skip);
  }

  void walkTo(Vector2 destination, {bool skip = false}) {
    if (_held || _airborne) return;
    _path.clear();
    _stuckTimer = 0;
    if (allowOffRoad || routeToward == null) {
      _target = allowOffRoad ? destination.clone() : _clampPoint(destination);
    } else {
      final route = routeToward!(position, destination);
      if (route.isEmpty) {
        _target = _clampPoint(destination);
      } else {
        _target = route.first;
        if (route.length > 1) {
          _path.addAll(route.skip(1));
        }
      }
    }
    _skipping = skip && _hasSkipAnimations;
    _busy = true;
    _updateDirection(force: true);
    _playMovementAnimation();
  }

  void _advancePathOrIdle() {
    if (_path.isNotEmpty) {
      _target = _path.removeAt(0);
      _stuckTimer = 0;
      _busy = true;
      _updateDirection(force: true);
      _playMovementAnimation();
      return;
    }
    allowOffRoad = false;
    _setIdle();
  }

  /// Walk off the left or right edge, then invoke [onExitComplete].
  void exitPlaza({required bool toLeft}) {
    if (_held) return;
    allowOffRoad = true;
    final road = roadBounds;
    final y = road?.center.dy ?? position.y;
    final x = toLeft
        ? (road?.left ?? position.x) - 120
        : (road?.right ?? position.x) + 120;
    walkTo(Vector2(x, y));
  }

  /// Appear from off-screen and walk onto a plaza point.
  void enterPlaza(Vector2 destination, {required bool fromLeft}) {
    allowOffRoad = true;
    final road = roadBounds;
    final y = destination.y;
    position = Vector2(
      fromLeft ? (road?.left ?? destination.x) - 100 : (road?.right ?? destination.x) + 100,
      y,
    );
    walkTo(destination);
  }

  void _updateDirection({bool force = false}) {
    final target = _target;
    if (target == null) return;
    final dx = target.x - position.x;
    final dy = target.y - position.y;
    // Ignore tiny remaining deltas so near-arrival doesn't flip facing.
    if (!force && dx.abs() < _directionDeadzone && dy.abs() < _directionDeadzone) {
      return;
    }
    // Stick with the current axis until the other clearly dominates (hysteresis).
    final preferHorizontal = force
        ? dx.abs() >= dy.abs()
        : (direction == 'left' || direction == 'right')
            ? dx.abs() >= dy.abs() * 0.72
            : dx.abs() > dy.abs() * 1.15;
    final next = preferHorizontal
        ? (dx < 0 ? 'left' : 'right')
        : (dy < 0 ? 'up' : 'down');
    if (next != direction) {
      direction = next;
      if (_target != null && !_held && !_airborne) {
        _playMovementAnimation();
      }
    }
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
      _walkDistance = 0;
      _resetWalkVisual();
      if (allowOffRoad && onExitComplete != null && _path.isEmpty) {
        final callback = onExitComplete;
        onExitComplete = null;
        allowOffRoad = false;
        callback?.call();
        return;
      }
      _advancePathOrIdle();
      return;
    }
    _updateDirection();
    final speed = _skipping
        ? (config.movement['skipSpeed'] ?? 72.0)
        : (config.movement['walkSpeed'] ?? 55.0);
    final step = min(distance, speed * dt);
    final sx = dx / distance * step;
    final sy = dy / distance * step;
    if (allowOffRoad) {
      position.x += sx;
      position.y += sy;
      _walkDistance += step;
      _stuckTimer = 0;
    } else {
      // Axis-slide against solid props so diagonal steps cannot tunnel through.
      final moved = _tryWalkStep(sx, sy);
      _walkDistance += moved;
      if (moved < step * 0.2) {
        _stuckTimer += dt;
      } else {
        _stuckTimer = 0;
      }
      if (_stuckTimer > 0.35 && distance > 12) {
        _unstickFromBlocker();
        return;
      }
    }
    _applyWalkBob();
  }

  /// When wedged on a prop, skirt it — don't twitch facing the wall.
  void _unstickFromBlocker() {
    _stuckTimer = 0;
    final finalDest = _path.isNotEmpty ? _path.last : _target;
    _path.clear();
    if (finalDest != null && routeToward != null) {
      final route = routeToward!(position, finalDest);
      // Drop the first point if it's basically where we already are.
      final points = [
        for (final p in route)
          if (p.distanceTo(position) > 14) p,
      ];
      if (points.isNotEmpty) {
        _target = points.first;
        if (points.length > 1) {
          _path.addAll(points.skip(1));
        }
        _busy = true;
        _updateDirection(force: true);
        _playMovementAnimation();
        return;
      }
    }
    // Give up on this trip; longer pause so we don't immediately re-wedge.
    _clearWalkIntent();
    _busy = false;
    _resetWalkVisual();
    _setIdle();
    _behaviourTimer = 1.4 + _random.nextDouble() * 1.6;
  }

  /// Moves by [sx],[sy] without entering blockers; slides on one axis if needed.
  double _tryWalkStep(double sx, double sy) {
    final origin = position.clone();
    final diagonal = _clampPoint(Vector2(origin.x + sx, origin.y + sy));
    if ((diagonal.x - (origin.x + sx)).abs() < 0.6 &&
        (diagonal.y - (origin.y + sy)).abs() < 0.6) {
      position.setFrom(diagonal);
      return sqrt(sx * sx + sy * sy);
    }

    final onlyX = _clampPoint(Vector2(origin.x + sx, origin.y));
    final xDist = (onlyX - origin).length;
    final onlyY = _clampPoint(Vector2(origin.x, origin.y + sy));
    final yDist = (onlyY - origin).length;

    if (xDist >= yDist && xDist > 0.05) {
      position.setFrom(onlyX);
      return xDist;
    }
    if (yDist > 0.05) {
      position.setFrom(onlyY);
      return yDist;
    }
    // Both axes blocked — stay put (caller may clear the target).
    position.setFrom(origin);
    return 0;
  }

  /// Soft head bob only — footfall squash smears tiny shoes into a blob.
  void _applyWalkBob() {
    final visual = _visual;
    if (visual == null || reduceMotion) return;
    final phase = _walkDistance / 24 * pi;
    final bob = sin(phase) * 1.6;
    _setVisualOffset(Vector2(0, -bob));
  }

  @override
  void render(Canvas canvas) {
    // Soft contact shadow only while held/airborne — standing sprites already
    // read on cobble, and a blurred oval reads as a milky white puddle.
    if (_held || _airborne) {
      final feet = Offset(size.x / 2, size.y);
      final lift = _held ? 1.0 : 0.7;
      final paint = Paint()
        ..color = Color.fromRGBO(18, 8, 28, 0.22 + 0.2 * lift)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _held ? 8 : 4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(feet.dx, feet.dy + (_held ? 4 : 2)),
          width: size.x * (0.34 + 0.2 * lift),
          height: size.y * (0.07 + 0.05 * lift),
        ),
        paint,
      );
    }
    super.render(canvas);
  }

  void _resetWalkVisual() {
    final visual = _visual;
    if (visual == null) return;
    _setVisualOffset();
    if ((_squash - 1).abs() < 0.02) {
      visual.scale = Vector2.all(1);
    }
  }

  void _setIdle() {
    _clearWalkIntent();
    _busy = false;
    _walkDistance = 0;
    _resetWalkVisual();
    play('idle_$direction');
  }

  void _clearWalkIntent() {
    _target = null;
    _path.clear();
    _stuckTimer = 0;
    _skipping = false;
  }

  // -- Pocket God interactions --------------------------------------------

  @override
  void onTapUp(TapUpEvent event) {
    if (_held || _airborne) return;
    _reactToPoke();
  }

  void _reactToPoke() {
    _clearWalkIntent();
    _busy = true;
    _squash = 0.72;
    _dizzyTimer = 0.35;
    play('idle_$direction');
    onPetalBurst?.call(position.clone()..y -= 40, count: 14);
    // Tiny hop so a tap feels alive even without special animations yet.
    _velocity = Vector2((_random.nextDouble() - 0.5) * 40, -160);
    _airborne = true;
  }

  /// Pocket God hold: sprite lifts high above the feet/shadow.
  /// Swap to a dedicated held/carry clip when art lands.
  double get _heldVisualLift => size.y * 0.92;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _idleAction = null;
    _idleActionTimer = 0;
    _held = true;
    _airborne = false;
    _busy = true;
    _clearWalkIntent();
    _velocity.setZero();
    _dragVelocity.setZero();
    // Tall lift + slight stretch reads as “picked up!” without a scream.
    _visual?.scale = Vector2(1.18, 1.28);
    _setVisualOffset(Vector2(0, -_heldVisualLift));
    // Prefer a down-facing idle so the “ahh” face reads toward the player.
    direction = 'down';
    play('idle_down');
    onGrab?.call();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final previous = position.clone();
    position += event.localDelta;
    // Held toys stay on walkable cobble (no roofs / fountain bowl / river).
    _clampToWorld(softTop: false);
    final now = position.clone();
    _dragVelocity = (now - previous) * 60;
    // Soft wiggle while held (Pocket God “dangling” energy).
    if (!reduceMotion) {
      final wobble = sin(_lifeTime * 16) * 3.0;
      final bounce = sin(_lifeTime * 11) * 2.0;
      _setVisualOffset(Vector2(wobble, -_heldVisualLift + bounce));
    } else {
      _setVisualOffset(Vector2(0, -_heldVisualLift));
    }
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
    _setVisualOffset();
    // Soften extreme flings so chaos stays cartoon, not mean.
    final capped = Vector2(
      fling.x.clamp(-520.0, 520.0),
      fling.y.clamp(-620.0, 200.0),
    );
    final flung = capped.length > 80;
    onRelease?.call(flung: flung);
    if (flung) {
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
    // Snap off roofs / fountain / river onto cobble.
    _clampToWorld(softTop: false);
    _busy = false;
    _dizzyTimer = 0.8;
    _squash = 0.8;
    _setIdle();
  }

  double _groundY() {
    final road = roadBounds;
    if (road != null) {
      // Land near current feet Y inside the cobble band, not always at the bottom.
      return position.y.clamp(road.top + road.height * 0.15, road.bottom);
    }
    final bounds = worldBounds;
    if (bounds == null) return position.y;
    return bounds.y * 0.90;
  }

  Vector2 _clampPoint(Vector2 point, {bool softTop = false}) {
    if (allowOffRoad) {
      final bounds = worldBounds;
      if (bounds == null) return point;
      return Vector2(
        point.x.clamp(-160, bounds.x + 160),
        point.y.clamp(bounds.y * 0.2, bounds.y * 0.98),
      );
    }
    final custom = walkClamp;
    if (custom != null) {
      return custom(point, softTop: softTop);
    }
    final road = roadBounds;
    if (road != null) {
      final minY = softTop ? road.top - road.height : road.top;
      return Vector2(
        point.x.clamp(road.left, road.right),
        point.y.clamp(minY, road.bottom),
      );
    }
    final bounds = worldBounds;
    if (bounds == null) return point;
    final minY = softTop ? bounds.y * 0.25 : bounds.y * 0.62;
    return Vector2(
      point.x.clamp(48, bounds.x - 48),
      point.y.clamp(minY, bounds.y * 0.95),
    );
  }

  void _clampToWorld({bool softTop = false}) {
    position.setFrom(_clampPoint(position, softTop: softTop));
  }

  /// Test seam: start a fling without gesture events.
  void debugFling(Vector2 velocity) {
    _held = false;
    _busy = true;
    _clearWalkIntent();
    _velocity = velocity.clone();
    _airborne = true;
  }

  /// Test seam: grab without gesture events.
  void debugGrab() {
    _held = true;
    _busy = true;
    _clearWalkIntent();
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
    _clearWalkIntent();
    _busy = true;
    _velocity = Vector2(directionSign * (220 + _random.nextDouble() * 160), -120);
    _airborne = true;
    _squash = 0.85;
    onPetalBurst?.call(position.clone()..y -= 24, count: 6);
  }

  /// Brief celebratory hop / spin-feel squash for mariachi music.
  void applyDancePulse() {
    if (_held || _airborne) return;
    _clearWalkIntent();
    _busy = true;
    _dizzyTimer = 0.9;
    _squash = 0.7;
    _velocity = Vector2((_random.nextDouble() - 0.5) * 30, -140);
    _airborne = true;
    onPetalBurst?.call(position.clone()..y -= 36, count: 10);
  }

  /// Face a plaza landmark without walking — building taps, rare events.
  void glanceToward(Vector2 worldPoint) {
    if (_held || _airborne) return;
    _clearWalkIntent();
    final dx = worldPoint.x - position.x;
    final dy = worldPoint.y - position.y;
    if (dx.abs() < 6 && dy.abs() < 6) return;
    direction = dx.abs() >= dy.abs()
        ? (dx < 0 ? 'left' : 'right')
        : (dy < 0 ? 'up' : 'down');
    play('idle_$direction');
    _squash = 0.9;
    _dizzyTimer = max(_dizzyTimer, 0.35);
  }

  /// Walk toward a treat / hotspot (used by pan dulce + Xolo chase).
  void attractTo(Vector2 destination) {
    if (_held || _airborne) return;
    walkTo(destination);
    _squash = 0.9;
  }
}
