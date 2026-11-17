import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Takım profili radar grafiği (0–10 ölçeği, 6 eksen).
class RadarChartCard extends StatelessWidget {
  final Map<String, dynamic>? radar;
  const RadarChartCard({super.key, this.radar});

  static const _axes = <List<String>>[
    ['yazilim', 'Yazılım'],
    ['mekanik', 'Mekanik'],
    ['elektronik', 'Elektronik'],
    ['strateji', 'Strateji'],
    ['hiz', 'Hız'],
    ['saglamlik', 'Sağlamlık'],
  ];

  double? _val(String key) {
    final v = radar?[key];
    if (v is! num) return null;
    return v.toDouble().clamp(0.0, 10.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [for (final a in _axes) a[1]];
    final values = [for (final a in _axes) _val(a[0])];
    final hasAny = values.any((v) => v != null);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Takım Profili',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              'Hız: OPR\'nin etkinlikteki diğer takımlara göre sırası. '
              'Sağlamlık: diskalifiye ve sıfır skorlu maçların azlığı. '
              'Yazılım, mekanik, elektronik ve strateji yapay zekanın kaba tahminidir. '
              'Hiçbiri doğrudan arıza ölçümü değildir (0–10).',
              style: TextStyle(fontSize: 12)),
          SizedBox(
            height: 360,
            child: CustomPaint(
              size: Size.infinite,
              painter: _RadarPainter(labels, values, scheme.primary, scheme.onSurface),
            ),
          ),
          if (!hasAny)
            const Text('Bu takım için henüz yeterli maç verisi yok, radar boş.',
                style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double?> values;
  final Color accent;
  final Color textColor;
  _RadarPainter(this.labels, this.values, this.accent, this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(40.0, math.min(size.width / 2 - 70, size.height / 2 - 36));

    Offset point(int i, double f) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return center + Offset(math.cos(a), math.sin(a)) * (radius * f);
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = textColor.withValues(alpha: 0.2);

    // Halkalar (2, 4, 6, 8, 10)
    for (var r = 1; r <= 5; r++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = point(i, r / 5);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, point(i, 1), grid);
    }

    // Veri çokgeni (veri yoksa merkeze iner)
    final data = Path();
    for (var i = 0; i < n; i++) {
      final p = point(i, (values[i] ?? 0) / 10);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    if (values.any((v) => v != null)) {
      canvas.drawPath(data, Paint()..color = accent.withValues(alpha: 0.3));
      canvas.drawPath(
          data,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = accent);
    }

    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v != null) canvas.drawCircle(point(i, v / 10), 4, Paint()..color = accent);

      // Etiket
      final text = v == null
          ? '${labels[i]}\n(veri yok)'
          : '${labels[i]}\n${v.toStringAsFixed(1)}';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              color: v == null ? textColor.withValues(alpha: 0.5) : textColor, fontSize: 12),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final dir = (point(i, 1) - center) / radius;
      final c = point(i, 1) + dir * 28;
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
