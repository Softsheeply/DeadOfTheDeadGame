import 'package:shared_preferences/shared_preferences.dart';

import 'plaza_mission.dart';
import 'plaza_tutorial.dart';

/// Local save for mute, day/night, mission, tutorial, reduce-motion.
class PlazaPrefs {
  SharedPreferences? _prefs;
  bool muted = false;
  bool isNight = true;
  bool tutorialSeen = false;
  int tutorialStep = 0;
  bool reduceMotion = false;
  MissionId missionId = MissionId.marigolds;
  int missionProgress = 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    muted = p.getBool(_kMute) ?? false;
    isNight = p.getBool(_kNight) ?? true;
    tutorialSeen = p.getBool(_kTutorial) ?? false;
    tutorialStep = p.getInt(_kTutorialStep) ??
        (tutorialSeen ? PlazaTutorial.stepCount : 0);
    reduceMotion = p.getBool(_kReduceMotion) ?? false;
    missionId = MissionId.values.firstWhere(
      (id) => id.name == (p.getString(_kMissionId) ?? ''),
      orElse: () => MissionId.marigolds,
    );
    missionProgress = p.getInt(_kMissionProgress) ?? 0;
  }

  Future<void> setMuted(bool value) async {
    muted = value;
    await _writeBool(_kMute, value);
  }

  Future<void> setNight(bool value) async {
    isNight = value;
    await _writeBool(_kNight, value);
  }

  Future<void> setTutorialStep(int value) async {
    tutorialStep = value.clamp(0, PlazaTutorial.stepCount);
    tutorialSeen = PlazaTutorial.isComplete(tutorialStep);
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setInt(_kTutorialStep, tutorialStep);
    await p.setBool(_kTutorial, tutorialSeen);
  }

  Future<void> setTutorialSeen(bool value) async {
    tutorialSeen = value;
    tutorialStep = value ? PlazaTutorial.stepCount : 0;
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setBool(_kTutorial, value);
    await p.setInt(_kTutorialStep, tutorialStep);
  }

  Future<void> setReduceMotion(bool value) async {
    reduceMotion = value;
    await _writeBool(_kReduceMotion, value);
  }

  Future<void> saveMission(MissionId id, int progress) async {
    missionId = id;
    missionProgress = progress;
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setString(_kMissionId, id.name);
    await p.setInt(_kMissionProgress, progress);
  }

  Future<void> _writeBool(String key, bool value) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    await p.setBool(key, value);
  }

  static const _kMute = 'plaza_mute';
  static const _kNight = 'plaza_night';
  static const _kTutorial = 'plaza_tutorial_seen';
  static const _kTutorialStep = 'plaza_tutorial_step';
  static const _kReduceMotion = 'plaza_reduce_motion';
  static const _kMissionId = 'plaza_mission_id';
  static const _kMissionProgress = 'plaza_mission_progress';
}
