import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../ui/home_screen.dart';

class PatternLockScreen extends StatefulWidget {
  const PatternLockScreen({super.key});
  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  final List<int> _drawn   = [];
  final List<Offset> _pts  = [];
  Offset? _cur;
  bool _err = false;
  String _message = 'Giriş için desen çizin';

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    final saved = await AppConfig.getPattern();
    final isDefault = saved.length == AppConfig.defaultPattern.length &&
        List.generate(saved.length, (i) => saved[i] == AppConfig.defaultPattern[i]).every((e) => e);
    setState(() {
      _message = isDefault ? 'Giriş için L çizin' : 'Giriş için desen çizin';
    });
  }

  List<Offset> _nodePositions(Size sz) {
    final dx = sz.width  / 4;
    final dy = sz.height / 4;
    return [
      for (var r = 1; r <= 3; r++)
        for (var c = 1; c <= 3; c++)
          Offset(c * dx, r * dy),
    ];
  }

  void _onPanStart(DragStartDetails d, List<Offset> nodes) {
    setState(() { _drawn.clear(); _pts.clear(); _err = false; });
    _checkNode(d.localPosition, nodes);
  }

  void _onPanUpdate(DragUpdateDetails d, List<Offset> nodes) {
    setState(() { _cur = d.localPosition; });
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
    final saved = await AppConfig.getPattern();
    if (_drawn.length == saved.length &&
        List.generate(_drawn.length, (i) => _drawn[i] == saved[i]).every((e) => e)) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() { _err = true; _drawn.clear(); _pts.clear(); _cur = null; });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF0D1117), const Color(0xFF010409)]
              : [const Color(0xFFf1f2f6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.lock_outline_rounded,
                          size: 64,
                          color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF1e90ff),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('DeepSafe', 
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2f3542), 
                      fontSize: 36, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5
                    )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _err ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_err ? 'Yanlış desen, tekrar deneyin' : _message,
                      style: TextStyle(
                        color: _err ? Colors.redAccent : (isDark ? Colors.white70 : Colors.blueGrey), 
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                      )),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22).withOpacity(0.5) : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
                    ),
                    child: SizedBox(
                      width: 280, height: 280,
                      child: LayoutBuilder(builder: (_, cons) {
                        final nodes = _nodePositions(cons.biggest);
                        return GestureDetector(
                          onPanStart:  (d) => _onPanStart(d, nodes),
                          onPanUpdate: (d) => _onPanUpdate(d, nodes),
                          onPanEnd:    _onPanEnd,
                          child: CustomPaint(
                            painter: PatternPainter(nodes, _pts, _cur, _err, isDark),
                            size: cons.biggest,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (isDark)
                    const Text('GÜVENLİ BÖLGE', 
                      style: TextStyle(color: Colors.white10, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<Offset> nodes, drawn;
  final Offset? cur;
  final bool err;
  final bool isDark;
  PatternPainter(this.nodes, this.drawn, this.cur, this.err, this.isDark);

  @override
  void paint(Canvas c, Size sz) {
    final accentCol = err ? Colors.redAccent : (isDark ? const Color(0xFF58A6FF) : const Color(0xFF007BFF));
    final nodeBaseCol = isDark ? const Color(0xFF30363D) : Colors.black.withOpacity(0.05);
    
    final pLine = Paint()
      ..color = accentCol
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Hafif parlama efekti

    final pNode = Paint()..color = nodeBaseCol..style = PaintingStyle.fill;
    final pNodeBorder = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pAct = Paint()
      ..color = accentCol
      ..style = PaintingStyle.fill;

    final pInner = Paint()..color = Colors.white;

    for (final n in nodes) {
      // Gölge efekti
      c.drawCircle(n, 14, Paint()..color = Colors.black.withOpacity(0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      // Ana daire
      c.drawCircle(n, 12, pNode);
      // Kenarlık
      c.drawCircle(n, 12, pNodeBorder);
      
      // Merkez noktası (Boşken bile hafif belli olsun)
      c.drawCircle(n, 3, Paint()..color = isDark ? Colors.white12 : Colors.black.withOpacity(0.05));
    }
    
    // Çizilen çizgiler
    if (drawn.length > 1) {
      for (var i = 0; i < drawn.length - 1; i++) {
        c.drawLine(drawn[i], drawn[i+1], pLine);
      }
    }
    if (drawn.isNotEmpty && cur != null) {
      c.drawLine(drawn.last, cur!, pLine);
    }

    // Aktif (seçili) noktalar
    for (final d in drawn) {
      // Dış parlama
      c.drawCircle(d, 16, Paint()..color = accentCol.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Ana nokta
      c.drawCircle(d, 14, pAct);
      // İç beyaz nokta
      c.drawCircle(d, 5, pInner);
    }
  }

  @override
  bool shouldRepaint(PatternPainter o) => true;
}
