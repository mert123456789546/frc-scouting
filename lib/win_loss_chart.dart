import 'package:flutter/material.dart';

/// Kazanma / kaybetme (ve varsa beraberlik) yüzdelerini gösteren köşeli sütun grafiği.
class WinLossChart extends StatelessWidget {
  final int wins;
  final int losses;
  final int ties;
  const WinLossChart({
    super.key,
    required this.wins,
    required this.losses,
    required this.ties,
  });

  static const _win = Color(0xFF2E9E4F);
  static const _loss = Color(0xFFD64545);
  static const _tie = Color(0xFF8A8F98);
  static const _chartH = 230.0;
  static const _labelH = 24.0;
  static const _barW = 48.0;

  String _pct(double v) =>
      v == v.roundToDouble() ? '%${v.toStringAsFixed(0)}' : '%${v.toStringAsFixed(1)}';

  Widget _bar(double pct, Color c) {
    const maxH = _chartH - _labelH;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Köşeli sütun: borderRadius yok. 100% = tam yükseklik, oranlar birebir korunur.
        Container(width: _barW, height: (pct / 100 * maxH).clamp(2.0, maxH), color: c),
        SizedBox(
          height: _labelH,
          child: Center(
            child: Text(_pct(pct),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c)),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final played = wins + losses + ties;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kazanma / Kaybetme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const SizedBox(
            height: 20,
            child: Align(alignment: Alignment.centerLeft, child: Text('Oynanan maçların yüzdesi')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _chartH,
            child: played == 0
                ? const Center(child: Text('Veri yok'))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar(wins / played * 100, _win),
                      _bar(losses / played * 100, _loss),
                      if (ties > 0) _bar(ties / played * 100, _tie),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text('$played maç', style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}