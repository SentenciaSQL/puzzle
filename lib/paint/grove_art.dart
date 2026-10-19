import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

class SkyPainter extends CustomPainter {
  SkyPainter(this.time, {this.motion = true});
  final double time;
  final bool motion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2A1860),
          Color(0xFF1A1448),
          Color(0xFF3A1C55),
          Color(0xFF1B3A48),
        ],
        stops: [0, 0.42, 0.72, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final moon = Paint()..color = const Color(0xFFFFF1C9);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.12),
      size.shortestSide * 0.055,
      moon,
    );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.11),
      size.shortestSide * 0.045,
      Paint()..color = const Color(0xFF2A1860),
    );

    _hill(canvas, size, 0.62, const Color(0xFF2C4A3A), 0.18);
    _hill(canvas, size, 0.72, const Color(0xFF243E55), 0.28);
    _hill(canvas, size, 0.84, const Color(0xFF1C3144), 0.08);

    final drift = motion ? math.sin(time / 1800) * 12 : 0;
    _tree(
      canvas,
      Offset(size.width * 0.12 + drift * 0.2, size.height * 0.78),
      size.shortestSide * 0.16,
    );
    _tree(
      canvas,
      Offset(size.width * 0.88, size.height * 0.74),
      size.shortestSide * 0.2,
    );
    if (motion) {
      for (var i = 0; i < 7; i++) {
        final phase = time / 700 + i;
        final x =
            (size.width * (0.15 + i * 0.12) + math.sin(phase) * 10) %
            size.width;
        final y =
            size.height * (0.18 + (i % 3) * 0.12) + math.cos(phase * 0.8) * 8;
        canvas.drawCircle(
          Offset(x, y),
          1.6 + (i % 3) * 0.6,
          Paint()..color = const Color(0xCCFFF6C8),
        );
      }
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x00000000), const Color(0x66100828)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  void _hill(Canvas canvas, Size size, double y, Color color, double bump) {
    final path = Path()..moveTo(0, size.height * y);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * (y - bump),
      size.width * 0.5,
      size.height * y,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height * (y + bump * 0.4),
      size.width,
      size.height * (y - bump * 0.2),
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _tree(Canvas canvas, Offset base, double height) {
    final trunk = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base.translate(0, -height * 0.18),
        width: height * 0.08,
        height: height * 0.36,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(trunk, Paint()..color = const Color(0xFF3A2416));
    final crown = Path()
      ..moveTo(base.dx, base.dy - height)
      ..quadraticBezierTo(
        base.dx + height * 0.42,
        base.dy - height * 0.55,
        base.dx + height * 0.08,
        base.dy - height * 0.28,
      )
      ..quadraticBezierTo(
        base.dx + height * 0.5,
        base.dy - height * 0.2,
        base.dx,
        base.dy - height * 0.05,
      )
      ..quadraticBezierTo(
        base.dx - height * 0.5,
        base.dy - height * 0.2,
        base.dx - height * 0.08,
        base.dy - height * 0.28,
      )
      ..quadraticBezierTo(
        base.dx - height * 0.42,
        base.dy - height * 0.55,
        base.dx,
        base.dy - height,
      );
    canvas.drawPath(crown, Paint()..color = const Color(0xFF1F6A4E));
    canvas.drawCircle(
      base.translate(height * 0.08, -height * 0.62),
      height * 0.06,
      Paint()..color = const Color(0xFFFF8FB8),
    );
  }

  @override
  bool shouldRepaint(SkyPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.motion != motion;
}

void paintGem(
  Canvas canvas,
  Rect rect,
  int gem, {
  String? special,
  double frost = 0,
  double alpha = 1,
  double scale = 1,
}) {
  if (alpha <= 0.01) return;
  canvas.save();
  final center = rect.center;
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  canvas.translate(-center.dx, -center.dy);
  final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
  canvas.saveLayer(rect.inflate(8), paint);

  final shadow = Rect.fromCenter(
    center: center.translate(0, rect.height * 0.08),
    width: rect.width * 0.72,
    height: rect.height * 0.22,
  );
  canvas.drawOval(shadow, Paint()..color = const Color(0x55301408));

  final body = rect.deflate(rect.width * 0.12);
  switch (gem.clamp(0, 5)) {
    case 0:
      _sunberry(canvas, body);
    case 1:
      _roseplum(canvas, body);
    case 2:
      _mint(canvas, body);
    case 3:
      _pearl(canvas, body);
    case 4:
      _dew(canvas, body);
    default:
      _fig(canvas, body);
  }
  if (special != null) _specialMark(canvas, body, special);
  if (frost > 0.02) _frost(canvas, body, frost);
  canvas.restore();
  canvas.restore();
}

void _gloss(Canvas canvas, Offset at, double rx, double ry) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(-0.6);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xEEFFFFFF), Color(0x22FFFFFF), Color(0x00FFFFFF)],
            stops: [0, 0.45, 1],
          ).createShader(
            Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
          ),
  );
  canvas.restore();
}

