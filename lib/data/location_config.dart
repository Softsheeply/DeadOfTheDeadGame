import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:flutter/services.dart' show rootBundle;

class LocationRoad {
  const LocationRoad({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;

  factory LocationRoad.fromJson(Map<String, dynamic> json) {
    return LocationRoad(
      left: (json['left'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }
}

class LocationOccluderDef {
  const LocationOccluderDef({
    required this.uv,
    required this.sortUvY,
    required this.radiusX,
    required this.radiusY,
  });

  final Offset uv;
  final double sortUvY;
  final double radiusX;
  final double radiusY;

  factory LocationOccluderDef.fromJson(Map<String, dynamic> json) {
    final uv = (json['uv'] as List).cast<num>();
    return LocationOccluderDef(
      uv: Offset(uv[0].toDouble(), uv[1].toDouble()),
      sortUvY: (json['sortUvY'] as num).toDouble(),
      radiusX: (json['radiusX'] as num).toDouble(),
      radiusY: (json['radiusY'] as num).toDouble(),
    );
  }
}

class LocationConfig {
  const LocationConfig({
    required this.id,
    required this.displayName,
    required this.unlockedByDefault,
    required this.backdrops,
    required this.road,
    required this.ofrendaUv,
    required this.hotspotUvs,
    required this.restSpotUvs,
    required this.occluders,
    required this.decorMarkers,
    required this.defaultCastOnPlaza,
  });

  final String id;
  final String displayName;
  final bool unlockedByDefault;
  final Map<String, String> backdrops;
  final LocationRoad road;
  final Offset ofrendaUv;
  final List<Offset> hotspotUvs;
  final List<Offset> restSpotUvs;
  final List<LocationOccluderDef> occluders;
  final String decorMarkers;
  final List<String> defaultCastOnPlaza;

  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    List<Offset> readUvs(List<dynamic> list) {
      return [
        for (final entry in list)
          if (entry is List && entry.length >= 2)
            Offset((entry[0] as num).toDouble(), (entry[1] as num).toDouble()),
      ];
    }

    final ofrenda = (json['ofrendaUv'] as List).cast<num>();
    return LocationConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      unlockedByDefault: json['unlockedByDefault'] as bool? ?? false,
      backdrops: (json['backdrops'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      road: LocationRoad.fromJson(json['road'] as Map<String, dynamic>),
      ofrendaUv: Offset(ofrenda[0].toDouble(), ofrenda[1].toDouble()),
      hotspotUvs: readUvs(json['hotspotUvs'] as List<dynamic>),
      restSpotUvs: readUvs(json['restSpotUvs'] as List<dynamic>),
      occluders: [
        for (final entry in json['occluders'] as List<dynamic>)
          LocationOccluderDef.fromJson(entry as Map<String, dynamic>),
      ],
      decorMarkers: json['decorMarkers'] as String,
      defaultCastOnPlaza: (json['defaultCastOnPlaza'] as List<dynamic>).cast<String>(),
    );
  }

  static Future<LocationConfig> loadAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    return LocationConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
