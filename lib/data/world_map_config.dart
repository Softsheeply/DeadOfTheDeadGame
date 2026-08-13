import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class WorldMapNode {
  const WorldMapNode({
    required this.id,
    required this.label,
    required this.unlocked,
    required this.role,
  });

  final String id;
  final String label;
  final bool unlocked;
  final String role;

  factory WorldMapNode.fromJson(Map<String, dynamic> json) {
    return WorldMapNode(
      id: json['id'] as String,
      label: json['label'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
      role: json['role'] as String? ?? '',
    );
  }
}

class WorldMapConfig {
  WorldMapConfig();

  final List<WorldMapNode> nodes = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load({String path = 'assets/data/world_map.json'}) async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    nodes
      ..clear()
      ..addAll([
        for (final entry in json['nodes'] as List<dynamic>)
          WorldMapNode.fromJson(entry as Map<String, dynamic>),
      ]);
    _loaded = true;
  }
}
