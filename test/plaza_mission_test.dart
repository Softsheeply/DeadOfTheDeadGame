import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/game/plaza_mission.dart';
import 'package:dead_of_the_dead_game/game/plaza_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('mission loop advances through feedXolo and candles', () {
    final mission = PlazaMission();
    expect(mission.current, MissionId.marigolds);
    expect(mission.reportOfrendaPetals(), isFalse);
    expect(mission.reportOfrendaPetals(), isFalse);
    expect(mission.reportOfrendaPetals(), isTrue);

    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.mariachi);
    expect(mission.reportMariachi(), isTrue);

    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.feedXolo);
    expect(mission.reportXoloFed(), isTrue);

    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.candles);
    for (var i = 0; i < 4; i++) {
      expect(mission.reportCandleLit(), isFalse);
    }
    expect(mission.reportCandleLit(), isTrue);

    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.marigolds);
  });

  test('wrong mission action is ignored', () {
    final mission = PlazaMission();
    expect(mission.reportMariachi(), isFalse);
    expect(mission.reportXoloFed(), isFalse);
    expect(mission.reportCandleLit(), isFalse);
    expect(mission.progress.value, 0);
  });

  test('restore resumes mid-mission progress', () {
    final mission = PlazaMission();
    mission.restore(MissionId.candles, 2);
    expect(mission.current, MissionId.candles);
    expect(mission.progress.value, 2);
    expect(mission.reportCandleLit(), isFalse);
    expect(mission.progress.value, 3);
  });

  test('prefs persist mute night tutorial mission', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = PlazaPrefs();
    await prefs.load();
    await prefs.setMuted(true);
    await prefs.setNight(false);
    await prefs.setTutorialSeen(true);
    await prefs.setReduceMotion(true);
    await prefs.saveMission(MissionId.feedXolo, 0);

    final again = PlazaPrefs();
    await again.load();
    expect(again.muted, isTrue);
    expect(again.isNight, isFalse);
    expect(again.tutorialSeen, isTrue);
    expect(again.reduceMotion, isTrue);
    expect(again.missionId, MissionId.feedXolo);
  });
}
