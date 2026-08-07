import 'package:flutter/foundation.dart';

/// Who can appear in the plaza, and whether they're currently on stage.
class CastMemberInfo {
  const CastMemberInfo({
    required this.id,
    required this.displayName,
    required this.assetPath,
    required this.kind,
    this.defaultOnPlaza = true,
  });

  final String id;
  final String displayName;
  final String assetPath;
  final CastKind kind;
  final bool defaultOnPlaza;
}

enum CastKind { person, dog, cat, creature }

/// Full Day of the Dead plaza roster.
const List<CastMemberInfo> kPlazaCast = [
  CastMemberInfo(
    id: 'pepita',
    displayName: 'Pepita',
    assetPath: 'assets/images/pepita/character.json',
    kind: CastKind.person,
  ),
  CastMemberInfo(
    id: 'abuela_rosa',
    displayName: 'Abuela Rosa',
    assetPath: 'assets/images/abuela_rosa/character.json',
    kind: CastKind.person,
  ),
  CastMemberInfo(
    id: 'xolo',
    displayName: 'Xolo',
    assetPath: 'assets/images/xolo/character.json',
    kind: CastKind.dog,
  ),
  CastMemberInfo(
    id: 'gato',
    displayName: 'Gato',
    assetPath: 'assets/images/gato/character.json',
    kind: CastKind.cat,
  ),
  CastMemberInfo(
    id: 'tito',
    displayName: 'Tito',
    assetPath: 'assets/images/tito/character.json',
    kind: CastKind.person,
  ),
  CastMemberInfo(
    id: 'miguel',
    displayName: 'Miguel',
    assetPath: 'assets/images/miguel/character.json',
    kind: CastKind.person,
  ),
  CastMemberInfo(
    id: 'dona_luz',
    displayName: 'Doña Luz',
    assetPath: 'assets/images/dona_luz/character.json',
    kind: CastKind.person,
  ),
  CastMemberInfo(
    id: 'alebrije',
    displayName: 'Alebrije',
    assetPath: 'assets/images/alebrije/character.json',
    kind: CastKind.creature,
  ),
];

/// Mutable on/off presence for the HUD + game.
class CastRoster extends ChangeNotifier {
  CastRoster() {
    for (final member in kPlazaCast) {
      _onPlaza[member.id] = member.defaultOnPlaza;
    }
  }

  final Map<String, bool> _onPlaza = {};

  bool isOnPlaza(String id) => _onPlaza[id] ?? false;

  List<CastMemberInfo> get members => kPlazaCast;

  Map<String, bool> get snapshot => Map.unmodifiable(_onPlaza);

  void setOnPlaza(String id, bool present) {
    if (_onPlaza[id] == present) return;
    _onPlaza[id] = present;
    notifyListeners();
  }

  void toggle(String id) => setOnPlaza(id, !isOnPlaza(id));
}
