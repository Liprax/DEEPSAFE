import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../core/crypto/password_gen.dart';

class PasswordGenScreen extends StatefulWidget {
  const PasswordGenScreen({super.key});
  @override
  State<PasswordGenScreen> createState() => _PasswordGenScreenState();
}

class _PasswordGenScreenState extends State<PasswordGenScreen> {
  final _masterCtrl = TextEditingController();
  final _appCtrl    = TextEditingController();
  String _result    = '---- ---- ---- ----';

  Future<void> _generate() async {
    if (_masterCtrl.text.isEmpty || _appCtrl.text.isEmpty) return;
    final salt = await AppConfig.getSalt();
    setState(() {
      _result = PasswordGen.generate(_masterCtrl.text, _appCtrl.text, salt);
    });
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Şifre Oluşturucu')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('GELİŞMİŞ ŞİFRE ÜRETİCİ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _masterCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Master Anahtar', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appCtrl,
            decoration: const InputDecoration(
              labelText: 'Uygulama Adı (örn: Binance)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF161B22) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : Colors.transparent),
            ),
            child: Center(
              child: SelectableText(
                _result,
                style: TextStyle(
                  fontSize: 22, 
                  fontFamily: 'monospace', 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF58A6FF) : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1e90ff),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _generate, 
                child: const Text('ÜRET'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('Kopyala'),
                onPressed: () => Clipboard.setData(ClipboardData(text: _result)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
