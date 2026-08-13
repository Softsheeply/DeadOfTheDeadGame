import 'package:flutter_test/flutter_test.dart';
import 'package:dead_of_the_dead_game/data/mission_catalog.dart';
import 'package:dead_of_the_dead_game/game/plaza_mission.dart';

Future<PlazaMission> _loadedMission() async {
  final catalog = MissionCatalog();
  await catalog.load();
  return PlazaMission(catalog);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mission loop advances through feedXolo and candles', () async {
    final mission = await _loadedMission();
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
    expect(mission.current, MissionId.stageEncore);
  });

  test('festival mission set follows welcome loop', () async {
    final mission = await _loadedMission();
    for (var i = 0; i < 3; i++) {
      mission.reportOfrendaPetals();
    }
    mission.advanceAfterCelebration();
    mission.reportMariachi();
    mission.advanceAfterCelebration();
    mission.reportXoloFed();
    mission.advanceAfterCelebration();
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

  test('reportOfrendaTap only counts during tribute mission', () async {
    final mission = await _loadedMission();
    expect(mission.reportOfrendaTap(), isFalse);
    mission.restore(MissionId.ofrendaTribute, 0);
    expect(mission.reportOfrendaTap(), isFalse);
    expect(mission.reportOfrendaTap(), isFalse);
    expect(mission.reportOfrendaTap(), isTrue);
  });

  test('wrong mission action is ignored', () async {
    final mission = await _loadedMission();
    expect(mission.reportMariachi(), isFalse);
    expect(mission.reportXoloFed(), isFalse);
    expect(mission.reportCandleLit(), isFalse);
    expect(mission.progress.value, 0);
  });

  test('restore resumes mid-mission progress', () async {
    final mission = await _loadedMission();
    mission.restore(MissionId.candles, 2);
    expect(mission.current, MissionId.candles);
    expect(mission.progress.value, 2);
    expect(mission.reportCandleLit(), isFalse);
    expect(mission.progress.value, 3);
  });
}
