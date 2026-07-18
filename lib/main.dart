import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/config/app_config.dart';
import 'modules/lock/pattern_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final pattern = await AppConfig.getPattern();
  final theme = await AppConfig.getThemeMode();
  
  final isDefault = pattern.length == AppConfig.defaultPattern.length &&
      List.generate(pattern.length, (i) => pattern[i] == AppConfig.defaultPattern[i]).every((e) => e);
  
  runApp(DeepSafeApp(initialSetup: isDefault, initialTheme: theme));
}

class DeepSafeApp extends StatefulWidget {
  final bool initialSetup;
  final String initialTheme;
  const DeepSafeApp({super.key, required this.initialSetup, required this.initialTheme});

  static _DeepSafeAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_DeepSafeAppState>()!;

  @override
  State<DeepSafeApp> createState() => _DeepSafeAppState();
}

class _DeepSafeAppState extends State<DeepSafeApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _parseThemeMode(widget.initialTheme);
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default: return ThemeMode.system;
    }
  }

  void changeTheme(String mode) {
    setState(() {
      _themeMode = _parseThemeMode(mode);
    });
  }

  @override
  Widget build(BuildContext ctx) => MaterialApp(
    title: 'DeepSafe',
    debugShowCheckedModeBanner: false,
    themeMode: _themeMode,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1e90ff), brightness: Brightness.light),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007BFF),    // Canlı Mavi
        onPrimary: Colors.white,
        secondary: Color(0xFF0056b3),  // Koyu Mavi
        surface: Color(0xFF0D1117),    // Neredeyse Siyah (GitHub Karanlık gibi)
        background: Color(0xFF010409), // Tamamen Siyah-Mavi tonu
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFF010409),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1117),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF58A6FF),
        textColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF0D1117),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    home: widget.initialSetup ? const _InitialPatternSetupScreen() : const PatternLockScreen(),
  );
}

class _InitialPatternSetupScreen extends StatefulWidget {
  const _InitialPatternSetupScreen();
  @override
  State<_InitialPatternSetupScreen> createState() => _InitialPatternSetupScreenState();
}

class _InitialPatternSetupScreenState extends State<_InitialPatternSetupScreen> {
  final List<int> _drawn = [];
  final List<Offset> _pts = [];
  Offset? _cur;
  bool _confirm = false;
  List<int>? _firstPattern;

  List<Offset> _nodePositions(Size sz) {
    final dx = sz.width / 4;
    final dy = sz.height / 4;
    return [
      for (var r = 1; r <= 3; r++)
        for (var c = 1; c <= 3; c++)
          Offset(c * dx, r * dy),
    ];
  }

  void _onPanStart(DragStartDetails d, List<Offset> nodes) {
    setState(() { _drawn.clear(); _pts.clear(); });
    _checkNode(d.localPosition, nodes);
  }

  void _onPanUpdate(DragUpdateDetails d, List<Offset> nodes) {
    setState(() => _cur = d.localPosition);
    _checkNode(d.localPosition, nodes);
  }

  void _checkNode(Offset pos, List<Offset> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      if ((pos - nodes[i]).distance < 28 && !_drawn.contains(i)) {
        setState(() { _drawn.add(i); _pts.add(nodes[i]); });
      }
    }
  }

  Future<void> _onPanEnd(DragEndDetails _) async {
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
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PatternLockScreen()));
      } else {
        setState(() { _confirm = false; _firstPattern = null; _drawn.clear(); _pts.clear(); _cur = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desenler eşleşmiyor, tekrar deneyin!')));
      }
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: const Color(0xFF010409),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D1117),
      foregroundColor: Colors.white,
      title: const Text('İlk Kurulum - Desen Oluştur')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('DeepSafe', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_confirm ? 'Deseni tekrar çizerek onayla' : 'Güvenlik için desen oluşturun',
            style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 16)),
          const SizedBox(height: 48),
          SizedBox(
            width: 300, height: 300,
            child: LayoutBuilder(builder: (_, cons) {
              final nodes = _nodePositions(cons.biggest);
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, nodes),
                onPanUpdate: (d) => _onPanUpdate(d, nodes),
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: PatternPainter(nodes, _pts, _cur, false, Theme.of(ctx).brightness == Brightness.dark),
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
