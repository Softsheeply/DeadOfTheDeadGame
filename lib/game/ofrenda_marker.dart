import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'village_backdrop.dart';

/// Soft pulse ring marking the tree ofrenda — tappable landmark.
class OfrendaMarker extends Component {
  OfrendaMarker({required this.backdrop});

  final VillageBackdrop backdrop;
  double _pulse = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 2.2;
  }

  @override
  void render(Canvas canvas) {
    if (backdrop.drawRect == Rect.zero) return;
    final center = backdrop.ofrendaWorld;
    final r = backdrop.drawRect.width * 0.055;
    final breathe = 1 + 0.06 * sin(_pulse);
    final outer = Paint()
      ..color = Color.fromRGBO(243, 154, 60, 0.14 + 0.06 * sin(_pulse))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final inner = Paint()
      ..color = Color.fromRGBO(237, 87, 145, 0.22 + 0.08 * sin(_pulse + 1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(center.x, center.y), r * breathe, outer);
    canvas.drawCircle(Offset(center.x, center.y), r * 0.62 * breathe, inner);
    // Marigold dot at center
    canvas.drawCircle(
      Offset(center.x, center.y - 2),
      3.2,
      Paint()..color = const Color(0xAAF39A3C),
    );
  }
}
