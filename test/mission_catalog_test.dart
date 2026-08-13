import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/mission_catalog.dart';
import 'package:dead_of_the_dead_game/game/plaza_mission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MissionCatalog loads eight plaza steps', () async {
    final catalog = MissionCatalog();
    await catalog.load();
    expect(catalog.steps.length, 8);
    expect(catalog.defFor(MissionId.marigolds).goal, 3);
    expect(catalog.nextId(MissionId.ofrendaTribute), MissionId.marigolds);
    expect(catalog.setLabel(MissionId.stageEncore), 'Festival');
  });
}
