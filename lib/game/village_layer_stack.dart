import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

import '../data/plaza_layers_config.dart';

/// Composited plaza backdrop: optional PNG layers + legacy day/night fallback.
class VillageLayerStack extends PositionComponent {
  VillageLayerStack({required this.config, required Vector2 gameSize})
      : super(priority: -100, position: Vector2.zero()) {
    size = gameSize.clone();
  }

  final PlazaLayersConfig config;
  final Map<String, Sprite> _sprites = {};
  Sprite? _legacyDay;
  Sprite? _legacyNight;
  bool _useLayers = false;
  bool isNight = true;
  double nightBlend = 1;
  double celestialRoll = 0;
  double _time = 0;
  double _wind = 0.35;
  double _gust = 0;
  double _fountainSplash = 0;
  Rect drawRect = Rect.zero;

  static const _letterboxColor = Color(0xFF120A24);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    var loaded = 0;
    for (final layer in config.layers) {
      try {
        final path = layer.asset.replaceFirst('assets/images/', '');
        _sprites[layer.id] = Sprite(await Flame.images.load(path));
        loaded++;
      } catch (_) {
        // Layer art not shipped yet — fall back to legacy plates.
      }
    }
    _useLayers = loaded >= 3;

    try {
      _legacyDay = Sprite(
        await Flame.images.load(
          config.legacyDayAsset.replaceFirst('assets/images/', ''),
        ),
      );
      _legacyNight = Sprite(
        await Flame.images.load(
          config.legacyNightAsset.replaceFirst('assets/images/', ''),
        ),
      );
    } catch (_) {}

