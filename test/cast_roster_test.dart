import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/cast_roster.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('roster includes expanded cast with preferred hotspots', () {
    expect(kPlazaCast.length, greaterThanOrEqualTo(12));
    expect(
      kPlazaCast.map((m) => m.id),
      containsAll(['chavo', 'don_mateo', 'pinto', 'senor_cuervo']),
    );
    final tito = kPlazaCast.firstWhere((m) => m.id == 'tito');
    expect(tito.preferredHotspotIndexes, isNotEmpty);
  });

  test('persists on/off plaza choices', () async {
    SharedPreferences.setMockInitialValues({});
    final roster = CastRoster();
    await roster.load();
    expect(roster.isOnPlaza('pepita'), true);
    expect(roster.isOnPlaza('tito'), false);

    await roster.setOnPlaza('tito', true);
    expect(roster.isOnPlaza('tito'), true);

    final again = CastRoster();
    await again.load();
    expect(again.isOnPlaza('tito'), true);
  });
}
