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

class LocationBlockedEllipse {
  const LocationBlockedEllipse({
    required this.center,
    required this.rx,
    required this.ry,
  });

  final Offset center;
  final double rx;
  final double ry;

  factory LocationBlockedEllipse.fromJson(Map<String, dynamic> json) {
    final center = (json['center'] as List).cast<num>();
    return LocationBlockedEllipse(
      center: Offset(center[0].toDouble(), center[1].toDouble()),
      rx: (json['rx'] as num).toDouble(),
      ry: (json['ry'] as num).toDouble(),
    );
  }

  (Offset, double, double) get asRecord => (center, rx, ry);
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
    required this.fountainCenter,
    required this.fountainRadiusX,
    required this.fountainRadiusY,
    required this.hotspotUvs,
    required this.restSpotUvs,
    required this.blockedEllipses,
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
  final Offset fountainCenter;
  final double fountainRadiusX;
  final double fountainRadiusY;
  final List<Offset> hotspotUvs;
  final List<Offset> restSpotUvs;
  final List<LocationBlockedEllipse> blockedEllipses;
  final List<LocationOccluderDef> occluders;
  final String decorMarkers;
  final List<String> defaultCastOnPlaza;

  List<(Offset, double, double)> get blockedEllipseRecords =>
      blockedEllipses.map((e) => e.asRecord).toList(growable: false);

  factory LocationConfig.fromJson(Map<String, dynamic> json) {
    List<Offset> readUvs(List<dynamic> list) {
      return [
        for (final entry in list)
          if (entry is List && entry.length >= 2)
            Offset((entry[0] as num).toDouble(), (entry[1] as num).toDouble()),
      ];
    }

    final ofrenda = (json['ofrendaUv'] as List).cast<num>();
    final blocked = [
      for (final entry in json['blockedEllipses'] as List<dynamic>)
        LocationBlockedEllipse.fromJson(entry as Map<String, dynamic>),
    ];
    final fountain = blocked.isNotEmpty ? blocked.first : null;
    return LocationConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      unlockedByDefault: json['unlockedByDefault'] as bool? ?? false,
      backdrops: (json['backdrops'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      road: LocationRoad.fromJson(json['road'] as Map<String, dynamic>),
      ofrendaUv: Offset(ofrenda[0].toDouble(), ofrenda[1].toDouble()),
      fountainCenter: fountain?.center ?? const Offset(0.575, 0.62),
      fountainRadiusX: fountain?.rx ?? 0.05,
      fountainRadiusY: fountain?.ry ?? 0.07,
      hotspotUvs: readUvs(json['hotspotUvs'] as List<dynamic>),
      restSpotUvs: readUvs(json['restSpotUvs'] as List<dynamic>),
      blockedEllipses: blocked,
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
