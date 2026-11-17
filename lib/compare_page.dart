import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'main.dart' show workerUrl, appToken;

const _colorA = Color(0xFF3B82F6);
const _colorB = Color(0xFFF59E0B);

/// İki takımın olası karşılaşmasında kazanma şansı tahmini.
class ComparePage extends StatefulWidget {
  final String a;
  final String b;
  const ComparePage({super.key, required this.a, required this.b});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late Future<Map<String, dynamic>> _f = _load();

  void _retry() => setState(() => _f = _load());

  Future<Map<String, dynamic>> _load() async {
    http.Response r;
    try {
      r = await http
          .get(Uri.parse('$workerUrl/api/compare?a=${widget.a}&b=${widget.b}'),
              headers: {'X-App-Token': appToken})
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw 'İnternet bağlantısı yok. İnternetinizi kontrol edin ve tekrar deneyin.';
    }
    Map<String, dynamic> d;
    try {
      d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw 'Sunucudan geçersiz bir cevap geldi. Biraz sonra tekrar deneyin.';
    }
    if (r.statusCode != 200) throw '${d['error'] ?? 'Bilinmeyen hata'}';
    return d;
  }

  String _f1(dynamic v) => v == null ? '-' : (v is double ? v.toStringAsFixed(1) : '$v');

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ]),
          ),
        ),
      );

  Widget _bar(Map<String, dynamic> t, int pct, Color c) {
    const maxH = 200.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Köşeli sütun, yükseklik yüzdeyle orantılı
        Container(width: 72, height: (pct / 100 * maxH).clamp(2.0, maxH), color: c),
        const SizedBox(height: 6),
        Text('%$pct', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
        Text('#${t['number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 120,
          height: 36,
          child: Text('${t['nickname'] ?? ''}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _chartCard(Map<String, dynamic> a, Map<String, dynamic> b, Map<String, dynamic>? p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kazanma Şansı (Tahmin)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (p == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                  'Tahmin için iki takımın da bu sezon maç oynamış olması gerekir. '
                  'Şu an en az birinin maç verisi yok.'),
            )
          else ...[
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _bar(a, (p['a_pct'] as num).toInt(), _colorA),
                  _bar(b, (p['b_pct'] as num).toInt(), _colorB),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Dayanak: ${p['basis']}  •  Güvenilirlik: ${p['confidence']} '
                '(en az ${p['min_played']} maç verisi)',
                style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Bu sonuçlar gerçek sonuç değil, yapay zeka destekli bir tahmindir. '
                    'Gerçek maçlarda sonuç değişebilir.'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(String label, String va, String vb) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
              child: Text(va,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _colorA))),
          Expanded(flex: 2, child: Text(label, textAlign: TextAlign.center)),
          Expanded(
              child: Text(vb,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _colorB))),
        ]),
      );

  Widget _statsCard(Map<String, dynamic> a, Map<String, dynamic> b) {
    final sa = a['stats'] as Map<String, dynamic>;
    final sb = b['stats'] as Map<String, dynamic>;
    String pair(String k, Map<String, dynamic> s) => _f1(s[k]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _row('', '#${a['number']}', '#${b['number']}'),
          _row('Oynanan maç', pair('played', sa), pair('played', sb)),
          _row('Kazanma %', pair('win_rate', sa), pair('win_rate', sb)),
          _row('Ort. ittifak puanı', pair('avg_score', sa), pair('avg_score', sb)),
          _row('Ort. OPR', pair('avg_opr', sa), pair('avg_opr', sb)),
          _row('Diskalifiye', pair('dq', sa), pair('dq', sb)),
          _row('Sıfır skor', pair('zero_score', sa), pair('zero_score', sb)),
        ]),
      ),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final a = d['a'] as Map<String, dynamic>;
    final b = d['b'] as Map<String, dynamic>;
    final p = d['prediction'] as Map<String, dynamic>?;
    final ai = d['ai'] as String?;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _chartCard(a, b, p),
      const SizedBox(height: 16),
      _statsCard(a, b),
      if (ai != null) ...[
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Yapay Zeka Yorumu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(ai),
            ]),
          ),
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Takım ${widget.a} - Takım ${widget.b}')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Tahmin hazırlanıyor...'),
                ]),
              );
            }
            if (s.hasError) return _error('${s.error}');
            return _body(s.data!);
          },
        ),
      );
}