void _volume(Canvas canvas, Path path) {
  canvas.save();
  canvas.clipPath(path);
  canvas.drawRect(
    path.getBounds().inflate(4),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x4D461208)],
        stops: [0, 0.42, 1],
      ).createShader(path.getBounds()),
  );
  canvas.restore();
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x55FFFFFF),
  );
}

void _sunberry(Canvas canvas, Rect body) {
  final path = Path()..addOval(body);
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        body.center.translate(-body.width * 0.12, -body.height * 0.16),
        body.width * 0.7,
        const [
          Color(0xFFFFF6CF),
          Color(0xFFFFD15A),
          Color(0xFFF39A16),
          Color(0xFFD86A09),
        ],
        const [0, 0.28, 0.68, 1],
      ),
  );
  _volume(canvas, path);
  final leaf = Path()
    ..moveTo(body.center.dx, body.top + body.height * 0.18)
    ..quadraticBezierTo(
      body.right - 2,
      body.top - body.height * 0.08,
      body.center.dx + body.width * 0.08,
      body.top + body.height * 0.28,
    )
    ..quadraticBezierTo(
      body.center.dx,
      body.top + body.height * 0.16,
      body.center.dx,
      body.top + body.height * 0.18,
    );
  canvas.drawPath(leaf, Paint()..color = const Color(0xFF2F9A62));
  _gloss(
    canvas,
    body.center.translate(-body.width * 0.16, -body.height * 0.18),
    body.width * 0.16,
    body.height * 0.09,
  );
}

void _roseplum(Canvas canvas, Rect body) {
  final path = Path();
  final c = body.center;
  path.moveTo(c.dx, body.bottom - body.height * 0.06);
  path.cubicTo(
    body.left - 4,
    c.dy,
    body.left + body.width * 0.1,
    body.top,
    c.dx,
    body.top + body.height * 0.32,
  );
  path.cubicTo(
    body.right - body.width * 0.1,
    body.top,
    body.right + 4,
    c.dy,
    c.dx,
    body.bottom - body.height * 0.06,
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        c.translate(-6, -8),
        body.width * 0.7,
        const [Color(0xFFFFD0E2), Color(0xFFFF6B9D), Color(0xFFD23A74)],
        const [0, 0.45, 1],
      ),
  );
  _volume(canvas, path);
  _gloss(
    canvas,
    c.translate(-body.width * 0.12, -body.height * 0.12),
    body.width * 0.12,
    body.height * 0.07,
  );
}

void _mint(Canvas canvas, Rect body) {
  void drawLeaf(Offset center, double rot) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);
    final oval = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: body.width * 0.78,
          height: body.height * 0.4,
        ),
      );
    canvas.drawPath(
      oval,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-20, -10),
          const Offset(20, 16),
          const [Color(0xFFB8FFE8), Color(0xFF2EC9AE), Color(0xFF0E8F78)],
          const [0, 0.55, 1],
        ),
    );
    _volume(canvas, oval);
    canvas.drawLine(
      Offset(-body.width * 0.28, 0),
      Offset(body.width * 0.28, 0),
      Paint()
        ..color = const Color(0xAAEFFFF8)
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  drawLeaf(
    body.center.translate(-body.width * 0.08, -body.height * 0.08),
    -0.6,
  );
  drawLeaf(body.center.translate(body.width * 0.08, body.height * 0.08), 0.7);
}

