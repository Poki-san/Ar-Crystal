part of '../create_screen.dart';

/* Рисует спокойную заглушку, пока камера ещё не успела инициализироваться. */
class _OrganicTexturePainter extends CustomPainter {
  static const int _lineCount = 14;
  static const double _waveWidth = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int index = 0; index < _lineCount; index++) {
      paint.color = _lineColor(index);
      canvas.drawPath(_buildWave(size, index), paint);
    }
  }

  Color _lineColor(int index) {
    final Color base = index.isEven ? AppColors.acid : AppColors.orange;
    return base.withValues(alpha: .05 + (index % 4) * .018);
  }

  Path _buildWave(Size size, int index) {
    final double y = size.height * index / _lineCount;
    final double waveHeight = index.isEven ? 22 : -20;
    final Path path = Path()..moveTo(-20, y);
    for (double x = 0; x <= size.width + 40; x += _waveWidth) {
      path.quadraticBezierTo(
        x + _waveWidth / 2,
        y + waveHeight,
        x + _waveWidth,
        y,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* Накладывает направляющую сетку и уголки области захвата поверх камеры. */
class _ScannerOverlayPainter extends CustomPainter {
  static const double _top = 110;
  static const double _bottomInset = 230;
  static const double _sideInset = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect frame = Rect.fromLTRB(
      _sideInset,
      _top,
      size.width - _sideInset,
      size.height - _bottomInset,
    );
    _paintGrid(canvas, frame);
    _paintCorners(canvas, frame);
  }

  void _paintGrid(Canvas canvas, Rect frame) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..strokeWidth = .8;
    for (int index = 1; index < 4; index++) {
      final double x = frame.left + frame.width * index / 4;
      final double y = frame.top + frame.height * index / 4;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), paint);
      canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), paint);
    }
  }

  void _paintCorners(Canvas canvas, Rect frame) {
    final Paint paint = Paint()
      ..color = AppColors.acid
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    const double length = 28;
    canvas.drawPath(
      Path()
        ..moveTo(frame.left, frame.top + length)
        ..lineTo(frame.left, frame.top)
        ..lineTo(frame.left + length, frame.top),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(frame.right - length, frame.bottom)
        ..lineTo(frame.right, frame.bottom)
        ..lineTo(frame.right, frame.bottom - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
