import 'package:flutter/material.dart';
import '../modules/file_manager/file_manager_screen.dart';
import '../modules/password_gen/password_gen_screen.dart';
import '../modules/file_transfer/file_transfer_screen.dart';
import '../ui/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF010409), const Color(0xFF0D1117)]
              : [const Color(0xFFf1f2f6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DeepSafe', 
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : const Color(0xFF2f3542),
                        letterSpacing: 1.2
                      )),
                    Text('Güvenli Veri Yönetimi', 
                      style: TextStyle(
                        fontSize: 14, 
                        color: isDark ? const Color(0xFF58A6FF) : Colors.blueGrey,
                        fontWeight: FontWeight.w500
                      )),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  crossAxisCount: MediaQuery.of(ctx).size.width > 600 ? 4 : 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _card(ctx, 'DOSYA GEZGİNİ', Icons.folder_copy_rounded, const Color(0xFF1e90ff), const FileManagerScreen()),
                    _card(ctx, 'GÜVENLİ AKTARIM', Icons.swap_horizontal_circle_rounded, const Color(0xFF27ae60), const FileTransferScreen()),
                    _card(ctx, 'ŞİFRE ÜRETİCİ', Icons.key_rounded, const Color(0xFF8e44ad), const PasswordGenScreen()),
                    _card(ctx, 'AYARLAR', Icons.settings_suggest_rounded, isDark ? const Color(0xFF30363D) : const Color(0xFFdcdde1), const SettingsScreen(), 
                      iconColor: isDark ? Colors.white : Colors.black87),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text('DeepSafe v1.0.2', 
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext ctx, String lbl, IconData icon, Color color, Widget dest, {Color? iconColor}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => dest)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor ?? color),
            ),
            const SizedBox(height: 16),
            Text(lbl, 
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white70 : Colors.black87,
                letterSpacing: 0.5
              )),
          ],
        ),
      ),
    );
  }
}
