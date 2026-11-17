import 'score_chart.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'win_loss_chart.dart';
import 'radar_chart.dart';

// deploy_api.bat'ın verdiği adresi buraya yaz (farklıysa değiştir).
const workerUrl = 'https://frc-scouting.dincermertozer.workers.dev';

// Worker'daki APP_TOKEN secret'i ile ayni olmali.
const appToken = 'GROQ_MODEL';

void main() => runApp(const ScoutApp());

class ScoutApp extends StatelessWidget {
  const ScoutApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FRC Scouting',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
        ),
        home: const MainMenu(),
      );
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final _c = TextEditingController();
  String? _err;

  void _go() {
    final n = _c.text.trim();
    if (int.tryParse(n) == null) {
      setState(() => _err = 'Geçerli bir takım numarası girin');
      return;
    }
    setState(() => _err = null);
    Navigator.push(context, MaterialPageRoute(builder: (_) => TeamPage(number: n)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Takım Numarası Girin',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _c,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _go(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'örn. 254',
                    errorText: _err,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(onPressed: _go, child: const Text('Verileri Getir')),
                ),
              ]),
            ),
          ),
        ),
      );
}

class TeamPage extends StatefulWidget {
  final String number;
  const TeamPage({super.key, required this.number});
  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _Failure {
  final IconData icon;
  final String title;
  final String message;
  const _Failure(this.icon, this.title, this.message);
}

class _TeamPageState extends State<TeamPage> {
  late Future<Map<String, dynamic>> _f = _load();

  void _retry() {
    setState(() {
      _f = _load();
    });
  }

  Future<Map<String, dynamic>> _load() async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final r = await http
            .get(Uri.parse('$workerUrl/api/team?number=${widget.number}'),
                headers: {'X-App-Token': appToken})
            .timeout(const Duration(seconds: 30));

        Map<String, dynamic> data;
        try {
          data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        } catch (_) {
          throw const _Failure(Icons.error_outline, 'Beklenmeyen cevap',
              'Sunucudan geçersiz bir cevap geldi. Biraz sonra tekrar deneyin.');
        }

        if (r.statusCode != 200) {
          final msg = '${data['error'] ?? 'Bilinmeyen hata'}';
          if (r.statusCode == 404) {
            throw _Failure(Icons.search_off, 'Sonuç bulunamadı',
                '$msg\nTakım numarasını kontrol edip tekrar deneyin.');
          }
          if (r.statusCode == 401) {
            throw const _Failure(Icons.lock_outline, 'Erişim reddedildi',
                'Uygulamanın erişim anahtarı geçersiz. Uygulamayı güncelleyin.');
          }
          throw _Failure(Icons.error_outline, 'Bir sorun oluştu', msg);
        }
        return data;
      } on _Failure {
        rethrow; // sunucunun kendi cevabı, tekrar denemeye gerek yok
      } catch (_) {
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw const _Failure(Icons.wifi_off, 'İnternet bağlantısı yok',
        'İnternetinizi kontrol edin ve tekrar deneyin.');
  }

  Widget _errorView(_Failure f) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(f.icon, size: 72, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(f.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(f.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
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
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Takım ${widget.number}')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Takım verileri getiriliyor...'),
                ]),
              );
            }
            if (s.hasError) {
              final e = s.error;
              return _errorView(e is _Failure
                  ? e
                  : const _Failure(Icons.error_outline, 'Bir sorun oluştu',
                      'Lütfen tekrar deneyin.'));
            }
            return _Dashboard(d: s.data!);
          },
        ),
      );
}
class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _Dashboard({required this.d});
  String _sub(Map<String, dynamic> m) {
    final base = '${m['score']} - ${m['opp']}${m['dq'] == true ? '  • DQ' : ''}';
    final teams = (m['opp_teams'] as List?)?.join(', ') ?? '';
    return teams.isEmpty ? base : '$base\nRakipler: $teams';
  }
  Widget _stat(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = d['team'] as Map<String, dynamic>;
    final s = d['stats'] as Map<String, dynamic>;
    final matches = (d['matches'] as List).cast<Map<String, dynamic>>();
    final ai = d['ai'] as String?;
    String f(dynamic v) => v == null ? '-' : (v is double ? v.toStringAsFixed(1) : '$v');

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('${t['nickname']} (#${t['number']})',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      Text('${t['name'] ?? ''}'),
      Text('${t['city'] ?? ''}, ${t['country'] ?? ''}  •  Kuruluş yılı: ${f(t['rookie_year'])}'),
      const SizedBox(height: 12),
      Text('Sezon: ${d['year']}', style: const TextStyle(fontSize: 16)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _stat('Oynanan maç', f(s['played'])),
        _stat('Galibiyet', f(s['wins'])),
        _stat('Mağlubiyet', f(s['losses'])),
        _stat('Beraberlik', f(s['ties'])),
        _stat('Kazanma %', f(s['win_rate'])),
        _stat('Ort. ittifak puanı', f(s['avg_score'])),
        _stat('Ort. OPR', f(s['avg_opr'])),
        _stat('Diskalifiye', f(s['dq'])),
        _stat('Sıfır skor', f(s['zero_score'])),
      ]),
      const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
        final score = ScoreChart(matches: matches);
        final wl = WinLossChart(
          wins: (s['wins'] as num).toInt(),
          losses: (s['losses'] as num).toInt(),
          ties: (s['ties'] as num).toInt(),
        );
        // Geniş ekranda yan yana, dar ekranda (telefon) alt alta
        if (c.maxWidth < 720) {
          return Column(children: [score, const SizedBox(height: 12), wl]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: score),
            const SizedBox(width: 12),
            SizedBox(width: 260, child: wl),
          ],
        );
      }),
      const SizedBox(height: 16),
      RadarChartCard(radar: d['radar'] as Map<String, dynamic>?),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Yapay Zeka Analizi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(ai ?? 'Yapay zeka analizi alınamadı. ${d['ai_error'] ?? ''}'),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      const Text('Maç Geçmişi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      for (final m in matches)
        ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: m['result'] == 'W'
                ? Colors.green
                : m['result'] == 'L'
                    ? Colors.red
                    : Colors.grey,
            child: Text('${m['result']}'),
          ),
          title: Text('${m['label']}  (${m['alliance'] == 'red' ? 'Kırmızı' : 'Mavi'})'),
           isThreeLine: m['opp_teams'] != null,
          subtitle: Text(_sub(m)),
        ),
    ]);
  }
}
