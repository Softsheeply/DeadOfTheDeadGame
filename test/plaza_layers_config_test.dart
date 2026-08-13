import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/plaza_layers_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('l1_plaza_layers.json defines layer stack manifest', () async {
    final config = await PlazaLayersConfig.load();
    expect(config.canvasWidth, 1280);
    expect(config.layers.length, greaterThanOrEqualTo(8));
    expect(config.layers.any((l) => l.id == 'river'), isTrue);
    expect(config.layers.any((l) => l.id == 'fountain'), isTrue);
    expect(config.layers.any((l) => l.id == 'lights'), isTrue);
  });
}
