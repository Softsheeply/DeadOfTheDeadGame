class AnimationDef {
  final int frames;
  final double fps;
  final bool loop;
  final List<String> paths;
  final Map<String, String> events; // frame index (as string) -> event name

  const AnimationDef({
    required this.frames,
    required this.fps,
    required this.loop,
    required this.paths,
    this.events = const {},
  });

  factory AnimationDef.fromJson(Map<String, dynamic> json) {
    return AnimationDef(
      frames: json['frames'] as int,
      fps: (json['fps'] as num).toDouble(),
      loop: json['loop'] as bool,
      paths: (json['paths'] as List).cast<String>(),
      events: (json['events'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as String)) ??
          const {},
    );
  }
}

class BehaviourWeight {
  final String action;
  final double weight;

  const BehaviourWeight({required this.action, required this.weight});

  factory BehaviourWeight.fromJson(Map<String, dynamic> json) {
    return BehaviourWeight(
      action: json['action'] as String,
      weight: (json['weight'] as num).toDouble(),
    );
  }
}

class PersonalityDef {
  final List<int> decisionIntervalMs;
  final List<BehaviourWeight> autonomousBehaviours;

  const PersonalityDef({
    required this.decisionIntervalMs,
    required this.autonomousBehaviours,
  });

  /// Matches legacy hardcoded rolls when JSON omits personality.
  static const fallback = PersonalityDef(
    decisionIntervalMs: [600, 2400],
    autonomousBehaviours: [
      BehaviourWeight(action: 'idle', weight: 0.22),
      BehaviourWeight(action: 'wave', weight: 0.055),
      BehaviourWeight(action: 'smell_flowers', weight: 0.053),
      BehaviourWeight(action: 'sit', weight: 0.052),
      BehaviourWeight(action: 'walk', weight: 0.62),
    ],
  );

  factory PersonalityDef.fromJson(Map<String, dynamic> json) {
    return PersonalityDef(
      decisionIntervalMs: (json['decisionIntervalMs'] as List)
          .map((value) => (value as num).toInt())
          .toList(),
      autonomousBehaviours: (json['autonomousBehaviours'] as List)
          .map((entry) => BehaviourWeight.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CharacterConfig {
  final String id;
  final String displayName;
  final String role;
  final String defaultDirection;
  /// Speeds (double) plus optional flags like [walkTwoFrameFallback] (bool).
  final Map<String, dynamic> movement;
  final Map<String, AnimationDef> animations;
  final PersonalityDef personality;
  final double frameHeight;
  final double feetAnchorX;
  final double feetAnchorY;

  const CharacterConfig({
    required this.id,
    required this.displayName,
    required this.role,
    required this.defaultDirection,
    required this.movement,
    required this.animations,
    this.personality = PersonalityDef.fallback,
    this.frameHeight = 128,
    this.feetAnchorX = 64,
    this.feetAnchorY = 124,
  });

  /// Mirrors resident.js's playAction fallback: `${action}_down` if the
  /// bare action name isn't a real animation. Used so a resident missing
  /// an action (e.g. Xolo has no "sit") degrades gracefully instead of
  /// throwing, same contract as the JS version.
  AnimationDef? animationFor(String name) {
    return animations[name] ?? animations['${name}_down'];
  }

  factory CharacterConfig.fromJson(Map<String, dynamic> json) {
    final animationsJson = json['animations'] as Map<String, dynamic>;
    final personalityJson = json['personality'] as Map<String, dynamic>?;
    final frameHeight = (json['frameHeight'] as num?)?.toDouble() ?? 128.0;
    final anchorsJson = json['anchors'] as Map<String, dynamic>?;
    var feetAnchorX = frameHeight / 2;
    var feetAnchorY = frameHeight - 4;
    if (anchorsJson != null && anchorsJson['feet'] is List) {
      final feet = (anchorsJson['feet'] as List).cast<num>();
      if (feet.length >= 2) {
        feetAnchorX = feet[0].toDouble();
        feetAnchorY = feet[1].toDouble();
      }
    }
    return CharacterConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      defaultDirection: json['defaultDirection'] as String,
      movement: Map<String, dynamic>.from(json['movement'] as Map),
      animations: animationsJson.map(
        (key, value) =>
            MapEntry(key, AnimationDef.fromJson(value as Map<String, dynamic>)),
      ),
      personality: personalityJson == null
          ? PersonalityDef.fallback
          : PersonalityDef.fromJson(personalityJson),
      frameHeight: frameHeight,
      feetAnchorX: feetAnchorX,
      feetAnchorY: feetAnchorY,
    );
  }
}
