import 'package:flutter/material.dart';

/// Onboarding beads shown once per install (skippable).
class PlazaTutorialStep {
  const PlazaTutorialStep({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;
}

class PlazaTutorial {
  const PlazaTutorial._();

  static const steps = <PlazaTutorialStep>[
    PlazaTutorialStep(
      message: 'Drag anyone — they’re toys',
      icon: Icons.back_hand_rounded,
    ),
    PlazaTutorialStep(
      message: 'Tap the sun / moon to flip day & night',
      icon: Icons.wb_sunny_rounded,
    ),
    PlazaTutorialStep(
      message: 'Try wind, petals, music & pan dulce',
      icon: Icons.toys_rounded,
    ),
    PlazaTutorialStep(
      message: 'Follow the mission — it loops forever',
      icon: Icons.flag_rounded,
    ),
  ];

  static int get stepCount => steps.length;

  static bool isComplete(int step) => step >= stepCount;

  static PlazaTutorialStep? stepAt(int index) {
    if (index < 0 || index >= steps.length) return null;
    return steps[index];
  }
}
