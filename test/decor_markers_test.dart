import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decor_markers.json lists plaza buildings and fx markers', () async {
    final raw = await rootBundle.loadString('assets/images/village/decor_markers.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final buildings = json['buildings'] as List<dynamic>;
    final fx = json['fx'] as List<dynamic>;
    expect(buildings.length, greaterThanOrEqualTo(5));
    expect(fx.any((e) => (e as Map)['type'] == 'water'), true);
    expect(fx.where((e) => (e as Map)['type'] == 'candle').length, greaterThanOrEqualTo(12));
    expect(fx.any((e) => (e as Map)['type'] == 'lantern'), true);
    expect(fx.any((e) => (e as Map)['type'] == 'oven'), true);
  });
}
