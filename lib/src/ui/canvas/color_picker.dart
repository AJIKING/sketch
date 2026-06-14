import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../theme/atelier_theme.dart';

/// SV(彩度×明度)矩形 + Hue 帯の HSV ピッカー(プロトタイプ準拠)。
///
/// [controller] の現在色(HSV)を読み書きする。ドラッグ確定時に最近色へ積む。
class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final (h, s, v) = controller.hsv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SvSquare(
          hue: h,
          saturation: s,
          value: v,
          onChange: (ns, nv) => controller.setHsv(h, ns, nv),
          onEnd: controller.addRecent,
        ),
        const SizedBox(height: 12),
        _HueBar(
          hue: h,
          onChange: (nh) => controller.setHsv(nh, s, v),
          onEnd: controller.addRecent,
        ),
      ],
    );
  }
}

class _SvSquare extends StatelessWidget {
  const _SvSquare({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChange,
    required this.onEnd,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double s, double v) onChange;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 170.0;
        void handle(Offset local) {
          final s = (local.dx / width).clamp(0.0, 1.0);
          final v = (1 - local.dy / height).clamp(0.0, 1.0);
          onChange(s, v);
        }

        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onPanEnd: (_) => onEnd(),
          child: Semantics(
            label: '彩度と明度',
            child: SizedBox(
              width: width,
              height: height,
              child: CustomPaint(
                painter: _SvPainter(
                  hue: hue,
                  saturation: saturation,
                  value: value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SvPainter extends CustomPainter {
  _SvPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(AtelierTokens.rMd),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final hueColor = HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();

    // 現在位置のインジケータ。
    final pos = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(pos, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      pos,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant _SvPainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}

class _HueBar extends StatelessWidget {
  const _HueBar({
    required this.hue,
    required this.onChange,
    required this.onEnd,
  });

  final double hue;
  final void Function(double hue) onChange;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void handle(Offset local) =>
            onChange((local.dx / width).clamp(0.0, 1.0) * 360);

        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onPanEnd: (_) => onEnd(),
          child: Semantics(
            label: '色相',
            child: SizedBox(
              width: width,
              height: 24,
              child: CustomPaint(painter: _HuePainter(hue: hue)),
            ),
          ),
        );
      },
    );
  }
}

class _HuePainter extends CustomPainter {
  _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(AtelierTokens.rSm),
    );
    final colors = [
      for (var i = 0; i <= 6; i++)
        HSVColor.fromAHSV(1, i * 60.0 % 360, 1, 1).toColor(),
    ];
    canvas.drawRRect(
      rrect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
    final x = (hue % 360) / 360 * size.width;
    canvas.drawCircle(
      Offset(x, size.height / 2),
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter old) => old.hue != hue;
}
