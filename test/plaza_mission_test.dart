import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/plaza_mission.dart';

void main() {
  test('marigold mission completes after three ofrenda offerings', () {
    final mission = PlazaMission();
    expect(mission.current, MissionId.marigolds);
    expect(mission.reportOfrendaPetals(), isFalse);
    expect(mission.progress.value, 1);
    expect(mission.reportOfrendaPetals(), isFalse);
    expect(mission.reportOfrendaPetals(), isTrue);
    expect(mission.completedFlash.value, isTrue);

    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.mariachi);
    expect(mission.progress.value, 0);
    expect(mission.reportMariachi(), isTrue);
  });

  test('wrong mission action is ignored', () {
    final mission = PlazaMission();
    expect(mission.reportMariachi(), isFalse);
    expect(mission.progress.value, 0);
  });
}
