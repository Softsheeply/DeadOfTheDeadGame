import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

/// Full-bleed Spirit Village backdrop from the Day of the Dead reference art.
///
/// Uses cover-fit so the painted plaza always fills the screen. Day/night
/// variants live under `assets/images/village/`.
class VillageBackdrop extends PositionComponent {
  VillageBackdrop({
    required Vector2 size,
    this.assetPath = 'village/spirit_village_plaza_night.png',
  }) : super(size: size, position: Vector2.zero(), priority: -100);

  /// Flame images path (relative to `assets/images/`).
  final String assetPath;

  Sprite? _sprite;
  Rect _drawRect = Rect.zero;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await Flame.images.load(assetPath);
    _sprite = Sprite(image);
    _recomputeDrawRect();
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
    _recomputeDrawRect();
  }

  /// Cover-fit the art into the current game size (may crop edges).
  void _recomputeDrawRect() {
    final sprite = _sprite;
    if (sprite == null || size.x <= 0 || size.y <= 0) {
      _drawRect = Rect.zero;
      return;
    }
    final imgW = sprite.srcSize.x;
    final imgH = sprite.srcSize.y;
    final scale = max(size.x / imgW, size.y / imgH);
    final drawW = imgW * scale;
    final drawH = imgH * scale;
    _drawRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: drawW,
      height: drawH,
    );
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null || _drawRect == Rect.zero) {
      // Fallback so a failed load isn't a blank purple void forever.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF1A0F3A),
      );
      return;
    }

    sprite.renderRect(canvas, _drawRect);

    // Soft bottom vignette keeps characters readable on busy cobbles.
    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0x00000000),
          Color(0x33000000),
          Color(0x660C0618),
        ],
        stops: const [0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignette);
  }
}