    _recomputeDrawRect();
  }

  void resizeTo(Vector2 newSize) {
    size.setFrom(newSize);
    _recomputeDrawRect();
  }

  void setNightBlend(double blend) {
    nightBlend = blend.clamp(0.0, 1.0);
    isNight = nightBlend >= 0.5;
  }

  void setCelestialRoll(double roll) {
    celestialRoll = roll.clamp(0.0, 1.0);
  }

  void applyGust({required double directionSign}) {
    _gust = 1.0;
    _wind = directionSign >= 0 ? 1.0 : -1.0;
    _fountainSplash = 1.0;
  }

  void splashFountain({double intensity = 1}) {
    _fountainSplash = (_fountainSplash + intensity).clamp(0.0, 1.6);
  }

  void _recomputeDrawRect() {
    final refW = config.canvasWidth;
    final refH = config.canvasHeight;
    if (size.x <= 0 || size.y <= 0) {
      drawRect = Rect.zero;
      return;
    }
    final scale = min(size.x / refW, size.y / refH);
    drawRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: refW * scale,
      height: refH * scale,
    );
  }

  bool _layerVisible(PlazaLayerDef layer) {
    return switch (layer.visibility) {
      PlazaLayerVisibility.always => true,
      PlazaLayerVisibility.day => nightBlend < 0.98,
      PlazaLayerVisibility.night => nightBlend > 0.02,
    };
  }

  double _layerAlpha(PlazaLayerDef layer) {
    return switch (layer.visibility) {
      PlazaLayerVisibility.always => 1.0,
      PlazaLayerVisibility.day => (1 - nightBlend).clamp(0.0, 1.0),
      PlazaLayerVisibility.night => nightBlend.clamp(0.0, 1.0),
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_gust > 0) _gust = max(0, _gust - dt * 0.55);
    if (_fountainSplash > 0) _fountainSplash = max(0, _fountainSplash - dt * 0.9);
    _wind += (0.35 * (_wind.sign == 0 ? 1 : _wind.sign) - _wind) * min(1, dt * 0.35);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = _letterboxColor,
    );
    if (drawRect == Rect.zero) return;

    if (!_useLayers) {
      _renderLegacy(canvas);
      return;
    }

    for (final layer in config.layers) {
      if (!_layerVisible(layer)) continue;
      final sprite = _sprites[layer.id];
      if (sprite == null) continue;
      final alpha = _layerAlpha(layer);
      if (alpha <= 0.01) continue;
      _renderAnimatedLayer(canvas, layer, sprite, alpha);
    }
  }

  void _renderLegacy(Canvas canvas) {
    if (nightBlend < 1 && _legacyDay != null) {
      _legacyDay!.renderRect(canvas, drawRect);
    }
    if (nightBlend > 0 && _legacyNight != null) {
      _legacyNight!.renderRect(
        canvas,
        drawRect,
        overridePaint: Paint()..color = Color.fromRGBO(255, 255, 255, nightBlend),
      );
    }
    _renderCodedCelestial(canvas);
  }

  void _renderCodedCelestial(Canvas canvas) {
    final roll = celestialRoll;
    final goingNight = nightBlend >= 0.5;
    final sunCenter = Offset(
      drawRect.left + drawRect.width * config.sunUv.dx,
      drawRect.top + drawRect.height * config.sunUv.dy,
    );
    final moonCenter = Offset(
      drawRect.left + drawRect.width * config.moonUv.dx,
      drawRect.top + drawRect.height * config.moonUv.dy,
    );
    final r = drawRect.width * 0.035;

    if (nightBlend < 0.98) {
      final sunAlpha = (1 - nightBlend).clamp(0.0, 1.0);
      final sunDx = goingNight ? -drawRect.width * roll : 0.0;
      canvas.drawCircle(
        sunCenter.translate(sunDx, 0),
        r,
        Paint()..color = Color.fromRGBO(255, 220, 100, sunAlpha),
      );
    }
    if (nightBlend > 0.02) {
      final moonAlpha = nightBlend.clamp(0.0, 1.0);
      final moonDx = goingNight ? drawRect.width * (1 - roll) : drawRect.width * roll;
      canvas.drawCircle(
        moonCenter.translate(moonDx, 0),
        r * 0.9,
        Paint()..color = Color.fromRGBO(230, 240, 255, moonAlpha),
      );
    }
  }

  void _renderAnimatedLayer(Canvas canvas, PlazaLayerDef layer, Sprite sprite, double alpha) {
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
    final windStrength = (_wind.abs() * 0.35 + _gust).clamp(0.0, 1.6);

    switch (layer.animation) {
      case PlazaLayerAnimation.celestialRoll:
        _renderCelestialSprite(canvas, layer.id, sprite, paint);
      case PlazaLayerAnimation.treeSway:
        _renderSway(canvas, sprite, paint, amount: 0.018 + windStrength * 0.03, pivotY: 0.55);
      case PlazaLayerAnimation.flagsSway:
        _renderSway(canvas, sprite, paint, amount: 0.03 + windStrength * 0.06, pivotY: 0.08);
      case PlazaLayerAnimation.riverFlow:
        _renderFlow(canvas, sprite, paint);
      case PlazaLayerAnimation.fountainFlow:
        _renderFountain(canvas, sprite, paint);
      case PlazaLayerAnimation.lightsFlicker:
        _renderFlicker(canvas, sprite, paint);
      case PlazaLayerAnimation.none:
        sprite.renderRect(canvas, drawRect, overridePaint: paint);
    }
  }

  void _renderCelestialSprite(Canvas canvas, String id, Sprite sprite, Paint paint) {
    final uv = id == 'sun' ? config.sunUv : config.moonUv;
    final goingNight = nightBlend >= 0.5;
    final roll = celestialRoll;
    final sizePx = drawRect.width * 0.09;
    final center = Offset(
      drawRect.left + drawRect.width * uv.dx,
      drawRect.top + drawRect.height * uv.dy,
    );
    var dx = 0.0;
    if (id == 'sun') {
      dx = goingNight ? -drawRect.width * roll : 0;
    } else {
      dx = goingNight ? drawRect.width * (1 - roll) : drawRect.width * roll;
    }
    final rect = Rect.fromCenter(center: center.translate(dx, 0), width: sizePx, height: sizePx);
    sprite.renderRect(canvas, rect, overridePaint: paint);
  }

  void _renderSway(Canvas canvas, Sprite sprite, Paint paint, {required double amount, required double pivotY}) {
    final sway = sin(_time * 1.2) * amount + _gust * 0.04 * _wind.sign;
    final pivot = Offset(drawRect.center.dx, drawRect.top + drawRect.height * pivotY);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(sway);
    canvas.translate(-pivot.dx, -pivot.dy);
    sprite.renderRect(canvas, drawRect, overridePaint: paint);
    canvas.restore();
  }

  void _renderFlow(Canvas canvas, Sprite sprite, Paint paint) {
    final shift = (_time * 0.6 * drawRect.width * 0.015) % (drawRect.width * 0.04);
    canvas.save();
    canvas.translate(shift, sin(_time * 2.1) * 1.5);
    sprite.renderRect(canvas, drawRect, overridePaint: paint);
    canvas.restore();
  }

  void _renderFountain(Canvas canvas, Sprite sprite, Paint paint) {
    final pulse = 1 + sin(_time * 3.2) * 0.012 + _fountainSplash * 0.025;
    canvas.save();
    canvas.translate(0, (1 - pulse) * drawRect.height * 0.008);
    final p = Paint()..color = paint.color.withValues(alpha: paint.color.a * (0.92 + _fountainSplash * 0.08));
    sprite.renderRect(canvas, drawRect, overridePaint: p);
    canvas.restore();
  }

  void _renderFlicker(Canvas canvas, Sprite sprite, Paint paint) {
    final flicker = 0.82 + 0.18 * sin(_time * 6.5 + 0.3) * sin(_time * 3.1);
    final p = Paint()..color = paint.color.withValues(alpha: paint.color.a * flicker);
    sprite.renderRect(canvas, drawRect, overridePaint: p);
  }
}
