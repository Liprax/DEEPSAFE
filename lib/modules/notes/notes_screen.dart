import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../core/config/app_config.dart';
import '../../core/crypto/xor_cipher.dart';

class NotesScreen extends StatefulWidget {
  final File? file;
  const NotesScreen({super.key, this.file});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  Database? _db;
  List<Map<String, dynamic>> _notes = [];
  int? _openId;
  late FleatherController _editor;
  late TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _editor    = FleatherController();
    _titleCtrl = TextEditingController();
    if (widget.file != null) {
      _loadFromFile();
    } else {
      _initDb();
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final bytes = await widget.file!.readAsBytes();
      final salt = await AppConfig.getSalt();
      
      String content;
      try {
        // Önce şifreli olduğunu varsayıp çözmeyi dene
        final decrypted = await AesGcmCipher.decrypt(bytes, salt);
        content = utf8.decode(decrypted);
      } catch (_) {
        // Şifreli değilse (veya yanlış tuz) düz metin olarak oku
        content = utf8.decode(bytes);
      }

      final doc = ParchmentDocument()..insert(0, content);
      setState(() {
        _openId = -2; // Special ID for external files
        _editor = FleatherController(document: doc);
        _titleCtrl = TextEditingController(text: p.basename(widget.file!.path));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya okunamadı: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initDb() async {
    final path = p.join(await getDatabasesPath(), 'notes.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) =>
      db.execute(
        'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, updated TEXT)'
      ));
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final rows = await _db!.query('notes', orderBy: 'updated DESC');
    setState(() => _notes = rows);
  }

  Future<void> _save() async {
    final content = _editor.document.toPlainText();
    final title   = _titleCtrl.text.isEmpty ? 'Başlıksız' : _titleCtrl.text;
    final now     = DateTime.now().toIso8601String();

    if (widget.file != null) {
      try {
        final salt = await AppConfig.getSalt();
        final bytes = Uint8List.fromList(utf8.encode(content));
        final encrypted = await AesGcmCipher.encrypt(bytes, salt);
        await widget.file!.writeAsBytes(encrypted);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya şifrelenerek kaydedildi ✓')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')));
        }
      }
      return;
    }

    if (_openId == null || _openId == -1) {
      await _db!.insert('notes', {'title': title, 'content': content, 'updated': now});
    } else {
      await _db!.update('notes',
        {'title': title, 'content': content, 'updated': now},
        where: 'id = ?', whereArgs: [_openId]);
    }
    _loadNotes();
    setState(() { _openId = null; _editor = FleatherController(); _titleCtrl.clear(); });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedildi ✓')));
    }
  }

  Future<void> _delete(int id) async {
    await _db!.delete('notes', where: 'id = ?', whereArgs: [id]);
    _loadNotes();
  }

  void _open(Map<String, dynamic> note) {
    final doc = ParchmentDocument()..insert(0, note['content'] ?? '');
    setState(() {
      _openId    = note['id'];
      _editor    = FleatherController(document: doc);
      _titleCtrl = TextEditingController(text: note['title']);
    });
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('Notlar'),
      actions: [
        if (_openId != null)
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        if (_openId != null)
          IconButton(icon: const Icon(Icons.close), onPressed: () =>
            setState(() {
              _openId = null;
              _editor = FleatherController();
              _titleCtrl.clear();
            })),
      ],
    ),
    floatingActionButton: _openId == null
      ? FloatingActionButton(
          onPressed: () => setState(() {
            _openId = -1;
            _editor = FleatherController();
            _titleCtrl.clear();
          }),
          child: const Icon(Icons.add),
        )
      : null,
    body: _openId != null ? _editorView() : _listView(),
  );

  Widget _listView() => _notes.isEmpty
    ? const Center(
        child: Text('Henüz not yok.\n+ ile yeni not ekleyin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey)))
    : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (_, i) {
          final n = _notes[i];
          return ListTile(
            leading: const Icon(Icons.note, color: Color(0xFF05c46b)),
            title: Text(n['title'] ?? 'Başlıksız'),
            subtitle: Text((n['updated'] ?? '').toString().substring(0, 10)),
            onTap: () => _open(n),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _delete(n['id'])),
          );
        },
      );

  Widget _editorView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            hintText: 'Başlık...', border: InputBorder.none),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      const Divider(height: 1),
      FleatherToolbar.basic(controller: _editor),
      Expanded(
        child: FleatherEditor(
          controller: _editor,
          padding: const EdgeInsets.all(16),
        ),
      ),
    ],
  );
}