void _pearl(Canvas canvas, Rect body) {
  final circle = Path()..addOval(body.deflate(body.width * 0.04));
  canvas.drawPath(
    circle,
    Paint()
      ..shader = ui.Gradient.radial(
        body.center.translate(-body.width * 0.15, -body.height * 0.18),
        body.width * 0.7,
        const [Color(0xFFF4E9FF), Color(0xFFB388FF), Color(0xFF6E4BD4)],
        const [0, 0.55, 1],
      ),
  );
  _volume(canvas, circle);
  final crescent = Path()
    ..addOval(
      body
          .deflate(body.width * 0.22)
          .shift(Offset(body.width * 0.12, -body.height * 0.02)),
    )
    ..addOval(body.deflate(body.width * 0.22).shift(const Offset(-2, 0)))
    ..fillType = PathFillType.evenOdd;
  canvas.save();
  canvas.clipPath(circle);
  canvas.drawPath(crescent, Paint()..color = const Color(0x66FFFFFF));
  canvas.restore();
  _gloss(
    canvas,
    body.center.translate(-body.width * 0.16, -body.height * 0.18),
    body.width * 0.14,
    body.height * 0.08,
  );
}

void _dew(Canvas canvas, Rect body) {
  final path = Path();
  path.moveTo(body.center.dx, body.top);
  path.quadraticBezierTo(
    body.right + 2,
    body.center.dy,
    body.center.dx,
    body.bottom,
  );
  path.quadraticBezierTo(
    body.left - 2,
    body.center.dy,
    body.center.dx,
    body.top,
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        body.center.translate(-4, -6),
        body.width * 0.65,
        const [Color(0xFFE7F6FF), Color(0xFF5EB6FF), Color(0xFF2C6FDB)],
        const [0, 0.5, 1],
      ),
  );
  _volume(canvas, path);
  _gloss(
    canvas,
    body.center.translate(-body.width * 0.1, -body.height * 0.12),
    body.width * 0.1,
    body.height * 0.14,
  );
}

void _fig(Canvas canvas, Rect body) {
  final path = Path();
  path.moveTo(body.center.dx, body.top + body.height * 0.08);
  path.cubicTo(
    body.right,
    body.top + body.height * 0.2,
    body.right - 2,
    body.bottom - 4,
    body.center.dx,
    body.bottom,
  );
  path.cubicTo(
    body.left + 2,
    body.bottom - 4,
    body.left,
    body.top + body.height * 0.2,
    body.center.dx,
    body.top + body.height * 0.08,
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.radial(
        body.center.translate(-4, -4),
        body.width * 0.7,
        const [Color(0xFFFFD0B0), Color(0xFFFF7A45), Color(0xFFD24A1E)],
        const [0, 0.5, 1],
      ),
  );
  _volume(canvas, path);
  canvas.drawLine(
    body.center.translate(0, -body.height * 0.05),
    body.center.translate(0, body.height * 0.22),
    Paint()
      ..color = const Color(0x66FFF1E4)
      ..strokeWidth = 1.3,
  );
  _gloss(
    canvas,
    body.center.translate(-body.width * 0.12, -body.height * 0.08),
    body.width * 0.1,
    body.height * 0.07,
  );
}

void _specialMark(Canvas canvas, Rect body, String special) {
  final paint = Paint()..color = const Color(0xF2FFFFFF);
  if (special == 'lineH' || special == 'lineV') {
    canvas.save();
    canvas.translate(body.center.dx, body.center.dy);
    if (special == 'lineV') canvas.rotate(math.pi / 2);
    final bar = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: body.width * 0.7,
        height: body.height * 0.16,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bar, paint);
    canvas.restore();
    return;
  }
  if (special == 'bomb') {
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final center =
          body.center +
          Offset(math.cos(angle), math.sin(angle)) * body.width * 0.22;
      canvas.drawCircle(
        center,
        body.width * 0.09,
        Paint()..color = const Color(0xFFFFF6C8),
      );
    }
    canvas.drawCircle(
      body.center,
      body.width * 0.1,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    return;
  }
  canvas.drawCircle(
    body.center,
    body.width * 0.28,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = body.width * 0.08
      ..shader = SweepGradient(colors: gemPalette).createShader(body),
  );
}

void _frost(Canvas canvas, Rect body, double frost) {
  final round = RRect.fromRectAndRadius(
    body.inflate(2),
    Radius.circular(body.width * 0.28),
  );
  canvas.drawRRect(
    round,
    Paint()..color = Colors.white.withValues(alpha: 0.28 * frost),
  );
  final crack = Paint()
    ..color = Colors.white.withValues(alpha: 0.7 * frost)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;
  canvas.drawLine(
    body.topLeft.translate(body.width * 0.2, body.height * 0.15),
    body.bottomRight.translate(-body.width * 0.15, -body.height * 0.1),
    crack,
  );
}

