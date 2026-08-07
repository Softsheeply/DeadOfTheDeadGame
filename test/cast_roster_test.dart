import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/cast_roster.dart';

void main() {
  test('roster starts with core cast on and guests off by default map', () {
    final roster = CastRoster();
    // Defaults from CastMemberInfo.defaultOnPlaza are true; game overrides guests.
    expect(roster.members.length, 8);
    expect(roster.members.map((m) => m.id), containsAll(['gato', 'tito', 'miguel']));
  });

  test('toggle flips plaza presence', () {
    final roster = CastRoster()..setOnPlaza('tito', false);
    expect(roster.isOnPlaza('tito'), false);
    roster.toggle('tito');
    expect(roster.isOnPlaza('tito'), true);
  });
}
