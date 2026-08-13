import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class CastBio {
  const CastBio({
    required this.id,
    required this.displayName,
    required this.role,
    required this.bio,
    required this.likes,
  });

  final String id;
  final String displayName;
  final String role;
  final String bio;
  final String likes;

  factory CastBio.fromJson(String id, Map<String, dynamic> json) {
    return CastBio(
      id: id,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      bio: json['bio'] as String,
      likes: json['likes'] as String,
    );
  }
}

/// Short journal entries for the cast HUD.
class CastJournal {
  CastJournal();

  final Map<String, CastBio> _bios = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/cast_bios.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in json.entries) {
      _bios[entry.key] = CastBio.fromJson(entry.key, entry.value as Map<String, dynamic>);
    }
    _loaded = true;
  }

  CastBio? bioFor(String id) => _bios[id];

  List<CastBio> get all => _bios.values.toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
}
