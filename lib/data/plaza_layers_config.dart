import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/services.dart' show rootBundle;

enum PlazaLayerVisibility { always, day, night }

enum PlazaLayerAnimation {
  none,
  riverFlow,
  fountainFlow,
  treeSway,
  flagsSway,
  lightsFlicker,
  celestialRoll,
}

class PlazaLayerDef {
  PlazaLayerDef({
    required this.id,
    required this.asset,
    required this.zIndex,
    required this.visibility,
    required this.animation,
  });

  final String id;
  final String asset;
  final int zIndex;
  final PlazaLayerVisibility visibility;
  final PlazaLayerAnimation animation;

  static PlazaLayerVisibility parseVisibility(String? raw) {
    return switch (raw) {
      'day' => PlazaLayerVisibility.day,
      'night' => PlazaLayerVisibility.night,
      _ => PlazaLayerVisibility.always,
    };
  }

  static PlazaLayerAnimation parseAnimation(String? raw) {
    return switch (raw) {
      'river_flow' => PlazaLayerAnimation.riverFlow,
      'fountain_flow' => PlazaLayerAnimation.fountainFlow,
      'tree_sway' => PlazaLayerAnimation.treeSway,
      'flags_sway' => PlazaLayerAnimation.flagsSway,
      'lights_flicker' => PlazaLayerAnimation.lightsFlicker,
      'celestial_roll' => PlazaLayerAnimation.celestialRoll,
      _ => PlazaLayerAnimation.none,
    };
  }

  factory PlazaLayerDef.fromJson(Map<String, dynamic> json) {
    return PlazaLayerDef(
      id: json['id'] as String,
      asset: json['asset'] as String,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      visibility: parseVisibility(json['visibility'] as String?),
      animation: parseAnimation(json['animation'] as String?),
    );
  }
}

class PlazaLayersConfig {
  PlazaLayersConfig({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layers,
    required this.legacyDayAsset,
    required this.legacyNightAsset,
    required this.sunUv,
    required this.moonUv,
    required this.rollDurationSeconds,
  });

  final double canvasWidth;
  final double canvasHeight;
  final List<PlazaLayerDef> layers;
  final String legacyDayAsset;
  final String legacyNightAsset;
  final Offset sunUv;
  final Offset moonUv;
  final double rollDurationSeconds;

  static const assetPath = 'assets/data/locations/l1_plaza_layers.json';

  static Future<PlazaLayersConfig> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final canvas = (json['canvasSize'] as List<dynamic>).cast<num>();
    final legacy = json['legacyFallback'] as Map<String, dynamic>;
    final celestial = json['celestial'] as Map<String, dynamic>? ?? {};
    final sun = (celestial['sunUv'] as List<dynamic>?)?.cast<num>() ?? [0.78, 0.12];
    final moon = (celestial['moonUv'] as List<dynamic>?)?.cast<num>() ?? [0.22, 0.14];

    final layerList = (json['layers'] as List<dynamic>)
        .map((e) => PlazaLayerDef.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return PlazaLayersConfig(
      canvasWidth: canvas[0].toDouble(),
      canvasHeight: canvas[1].toDouble(),
      layers: layerList,
      legacyDayAsset: legacy['day'] as String,
      legacyNightAsset: legacy['night'] as String,
      sunUv: Offset(sun[0].toDouble(), sun[1].toDouble()),
      moonUv: Offset(moon[0].toDouble(), moon[1].toDouble()),
      rollDurationSeconds: (celestial['rollDurationSeconds'] as num?)?.toDouble() ?? 1.4,
    );
  }
}
