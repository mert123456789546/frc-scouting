import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class _TeamPageState extends State<TeamPage> {
  late final Future<Map<String, dynamic>> _f = _load();

  Future<Map<String, dynamic>> _load() async {
    final r = await http
        .get(Uri.parse('$workerUrl/api/team?number=${widget.number}'),
            headers: {'X-App-Token': appToken})
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode != 200) throw data['error'] ?? 'Bilinmeyen hata';
    return data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Takım ${widget.number}')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) {
              return Center(child: Text('Hata: ${s.error}', style: const TextStyle(fontSize: 18)));
            }
            return _Dashboard(d: s.data!);
          },
        ),
      );
}

class _Dashboard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _Dashboard({required this.d});

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
          subtitle: Text('${m['score']} - ${m['opp']}${m['dq'] == true ? '  • DQ' : ''}'),
        ),
    ]);
  }
}
