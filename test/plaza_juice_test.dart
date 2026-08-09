import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/plaza_juice.dart';

void main() {
  test('PlazaBuildingReactions returns building-specific flavor', () {
    expect(
      PlazaBuildingReactions.flavorLine('floristeria', 'fallback'),
      contains('Pepita'),
    );
    expect(
      PlazaBuildingReactions.flavorLine('unknown', 'fallback'),
      'fallback',
    );
  });

  test('PlazaBuildingReactions maps cast affinity per building', () {
    expect(PlazaBuildingReactions.affinityFor('mariachi_stage'), contains('tito'));
    expect(PlazaBuildingReactions.affinityFor('nope'), isEmpty);
  });

  test('PlazaRareEvents status lines cover all kinds', () {
    for (final kind in PlazaRareEventKind.values) {
      expect(PlazaRareEvents.statusLine(kind), isNotEmpty);
    }
  });
}
