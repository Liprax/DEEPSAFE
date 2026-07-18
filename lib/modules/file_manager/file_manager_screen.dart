import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../core/config/app_config.dart';
import '../../core/crypto/xor_cipher.dart';
import '../../core/database/alias_service.dart';
import '../notes/notes_screen.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});
  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late Directory _cur;
  List<FileSystemEntity> _items = [];
  Map<String, Map<String, String>> _aliasData = {};
  final Set<int> _selected = {};
  final TextEditingController _pathCtrl = TextEditingController();
  bool _loading = true;
  String _viewMode = 'list';
  String _sortMode = 'name';
  String _sortOrder = 'asc';

  // Kopyala/Kes/Yapıştır için pano yönetimi
  List<FileSystemEntity> _clipboard = [];
  bool _isCutMode = false;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    final savedPath = await AppConfig.getStartPath();
    Directory startDir;
    
    if (savedPath != null && await Directory(savedPath).exists()) {
      startDir = Directory(savedPath);
    } else {
      startDir = Platform.isAndroid || Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : Directory(Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.');
    }

    final viewMode = await AppConfig.getViewMode();
    final sortMode = await AppConfig.getSortMode();
    final sortOrder = await AppConfig.getSortOrder();
    setState(() { 
      _cur = startDir; 
      _pathCtrl.text = startDir.path;
      _loading = false; 
      _viewMode = viewMode;
      _sortMode = sortMode;
      _sortOrder = sortOrder;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final items = _cur.listSync();
      final aliasData = await AliasService.getAllData();
      _pathCtrl.text = _cur.path;
      
      // Sıralama mantığı
      items.sort((a, b) {
        // Önce klasörleri ayır
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;

        int compare = 0;
        if (_sortMode == 'name') {
          final nameA = (aliasData[a.path]?['alias']?.isNotEmpty == true ? aliasData[a.path]!['alias']! : a.path.split(Platform.pathSeparator).last).toLowerCase();
          final nameB = (aliasData[b.path]?['alias']?.isNotEmpty == true ? aliasData[b.path]!['alias']! : b.path.split(Platform.pathSeparator).last).toLowerCase();
          compare = nameA.compareTo(nameB);
        } else if (_sortMode == 'date') {
          final statA = a.statSync();
          final statB = b.statSync();
          compare = statA.modified.compareTo(statB.modified);
        } else if (_sortMode == 'size') {
          int sizeA = _isDir(a) ? 0 : (a as File).lengthSync();
          int sizeB = _isDir(b) ? 0 : (b as File).lengthSync();
          compare = sizeA.compareTo(sizeB);
        }

        return _sortOrder == 'asc' ? compare : -compare;
      });

      setState(() { 
        _items = items; 
        _aliasData = aliasData;
        _selected.clear(); 
      });
    } catch (e) {
      _snack('Erişim hatası: $e');
    }
  }

  String _name(FileSystemEntity e) {
    if (_aliasData.containsKey(e.path) && _aliasData[e.path]!['alias']!.isNotEmpty) {
      return _aliasData[e.path]!['alias']!;
    }
    return _realName(e);
  }

  String _realName(FileSystemEntity e) => e.path.split(Platform.pathSeparator).last;

  IconData _icon(FileSystemEntity e) {
    final type = _aliasData[e.path]?['icon'];
    if (type == 'book') return Icons.menu_book;
    if (type == 'disk') return Icons.save;
    if (type == 'game') return Icons.videogame_asset;
    if (type == 'note') return Icons.note;
    if (type == 'cd') return Icons.album;
    return _isDir(e) ? Icons.folder : Icons.insert_drive_file;
  }

  bool   _isDir(FileSystemEntity e) => e is Directory;
  String _size(FileSystemEntity e) {
    if (_isDir(e)) return '-';
    try { return '${(e as File).lengthSync() ~/ 1024} KB'; } catch (_) { return '?'; }
  }

  Future<void> _process(bool encrypt) async {
    if (_selected.isEmpty) { _snack('Önce dosya seçin (uzun basın)'); return; }
    final salt = await AppConfig.getSalt();
    var ok = 0;
    for (final i in _selected) {
      final e = _items[i];
      if (e is File) {
        try {
          final data = await e.readAsBytes();
          final result = encrypt
              ? await AesGcmCipher.encrypt(data, salt)
              : await AesGcmCipher.decrypt(data, salt);
          final newPath = encrypt
              ? '${e.path}.deep'
              : e.path.endsWith('.deep')
                  ? e.path.substring(0, e.path.length - 5)
                  : '${e.path}.unlocked';
          await File(newPath).writeAsBytes(result);
          ok++;
        } catch (_) {}
      }
    }
    _load();
    _snack('$ok dosya işlendi ✓');
  }

  void _snack(String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yeni Klasör'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Klasör adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                try {
                  await Directory('${_cur.path}${Platform.pathSeparator}${ctrl.text}').create();
                  _load();
                  Navigator.pop(context);
                  _snack('Klasör oluşturuldu ✓');
                } catch (e) {
                  _snack('Hata: $e');
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameItem(FileSystemEntity item) async {
    final oldName = _realName(item);
    final ctrl = TextEditingController(text: oldName);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adlandır'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Yeni ad'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty && ctrl.text != oldName) {
                try {
                  final newPath = '${_cur.path}${Platform.pathSeparator}${ctrl.text}';
                  final oldPath = item.path;
                  if (item is File) {
                    await item.rename(newPath);
                  } else if (item is Directory) {
                    await (item as Directory).rename(newPath);
                  }
                  
                  // Takma adı yeni yola taşı
                  if (_aliasData.containsKey(oldPath)) {
                    final data = _aliasData[oldPath]!;
                    await AliasService.removeAlias(oldPath);
                    await AliasService.setAlias(newPath, data['alias']!);
                    await AliasService.setIcon(newPath, data['icon']!);
                  }

                  _load();
                  Navigator.pop(context);
                  _snack('Adlandırıldı ✓');
                } catch (e) {
                  _snack('Hata: $e');
                }
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNoteHere() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Not Oluştur'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Not adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                try {
                  final notePath = '${_cur.path}${Platform.pathSeparator}${ctrl.text}.txt';
                  await File(notePath).writeAsString('Not oluşturuldu: ${DateTime.now()}\n');
                  _load();
                  Navigator.pop(context);
                  _snack('Not oluşturuldu ✓');
                } catch (e) {
                  _snack('Hata: $e');
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(TapDownDetails details) async {
    const choices = ['Yeni Klasör', 'Not Oluştur'];
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: choices
          .map((choice) => PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              ))
          .toList(),
    );

    if (selected == 'Yeni Klasör') {
      _createFolder();
    } else if (selected == 'Not Oluştur') {
      _createNoteHere();
    }
  }

  Future<void> _setAlias(FileSystemEntity item) async {
    final currentAlias = _aliasData[item.path]?['alias'] ?? '';
    final ctrl = TextEditingController(text: currentAlias);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Takma Ad Ver'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Uygulama içinde görünecek ad'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          if (currentAlias.isNotEmpty)
            TextButton(
              onPressed: () async {
                await AliasService.removeAlias(item.path);
                _load();
                Navigator.pop(context);
                _snack('Takma ad kaldırıldı ✓');
              },
              child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await AliasService.setAlias(item.path, ctrl.text);
                _load();
                Navigator.pop(context);
                _snack('Takma ad atandı ✓');
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  Future<void> _setIcon(FileSystemEntity item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Görsel Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconOption(item, 'Varsayılan', null),
            _iconOption(item, 'Kitap', 'book'),
            _iconOption(item, 'Disk', 'disk'),
            _iconOption(item, 'Oyun Kartuşu', 'game'),
            _iconOption(item, 'Klasik Not', 'note'),
            _iconOption(item, 'CD', 'cd'),
          ],
        ),
      ),
    );
  }

  Widget _iconOption(FileSystemEntity item, String label, String? type) {
    IconData iconData;
    if (type == 'book') iconData = Icons.menu_book;
    else if (type == 'disk') iconData = Icons.save;
    else if (type == 'game') iconData = Icons.videogame_asset;
    else if (type == 'note') iconData = Icons.note;
    else if (type == 'cd') iconData = Icons.album;
    else iconData = _isDir(item) ? Icons.folder : Icons.insert_drive_file;

    return ListTile(
      leading: Icon(iconData, color: _isDir(item) ? Colors.amber : Colors.blueGrey),
      title: Text(label),
      onTap: () async {
        await AliasService.setIcon(item.path, type ?? '');
        await _load();
        if (context.mounted) Navigator.pop(context);
        _snack('Görsel güncellendi ✓');
      },
    );
  }

  void _showItemMenuAt(RelativeRect position, FileSystemEntity item) async {
    const choices = ['Adlandır', 'Takma Ad Ver', 'Görsel Değiştir', 'Sil'];
    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: choices
          .map((choice) => PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              ))
          .toList(),
    );

    if (selected == 'Adlandır') {
      _renameItem(item);
    } else if (selected == 'Takma Ad Ver') {
      _setAlias(item);
    } else if (selected == 'Görsel Değiştir') {
      _setIcon(item);
    } else if (selected == 'Sil') {
      try {
        if (item is File) {
          await item.delete();
        } else if (item is Directory) {
          await (item as Directory).delete(recursive: true);
        }
        await AliasService.removeAlias(item.path);
        _load();
        _snack('Silindi ✓');
      } catch (e) {
        _snack('Hata: $e');
      }
    }
  }

  void _showItemContextMenu(TapDownDetails details, FileSystemEntity item) async {
    final position = RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    );
    _showItemMenuAt(position, item);
  }

  void _copySelected(bool cut) {
    setState(() {
      _clipboard = _selected.map((i) => _items[i]).toList();
      _isCutMode = cut;
      _selected.clear();
    });
    _snack(_isCutMode ? 'Öğeler kesildi' : 'Öğeler kopyalandı');
  }

  Future<void> _paste() async {
    if (_clipboard.isEmpty) return;
    int ok = 0;
    for (var item in _clipboard) {
      try {
        final name = p.basename(item.path);
        final newPath = p.join(_cur.path, name);
        if (item is File) {
          if (_isCutMode) {
            await item.rename(newPath);
          } else {
            await item.copy(newPath);
          }
        } else if (item is Directory) {
          // Klasör kopyalama/taşıma (basitleştirilmiş)
          if (_isCutMode) {
            await item.rename(newPath);
          } else {
            // Klasör kopyalama için özel mantık gerekir, Flutter'da basit bir copy() yok.
            // Şimdilik sadece dosyaları destekleyelim veya basitleştirelim.
          }
        }
        ok++;
      } catch (e) {
        debugPrint('Yapıştırma hatası: $e');
      }
    }
    if (_isCutMode) _clipboard.clear();
    _load();
    _snack('$ok öğe yapıştırıldı ✓');
  }

  Widget _buildFileList() {
    if (_viewMode == 'list') {
      return GestureDetector(
        onSecondaryTapDown: _showContextMenu,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final e = _items[i];
            final sel = _selected.contains(i);
            return GestureDetector(
              onSecondaryTapDown: (details) => _showItemContextMenu(details, e),
              child: ListTile(
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Icon(_icon(e), size: 40, color: _isDir(e) ? Colors.amber : Colors.blueGrey),
                    if (sel) const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                  ],
                ),
                title: Text(_name(e), style: const TextStyle(fontSize: 14)),
                subtitle: Text(_size(e), style: const TextStyle(fontSize: 12)),
                tileColor: sel ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  if (_selected.isNotEmpty) {
                    setState(() { sel ? _selected.remove(i) : _selected.add(i); });
                  } else if (_isDir(e)) {
                    setState(() { _cur = e as Directory; });
                    _load();
                  } else {
                    final path = e.path.toLowerCase();
                    if (path.endsWith('.txt') || path.endsWith('.md')) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(file: e as File))).then((_) => _load());
                    }
                  }
                },
                onLongPress: () {
                  setState(() { sel ? _selected.remove(i) : _selected.add(i); });
                },
                trailing: sel
                    ? Builder(
                        builder: (btnCtx) => IconButton(
                          icon: const Icon(Icons.more_vert, size: 32), // BÜYÜTÜLDÜ
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final RenderBox box = btnCtx.findRenderObject() as RenderBox;
                            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                            final RelativeRect position = RelativeRect.fromRect(
                              Rect.fromPoints(
                                box.localToGlobal(Offset.zero, ancestor: overlay),
                                box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
                              ),
                              Offset.zero & overlay.size,
                            );
                            _showItemMenuAt(position, e);
                          },
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      );
    } else {
      final crossAxisCount = _viewMode == 'grid_small' ? 4 : 3;
      final iconSize = _viewMode == 'grid_small' ? 128.0 : 192.0;
      return GestureDetector(
        onSecondaryTapDown: _showContextMenu,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final e = _items[i];
            final sel = _selected.contains(i);
            return GestureDetector(
              onSecondaryTapDown: (details) => _showItemContextMenu(details, e),
              onTap: () {
                if (_selected.isNotEmpty) {
                  setState(() { sel ? _selected.remove(i) : _selected.add(i); });
                } else if (_isDir(e)) {
                  setState(() { _cur = e as Directory; });
                  _load();
                }
              },
              onLongPress: () {
                setState(() { sel ? _selected.remove(i) : _selected.add(i); });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: sel ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: sel ? Border.all(color: Colors.blue) : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icon(e), size: iconSize, color: _isDir(e) ? Colors.amber : Colors.blueGrey),
                          Text(_name(e), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    if (sel)
                      Positioned(
                        right: 0, top: 0,
                        child: Builder(
                          builder: (btnCtx) => IconButton(
                            icon: const Icon(Icons.more_vert, size: 28), // BÜYÜTÜLDÜ
                            onPressed: () {
                              final RenderBox box = btnCtx.findRenderObject() as RenderBox;
                              final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                              final RelativeRect position = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  box.localToGlobal(Offset.zero, ancestor: overlay),
                                  box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );
                              _showItemMenuAt(position, e);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_selected.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e90ff),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.create_new_folder),
              label: const Text('YENİ KLASÖR'),
              onPressed: _createFolder,
            ),
            if (_clipboard.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.paste),
                label: const Text('YAPIŞTIR'),
                onPressed: _paste,
              ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27ae60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.note_add),
              label: const Text('YENİ NOT'),
              onPressed: _createNoteHere,
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.blue.shade50,
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.blue.shade200)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(Icons.copy, 'Kopyala', () => _copySelected(false)),
              _actionBtn(Icons.content_cut, 'Kes', () => _copySelected(true)),
              _actionBtn(Icons.delete, 'Sil', () async {
                for (var i in _selected.toList()) {
                  final item = _items[i];
                  if (item is File) await item.delete();
                  else if (item is Directory) await item.delete(recursive: true);
                }
                _load();
                _snack('Seçili öğeler silindi');
              }, color: Colors.redAccent),
              _actionBtn(Icons.close, 'İptal', () => setState(() => _selected.clear()), color: isDark ? Colors.white70 : Colors.blueGrey),
            ],
          ),
        ),
      );
    }
  }

  Widget _actionBtn(IconData icon, String lbl, VoidCallback press, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? const Color(0xFF58A6FF) : Colors.blue;
    return InkWell(
      onTap: press,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? defaultColor, size: 28),
          const SizedBox(height: 4),
          Text(lbl, style: TextStyle(fontSize: 11, color: color ?? defaultColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: Text(_loading ? 'Yükleniyor...' : _realName(_cur.parent) + ' / ' + _realName(_cur),
        style: const TextStyle(fontSize: 13)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_upward),
        onPressed: () { setState(() { _cur = _cur.parent; }); _load(); },
      ),
      actions: [
        IconButton(
          icon: Icon(_viewMode == 'list' ? Icons.grid_view : Icons.list),
          onPressed: () async {
            final newMode = _viewMode == 'list' ? 'grid_small' : 'list';
            await AppConfig.saveViewMode(newMode);
            setState(() => _viewMode = newMode);
          },
          tooltip: 'Görünüm değiştir',
        ),
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.of(ctx).pop(),
          tooltip: 'Ana Menüye Dön',
        ),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pathCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        prefixIcon: Icon(Icons.folder_open, size: 16),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (val) async {
                        if (await Directory(val).exists()) {
                          setState(() { _cur = Directory(val); });
                          _load();
                        } else {
                          _snack('Geçersiz yol!');
                          _pathCtrl.text = _cur.path;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.folder_shared, color: Color(0xFF58A6FF)),
                    onPressed: () async {
                      String? selected = await FilePicker.platform.getDirectoryPath();
                      if (selected != null && await Directory(selected).exists()) {
                        setState(() { _cur = Directory(selected); });
                        _load();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildFileList()),
            _buildBottomBar(),
          ],
        ),
  );
}
