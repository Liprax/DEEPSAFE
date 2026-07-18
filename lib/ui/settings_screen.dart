import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/config/app_config.dart';
import '../modules/lock/pattern_lock_screen.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.pattern),
          title: const Text('Deseni Değiştir'),
          subtitle: const Text('Yeni giriş deseni çiz'),
          onTap: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const _PatternSetScreen())),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.view_list),
          title: const Text('Dosya Görünümü'),
          subtitle: const Text('Liste, küçük/küçük ızgara'),
          onTap: () => _changeViewMode(ctx),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.sort),
          title: const Text('Sıralama'),
          subtitle: const Text('İsim, tarih, boyut'),
          onTap: () => _changeSort(ctx),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Tuzu Değiştir'),
          subtitle: const Text('Şifreleme anahtarını güncelle'),
          onTap: () => _changeSalt(ctx),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.swap_horizontal_circle),
          title: const Text('Aktarım Klasörü'),
          subtitle: const Text('Dosya aktarımı için kullanılan dizin'),
          onTap: () => _changeTransferPath(ctx),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: const Text('Başlangıç Klasörü'),
          subtitle: const Text('Dosya yöneticisi açılış dizini'),
          onTap: () => _changeStartPath(ctx),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Tema'),
          subtitle: const Text('Aydınlık, karanlık veya sistem'),
          onTap: () => _changeTheme(ctx),
        ),
      ],
    ),
  );

  Future<void> _changeTransferPath(BuildContext ctx) async {
    final current = await AppConfig.getTransferPath();
    final ctrl = TextEditingController(text: current);
    
    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Aktarım Klasörü'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Klasör Yolu',
                hintText: 'Yolu yazın veya butona basın',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('KLASÖR SEÇ'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String? selected = await FilePicker.platform.getDirectoryPath();
                if (selected != null) ctrl.text = selected;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await AppConfig.saveTransferPath(null);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Varsayılan dizine sıfırlandı')));
            },
            child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                if (await Directory(ctrl.text).exists()) {
                  await AppConfig.saveTransferPath(ctrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Aktarım klasörü güncellendi ✓')));
                  }
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Geçersiz klasör yolu!')));
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeTheme(BuildContext ctx) async {
    final current = await AppConfig.getThemeMode();
    String selected = current;

    await showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tema Seçimi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Aydınlık'),
                value: 'light',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
              ),
              RadioListTile<String>(
                title: const Text('Karanlık'),
                value: 'dark',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
              ),
              RadioListTile<String>(
                title: const Text('Sistem Varsayılanı'),
                value: 'system',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                await AppConfig.saveThemeMode(selected);
                if (ctx.mounted) {
                  DeepSafeApp.of(ctx).changeTheme(selected);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Tema güncellendi ✓')));
                }
              },
              child: const Text('Onayla'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStartPath(BuildContext ctx) async {
    final current = await AppConfig.getStartPath();
    final ctrl = TextEditingController(text: current);
    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Başlangıç Klasörü'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Tam Klasör Yolu',
                hintText: 'C:\\Users\\...',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('KLASÖR SEÇ'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String? selected = await FilePicker.platform.getDirectoryPath();
                if (selected != null) ctrl.text = selected;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await AppConfig.saveStartPath(null as dynamic); // Clear
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Varsayılan dizine sıfırlandı')));
            },
            child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                if (await Directory(ctrl.text).exists()) {
                  await AppConfig.saveStartPath(ctrl.text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Başlangıç klasörü güncellendi ✓')));
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Geçersiz klasör yolu!')));
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSort(BuildContext ctx) async {
    final currentMode = await AppConfig.getSortMode();
    final currentOrder = await AppConfig.getSortOrder();
    String selectedMode = currentMode;
    String selectedOrder = currentOrder;

    await showDialog<void>(
      context: ctx,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sıralama'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sıralama Türü:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('İsme Göre'),
                    value: 'name',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Tarihe Göre'),
                    value: 'date',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Boyuta Göre'),
                    value: 'size',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Sıra:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Artan (A-Z, Eski-Yeni)'),
                    value: 'asc',
                    groupValue: selectedOrder,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedOrder = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Azalan (Z-A, Yeni-Eski)'),
                    value: 'desc',
                    groupValue: selectedOrder,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedOrder = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AppConfig.saveSortMode(selectedMode);
                    await AppConfig.saveSortOrder(selectedOrder);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Sıralama güncellendi ✓')),
                    );
                  },
                  child: const Text('Onayla'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeSalt(BuildContext ctx) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Tuz Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mevcut tuz')),
            const SizedBox(height: 16),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni tuz')),
            const SizedBox(height: 16),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni tuz (tekrar)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final currentSalt = await AppConfig.getSalt();
              if (currentCtrl.text != currentSalt) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Mevcut tuz yanlış!')));
                return;
              }
              if (newCtrl.text.isEmpty || newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Yeni tuz eşleşmiyor veya boş!')));
                return;
              }
              await AppConfig.saveSalt(newCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Tuz güncellendi ✓')));
            },
            child: const Text('Kaydet')),
        ],
      ),
    );
  }

  Future<void> _changeViewMode(BuildContext ctx) async {
    final currentMode = await AppConfig.getViewMode();
    String selectedMode = currentMode;

    await showDialog<void>(
      context: ctx,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Dosya Görünümü'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Liste Görünümü'),
                    value: 'list',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Küçük Simgeler'),
                    value: 'grid_small',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Büyük Simgeler'),
                    value: 'grid_large',
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMode = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AppConfig.saveViewMode(selectedMode);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Görünüm güncellendi ✓')),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PatternSetScreen extends StatefulWidget {
  const _PatternSetScreen();
  @override
  State<_PatternSetScreen> createState() => _PatternSetScreenState();
}

class _PatternSetScreenState extends State<_PatternSetScreen> {
  final List<int>    _drawn = [];
  final List<Offset> _pts   = [];
  Offset? _cur;
  bool _confirm = false;
  List<int>? _firstPattern;

  List<Offset> _nodePositions(Size sz) {
    final dx = sz.width  / 4;
    final dy = sz.height / 4;
    return [
      for (var r = 1; r <= 3; r++)
        for (var c = 1; c <= 3; c++)
          Offset(c * dx, r * dy),
    ];
  }

  Future<void> _onEnd(DragEndDetails _) async {
    if (_drawn.length < 4) {
      setState(() { _drawn.clear(); _pts.clear(); _cur = null; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 4 nokta seçin!')));
      return;
    }
    if (!_confirm) {
      setState(() { _firstPattern = List.from(_drawn); _confirm = true; _drawn.clear(); _pts.clear(); _cur = null; });
    } else {
      if (_firstPattern != null &&
          _drawn.length == _firstPattern!.length &&
          List.generate(_drawn.length, (i) => _drawn[i] == _firstPattern![i]).every((e) => e)) {
        await AppConfig.savePattern(_drawn);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desen kaydedildi ✓')));
      } else {
        setState(() { _confirm = false; _firstPattern = null; _drawn.clear(); _pts.clear(); _cur = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desenler eşleşmiyor, tekrar deneyin!')));
      }
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFF1e272e),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1e272e),
      foregroundColor: Colors.white,
      title: const Text('Yeni Desen Çiz')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _confirm ? 'Deseni tekrar çizerek onayla' : 'Yeni desen çizin',
            style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          SizedBox(
            width: 280, height: 280,
            child: LayoutBuilder(builder: (_, cons) {
              final nodes = _nodePositions(cons.biggest);
              return GestureDetector(
                onPanStart: (_) => setState(() { _drawn.clear(); _pts.clear(); }),
                onPanUpdate: (d) {
                  setState(() => _cur = d.localPosition);
                  for (var i = 0; i < nodes.length; i++) {
                    if ((d.localPosition - nodes[i]).distance < 28 &&
                        !_drawn.contains(i)) {
                      setState(() { _drawn.add(i); _pts.add(nodes[i]); });
                    }
                  }
                },
                onPanEnd: _onEnd,
                child: CustomPaint(
                  painter: PatternPainter(nodes, _pts, _cur, false),
                  size: cons.biggest,
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}

class PatternPainter extends CustomPainter {
  final List<Offset> nodes;
  final List<Offset> pts;
  final Offset? cur;
  final bool initialSetup;

  PatternPainter(this.nodes, this.pts, this.cur, this.initialSetup);

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.fill;
    final p2 = Paint()
      ..color = const Color(0xFF1e90ff)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final p3 = Paint()
      ..color = const Color(0xFF1e90ff)
      ..style = PaintingStyle.fill;

    for (final n in nodes) {
      canvas.drawCircle(n, 8, p1);
    }

    if (pts.isNotEmpty) {
      for (var i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], p2);
      }
      if (cur != null) {
        canvas.drawLine(pts.last, cur!, p2);
      }
      for (final pt in pts) {
        canvas.drawCircle(pt, 12, p3);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
