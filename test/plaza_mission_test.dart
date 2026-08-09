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

  test('festival mission set follows welcome loop', () {
    final mission = PlazaMission();
    for (var i = 0; i < 3; i++) {
      mission.reportOfrendaPetals();
    }
    mission.advanceAfterCelebration(); // mariachi
    mission.reportMariachi();
    mission.advanceAfterCelebration(); // xolo
    mission.reportXoloFed();
    mission.advanceAfterCelebration(); // candles
    for (var i = 0; i < 5; i++) {
      mission.reportCandleLit();
    }
    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.stageEncore);
    expect(mission.currentSet, MissionSet.festival);

    expect(mission.reportMariachi(), isFalse);
    expect(mission.reportMariachi(), isTrue);
    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.candlePath);

    for (var i = 0; i < 7; i++) {
      mission.reportCandleLit();
    }
    expect(mission.reportCandleLit(), isTrue);
    mission.advanceAfterCelebration();

    expect(mission.reportXoloFed(), isFalse);
    expect(mission.reportXoloFed(), isTrue);
    mission.advanceAfterCelebration();

    for (var i = 0; i < 2; i++) {
      expect(mission.reportOfrendaTap(), isFalse);
    }
    expect(mission.reportOfrendaTap(), isTrue);
    mission.advanceAfterCelebration();
    expect(mission.current, MissionId.marigolds);
  });

  test('reportOfrendaTap only counts during tribute mission', () {
    final mission = PlazaMission();
    expect(mission.reportOfrendaTap(), isFalse);
    mission.restore(MissionId.ofrendaTribute, 0);
    expect(mission.reportOfrendaTap(), isFalse);
    expect(mission.reportOfrendaTap(), isFalse);
    expect(mission.reportOfrendaTap(), isTrue);
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
