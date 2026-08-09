import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/cast_journal.dart';
import 'package:dead_of_the_dead_game/data/location_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocationConfig loads festival plaza JSON', () async {
    final location = await LocationConfig.loadAsset(
      'assets/data/locations/l1_festival_plaza.json',
    );
    expect(location.id, 'l1_festival_plaza');
    expect(location.hotspotUvs.length, 9);
    expect(location.occluders.length, 4);
    expect(location.defaultCastOnPlaza, contains('pepita'));
  });

  test('CastJournal loads bios for full roster', () async {
    final journal = CastJournal();
    await journal.load();
    expect(journal.bioFor('pepita')?.role, 'Florist');
    expect(journal.all.length, 12);
  });
}
