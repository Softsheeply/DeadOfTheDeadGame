import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../game/plaza_mission.dart';

class MissionStepDef {
  const MissionStepDef({
    required this.id,
    required this.setId,
    required this.title,
    required this.detail,
    required this.goal,
    required this.triggers,
  });

  final MissionId id;
  final String setId;
  final String title;
  final String detail;
  final int goal;
  final List<String> triggers;

  factory MissionStepDef.fromJson(Map<String, dynamic> json) {
    return MissionStepDef(
      id: MissionId.values.byName(json['id'] as String),
      setId: json['set'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      goal: (json['goal'] as num).toInt(),
      triggers: (json['triggers'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Data-driven mission chain loaded from JSON.
class MissionCatalog {
  MissionCatalog();

  final List<MissionStepDef> steps = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load({String path = 'assets/data/missions/plaza_missions.json'}) async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    steps
      ..clear()
      ..addAll([
        for (final entry in json['steps'] as List<dynamic>)
          MissionStepDef.fromJson(entry as Map<String, dynamic>),
      ]);
    _loaded = true;
  }

  MissionStepDef defFor(MissionId id) =>
      steps.firstWhere((step) => step.id == id);

  MissionId? nextId(MissionId current) {
    final index = steps.indexWhere((step) => step.id == current);
    if (index < 0) return null;
    return steps[(index + 1) % steps.length].id;
  }

  String setLabel(MissionId id) {
    final setId = defFor(id).setId;
    return switch (setId) {
      'festival' => 'Festival',
      _ => 'Welcome',
    };
  }
}
