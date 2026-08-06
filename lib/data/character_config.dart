/// Dart mirror of the JS prototype's `character.json` shape
/// (Softsheeply/DayoftheDead, `assets/characters/{id}/character.json`).
/// Kept intentionally close to the original field names so the JSON files
/// themselves can be reused as-is -- no reformatting needed to port a
/// character's data over, only the code that reads it.
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

class CharacterConfig {
  final String id;
  final String displayName;
  final String role;
  final String defaultDirection;
  final Map<String, double> movement;
  final Map<String, AnimationDef> animations;

  const CharacterConfig({
    required this.id,
    required this.displayName,
    required this.role,
    required this.defaultDirection,
    required this.movement,
    required this.animations,
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
    return CharacterConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      defaultDirection: json['defaultDirection'] as String,
      movement: (json['movement'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      animations: animationsJson.map(
        (key, value) =>
            MapEntry(key, AnimationDef.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}
