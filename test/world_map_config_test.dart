import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/world_map_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WorldMapConfig loads eight nodes with plaza unlocked', () async {
    final map = WorldMapConfig();
    await map.load();
    expect(map.nodes.length, 8);
    expect(map.nodes.first.id, 'l1_festival_plaza');
    expect(map.nodes.first.unlocked, isTrue);
    expect(map.nodes.where((node) => !node.unlocked).length, 7);
  });
}