class BoardMetrics {
  BoardMetrics({
    required this.rows,
    required this.cols,
    required this.cell,
    required this.pad,
    required this.origin,
  });
  final int rows;
  final int cols;
  final double cell;
  final double pad;
  final Offset origin;

  double get width => pad * 2 + cols * cell;
  double get height => pad * 2 + rows * cell;
  Size get size => Size(width, height);

  Rect cellRect(double r, double c) =>
      Rect.fromLTWH(origin.dx + c * cell, origin.dy + r * cell, cell, cell);

  (int, int)? cellAt(Offset local) {
    final c = ((local.dx - origin.dx) / cell).floor();
    final r = ((local.dy - origin.dy) / cell).floor();
    if (r < 0 || c < 0 || r >= rows || c >= cols) return null;
    return (r, c);
  }

  static BoardMetrics fit({
    required int rows,
    required int cols,
    required double maxWidth,
    required double maxHeight,
    required bool wide,
  }) {
    final cap = wide ? 74.0 : 82.0;
    final byW = maxWidth / (cols + 0.95);
    final byH = maxHeight / (rows + 0.95);
    var cell = math.min(cap, math.min(byW, byH));
    if (!cell.isFinite || cell < 8) cell = 8;
    final pad = cell * 0.42;
    return BoardMetrics(
      rows: rows,
      cols: cols,
      cell: cell,
      pad: pad,
      origin: Offset(pad, pad),
    );
  }
}

void paintWood(
  Canvas canvas,
  BoardMetrics metrics, {
  double time = 0,
  (int, int)? selected,
  HintPulse? hint,
  double shake = 0,
}) {
  canvas.save();
  if (shake > 0) {
    canvas.translate(math.sin(time / 18) * (shake / 180) * 5, 0);
  }
  final board = RRect.fromRectAndRadius(
    Offset.zero & metrics.size,
    Radius.circular(metrics.cell * 0.28),
  );
  canvas.drawRRect(
    board.shift(const Offset(0, 8)),
    Paint()..color = const Color(0x55200C28),
  );
  canvas.drawRRect(
    board,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE7B06A), Color(0xFFC4843E), Color(0xFF8C4E22)],
      ).createShader(Offset.zero & metrics.size),
  );
  canvas.drawRRect(
    board.deflate(metrics.cell * 0.08),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x66FFF1D2),
  );
  for (var r = 0; r < metrics.rows; r++) {
    for (var c = 0; c < metrics.cols; c++) {
      final well = metrics
          .cellRect(r.toDouble(), c.toDouble())
          .deflate(metrics.cell * 0.06);
      canvas.drawRRect(
        RRect.fromRectAndRadius(well, Radius.circular(metrics.cell * 0.18)),
        Paint()..color = const Color(0x33210E08),
      );
    }
  }
  if (hint != null) {
    final pulse = 0.35 + 0.25 * math.sin(time / 180);
    for (final cell in [hint.a, hint.b]) {
      final well = metrics
          .cellRect(cell.$1.toDouble(), cell.$2.toDouble())
          .deflate(2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(well, Radius.circular(metrics.cell * 0.2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = gold.withValues(alpha: pulse),
      );
    }
  }
  if (selected != null) {
    final well = metrics
        .cellRect(selected.$1.toDouble(), selected.$2.toDouble())
        .deflate(1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(well, Radius.circular(metrics.cell * 0.2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color(0xFFFFF6C8),
    );
  }
  canvas.restore();
}

class HintPulse {
  const HintPulse(this.a, this.b);
  final (int, int) a;
  final (int, int) b;
}

void paintCoin(Canvas canvas, Size size) {
  final center = size.center(Offset.zero);
  final radius = size.shortestSide * 0.42;
  canvas.drawCircle(center, radius, Paint()..color = goldDeep);
  canvas.drawCircle(
    center.translate(-radius * 0.1, -radius * 0.12),
    radius * 0.86,
    Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        const [Color(0xFFFFE7A0), Color(0xFFFFC44D), Color(0xFFE0941D)],
        const [0, 0.55, 1],
      ),
  );
  final text = TextPainter(
    text: TextSpan(
      text: '✦',
      style: display(size.shortestSide * 0.46, color: goldInk),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
}

void paintStar(Canvas canvas, Size size, {bool lit = true}) {
  final path = _star(
    size.center(Offset.zero),
    size.shortestSide * 0.42,
    size.shortestSide * 0.18,
  );
  canvas.drawPath(path, Paint()..color = lit ? gold : const Color(0x66E7D3B8));
  if (lit) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFFF6D2),
    );
  }
}

Path _star(Offset center, double outer, double inner) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? outer : inner;
    final angle = -math.pi / 2 + i * math.pi / 5;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

class GroveMark extends StatelessWidget {
  const GroveMark(this.draw, {super.key, this.size = 28});
  final void Function(Canvas, Size) draw;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _MarkPainter(draw));
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.draw);
  final void Function(Canvas, Size) draw;
  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);
  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => false;
}

