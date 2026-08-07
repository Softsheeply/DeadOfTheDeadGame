import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who can appear in the plaza, and whether they're currently on stage.
class CastMemberInfo {
  const CastMemberInfo({
    required this.id,
    required this.displayName,
    required this.assetPath,
    required this.kind,
    this.defaultOnPlaza = false,
    this.preferredHotspotIndexes = const [],
  });

  final String id;
  final String displayName;
  final String assetPath;
  final CastKind kind;
  final bool defaultOnPlaza;

  /// Indexes into [VillageBackdrop.hotspotUvs] this cast member prefers.
  final List<int> preferredHotspotIndexes;
}

enum CastKind { person, dog, cat, creature }

/// Full Day of the Dead plaza roster.
const List<CastMemberInfo> kPlazaCast = [
  CastMemberInfo(
    id: 'pepita',
    displayName: 'Pepita',
    assetPath: 'assets/images/pepita/character.json',
    kind: CastKind.person,
    defaultOnPlaza: true,
    preferredHotspotIndexes: [0, 2],
  ),
  CastMemberInfo(
    id: 'abuela_rosa',
    displayName: 'Abuela Rosa',
    assetPath: 'assets/images/abuela_rosa/character.json',
    kind: CastKind.person,
    defaultOnPlaza: true,
    preferredHotspotIndexes: [2, 3],
  ),
  CastMemberInfo(
    id: 'xolo',
    displayName: 'Xolo',
    assetPath: 'assets/images/xolo/character.json',
    kind: CastKind.dog,
    defaultOnPlaza: true,
    preferredHotspotIndexes: [7, 8],
  ),
  CastMemberInfo(
    id: 'gato',
    displayName: 'Gato',
    assetPath: 'assets/images/gato/character.json',
    kind: CastKind.cat,
    defaultOnPlaza: true,
    preferredHotspotIndexes: [6, 1],
  ),
  CastMemberInfo(
    id: 'tito',
    displayName: 'Tito',
    assetPath: 'assets/images/tito/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [4],
  ),
  CastMemberInfo(
    id: 'miguel',
    displayName: 'Miguel',
    assetPath: 'assets/images/miguel/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [0, 2],
  ),
  CastMemberInfo(
    id: 'dona_luz',
    displayName: 'Doña Luz',
    assetPath: 'assets/images/dona_luz/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [5, 3],
  ),
  CastMemberInfo(
    id: 'alebrije',
    displayName: 'Alebrije',
    assetPath: 'assets/images/alebrije/character.json',
    kind: CastKind.creature,
    preferredHotspotIndexes: [7, 8],
  ),
  CastMemberInfo(
    id: 'chavo',
    displayName: 'Chavo',
    assetPath: 'assets/images/chavo/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [4, 8],
  ),
  CastMemberInfo(
    id: 'don_mateo',
    displayName: 'Don Mateo',
    assetPath: 'assets/images/don_mateo/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [1, 6],
  ),
  CastMemberInfo(
    id: 'pinto',
    displayName: 'Pinto',
    assetPath: 'assets/images/pinto/character.json',
    kind: CastKind.person,
    preferredHotspotIndexes: [0, 6],
  ),
  CastMemberInfo(
    id: 'senor_cuervo',
    displayName: 'Señor Cuervo',
    assetPath: 'assets/images/senor_cuervo/character.json',
    kind: CastKind.creature,
    preferredHotspotIndexes: [6, 5],
  ),
];

/// Mutable on/off presence for the HUD + game, persisted locally.
class CastRoster extends ChangeNotifier {
  CastRoster() {
    for (final member in kPlazaCast) {
      _onPlaza[member.id] = member.defaultOnPlaza;
    }
  }

  final Map<String, bool> _onPlaza = {};
  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  bool isOnPlaza(String id) => _onPlaza[id] ?? false;

  List<CastMemberInfo> get members => kPlazaCast;

  Map<String, bool> get snapshot => Map.unmodifiable(_onPlaza);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    for (final member in kPlazaCast) {
      final stored = _prefs!.getBool(_key(member.id));
      _onPlaza[member.id] = stored ?? member.defaultOnPlaza;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setOnPlaza(String id, bool present) async {
    if (_onPlaza[id] == present) return;
    _onPlaza[id] = present;
    notifyListeners();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_key(id), present);
  }

  Future<void> toggle(String id) => setOnPlaza(id, !isOnPlaza(id));

  static String _key(String id) => 'cast_on_plaza_$id';
}
