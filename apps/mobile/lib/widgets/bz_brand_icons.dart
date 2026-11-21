import 'package:material_ui/material_ui.dart';

/// Breezze brand marks as vector widgets.
///
/// Widget forms of assets/icons/*.svg; they inherit any token color.
class BzBnoteMark extends StatelessWidget {
  final double size;
  final Color? color;

  const BzBnoteMark({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BnotePainter(c), size: Size.square(size)),
    );
  }
}

class _BnotePainter extends CustomPainter {
  final Color color;
  _BnotePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final x = size.width;
    final y = size.height;

    // Stem of the B.
    canvas.drawLine(Offset(x * 0.34, y * 0.26), Offset(x * 0.34, y * 0.74), paint);

    // Upper bowl.
    final upper = Path()
      ..moveTo(x * 0.34, y * 0.26)
      ..lineTo(x * 0.58, y * 0.26)
      ..arcToPoint(Offset(x * 0.58, y * 0.47),
          radius: Radius.circular(x * 0.11), clockwise: true)
      ..lineTo(x * 0.34, y * 0.47);
    canvas.drawPath(upper, paint);

    // Lower bowl.
    final lower = Path()
      ..moveTo(x * 0.34, y * 0.47)
      ..lineTo(x * 0.61, y * 0.47)
      ..arcToPoint(Offset(x * 0.61, y * 0.69),
          radius: Radius.circular(x * 0.11), clockwise: true)
      ..lineTo(x * 0.34, y * 0.69);
    canvas.drawPath(lower, paint);

    // Music-note flag on the right of the lower bowl.
    final flag = Path()
      ..moveTo(x * 0.61, y * 0.69)
      ..lineTo(x * 0.65, y * 0.69)
      ..lineTo(x * 0.65, y * 0.50);
    canvas.drawPath(flag, paint);

    final note = Path()
      ..moveTo(x * 0.65, y * 0.50)
      ..arcToPoint(Offset(x * 0.65, y * 0.60),
          radius: Radius.circular(x * 0.05), clockwise: false);
    canvas.drawPath(note, paint);
  }

  @override
  bool shouldRepaint(_BnotePainter oldDelegate) => oldDelegate.color != color;
}

/// The ribbon-B logo with sound-wave tail.
class BzRibbonLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const BzRibbonLogo({super.key, this.width = 120, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: width,
      height: width * 0.8,
      child: CustomPaint(painter: _RibbonPainter(c)),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final Color color;
  _RibbonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Vertical stem.
    final stem = Path()
      ..moveTo(w * 0.22, h * 0.23)
      ..lineTo(w * 0.22, h * 0.77);
    canvas.drawPath(stem, paint);

    // Upper bowl.
    final upper = Path()
      ..moveTo(w * 0.22, h * 0.23)
      ..lineTo(w * 0.44, h * 0.23)
      ..arcToPoint(Offset(w * 0.44, h * 0.51),
          radius: Radius.circular(w * 0.14), clockwise: true)
      ..lineTo(w * 0.22, h * 0.51);
    canvas.drawPath(upper, paint);

    // Lower bowl.
    final lower = Path()
      ..moveTo(w * 0.22, h * 0.51)
      ..lineTo(w * 0.49, h * 0.51)
      ..arcToPoint(Offset(w * 0.49, h * 0.69),
          radius: Radius.circular(w * 0.16), clockwise: true)
      ..lineTo(w * 0.22, h * 0.69);
    canvas.drawPath(lower, paint);

    // Sound-wave tail flowing right.
    final wave1 = Path()
      ..moveTo(w * 0.60, h * 0.50)
      ..cubicTo(w * 0.64, h * 0.43, w * 0.68, h * 0.43, w * 0.72, h * 0.48);
    canvas.drawPath(wave1, paint);

    final wave2 = Path()
      ..moveTo(w * 0.60, h * 0.58)
      ..cubicTo(w * 0.65, h * 0.66, w * 0.71, h * 0.67, w * 0.76, h * 0.62);
    canvas.drawPath(wave2, paint);

    final wave3 = Path()
      ..moveTo(w * 0.60, h * 0.42)
      ..cubicTo(w * 0.64, h * 0.35, w * 0.69, h * 0.34, w * 0.73, h * 0.38);
    canvas.drawPath(wave3, paint);
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => oldDelegate.color != color;
}
