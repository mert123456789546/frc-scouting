import 'package:flutter/material.dart';

/// Maç başına kazanılan puanları gösteren sütun grafiği.
/// Yeşil = galibiyet, kırmızı = mağlubiyet, gri = beraberlik.
class ScoreChart extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  const ScoreChart({super.key, required this.matches});

  @override
  State<ScoreChart> createState() => _ScoreChartState();
}

class _ScoreChartState extends State<ScoreChart> {
  final _scroll = ScrollController();

  static const _win = Color(0xFF2E9E4F);
  static const _loss = Color(0xFFD64545);
  static const _tie = Color(0xFF8A8F98);
  static const _chartH = 230.0;
  static const _labelH = 18.0; // sütunun üstündeki puan yazısına ayrılan yer
  static const _barW = 28.0;
  static const _gap = 6.0;

  Color _color(dynamic r) => r == 'W' ? _win : (r == 'L' ? _loss : _tie);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _legend(Color c, String text) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, color: c),
          const SizedBox(width: 6),
          Text(text),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final matches = widget.matches;
    if (matches.isEmpty) return const SizedBox.shrink();

    var top = 0.0;
    for (final m in matches) {
      final s = (m['score'] as num).toDouble();
      if (s > top) top = s;
    }
    if (top <= 0) top = 1;
    final hasTie = matches.any((m) => m['result'] == 'T');
    const barArea = _chartH - _labelH;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Maç Başına Puan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            _legend(_win, 'Galibiyet'),
            _legend(_loss, 'Mağlubiyet'),
            if (hasTie) _legend(_tie, 'Beraberlik'),
          ]),
          const SizedBox(height: 12),
          Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in matches)
                    Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      message: '${m['label']}\n${m['score']} - ${m['opp']}',
                      child: Padding(
                        padding: const EdgeInsets.only(right: _gap),
                        child: SizedBox(
                          width: _barW,
                          height: _chartH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: _labelH,
                                child: Center(
                                  child: Text(
                                    '${m['score']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _color(m['result']),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: _barW,
                                height: ((m['score'] as num).toDouble() / top * barArea)
                                    .clamp(2.0, barArea),
                                decoration: BoxDecoration(
                                  color: _color(m['result']),
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${matches.length} maç  •  Sütuna gelin veya dokunun: maç adı ve skor görünür',
              style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}