void paintHammer(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = cream
    ..strokeWidth = size.shortestSide * 0.1
    ..strokeCap = StrokeCap.round;
  final head = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.32),
      width: size.width * 0.62,
      height: size.height * 0.22,
    ),
    Radius.circular(size.width * 0.08),
  );
  canvas.drawRRect(head, Paint()..color = gold);
  canvas.drawLine(
    Offset(size.width * 0.5, size.height * 0.4),
    Offset(size.width * 0.5, size.height * 0.82),
    paint,
  );
}

void paintStir(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = cream
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.shortestSide * 0.09
    ..strokeCap = StrokeCap.round;
  final path = Path()
    ..addArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.16,
        size.width * 0.64,
        size.height * 0.64,
      ),
      0.4,
      4.6,
    );
  canvas.drawPath(path, paint);
  final tip = Offset(size.width * 0.72, size.height * 0.28);
  canvas.drawLine(
    tip,
    tip.translate(size.width * 0.08, -size.height * 0.02),
    paint,
  );
}

void paintPlus(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = gold
    ..strokeWidth = size.shortestSide * 0.12
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(size.width * 0.5, size.height * 0.22),
    Offset(size.width * 0.5, size.height * 0.78),
    paint,
  );
  canvas.drawLine(
    Offset(size.width * 0.22, size.height * 0.5),
    Offset(size.width * 0.78, size.height * 0.5),
    paint,
  );
}

void paintGift(Canvas canvas, Size size) {
  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.38,
      size.width * 0.64,
      size.height * 0.42,
    ),
    Radius.circular(size.width * 0.08),
  );
  canvas.drawRRect(box, Paint()..color = const Color(0xFFFF6B9D));
  canvas.drawRect(
    Rect.fromLTWH(
      size.width * 0.44,
      size.height * 0.38,
      size.width * 0.12,
      size.height * 0.42,
    ),
    Paint()..color = gold,
  );
  canvas.drawCircle(
    Offset(size.width * 0.4, size.height * 0.32),
    size.width * 0.1,
    Paint()..color = gold,
  );
  canvas.drawCircle(
    Offset(size.width * 0.6, size.height * 0.32),
    size.width * 0.1,
    Paint()..color = const Color(0xFFFFD0E2),
  );
}

void paintLock(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = creamDim
    ..style = PaintingStyle.stroke
    ..strokeWidth = size.shortestSide * 0.08;
  canvas.drawArc(
    Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.16,
      size.width * 0.44,
      size.height * 0.42,
    ),
    math.pi,
    math.pi,
    false,
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.42,
        size.width * 0.56,
        size.height * 0.4,
      ),
      Radius.circular(4),
    ),
    Paint()..color = creamDim,
  );
}

void paintGear(Canvas canvas, Size size) {
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final angle = i * math.pi / 4;
    final outer = i.isEven
        ? size.shortestSide * 0.38
        : size.shortestSide * 0.28;
    final point = Offset(math.cos(angle), math.sin(angle)) * outer;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = cream);
  canvas.drawCircle(
    Offset.zero,
    size.shortestSide * 0.12,
    Paint()..color = night,
  );
  canvas.restore();
}

void paintBack(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = cream
    ..strokeWidth = size.shortestSide * 0.09
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final path = Path()
    ..moveTo(size.width * 0.62, size.height * 0.22)
    ..lineTo(size.width * 0.32, size.height * 0.5)
    ..lineTo(size.width * 0.62, size.height * 0.78);
  canvas.drawPath(path, paint);
}
