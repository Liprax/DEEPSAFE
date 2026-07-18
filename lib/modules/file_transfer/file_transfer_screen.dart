import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_multipart/shelf_multipart.dart';
import '../../core/config/app_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileTransferScreen extends StatefulWidget {
  const FileTransferScreen({super.key});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  HttpServer? _server;
  String _ipAddress = 'Yükleniyor...';
  String _sessionToken = '';
  final int _port = 8080;
  List<File> _currentFiles = [];
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _transferDirPath;

  @override
  void initState() {
    super.initState();
    _initTransferDir().then((_) => _startServer());
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  Future<void> _initTransferDir() async {
    final customPath = await AppConfig.getTransferPath();
    if (customPath != null) {
      _transferDirPath = customPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      _transferDirPath = p.join(directory.path, 'Transfers');
    }

    final transferDir = Directory(_transferDirPath!);
    if (!await transferDir.exists()) await transferDir.create(recursive: true);
    _refreshFiles();
  }

  void _refreshFiles() {
    if (_transferDirPath == null) return;
    final dir = Directory(_transferDirPath!);
    if (dir.existsSync()) {
      setState(() {
        _currentFiles = dir.listSync().whereType<File>().toList();
        _currentFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      });
    }
  }

  Future<void> _openTransferFolder() async {
    if (_transferDirPath == null) return;
    final path = _transferDirPath!;
    
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  Future<void> _startServer() async {
    String? ip;
    try {
      ip = await _networkInfo.getWifiIP();
      if (ip == null || ip == '127.0.0.1' || ip == '0.0.0.0') {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              ip = addr.address;
              break;
            }
          }
          if (ip != null) break;
        }
      }
    } catch (e) {
      debugPrint('IP discovery error: $e');
    }

    setState(() {
      _ipAddress = ip ?? '127.0.0.1';
      _sessionToken = _generateRandomToken();
    });

    final router = shelf_router.Router();

    // Serve HTML Interface
    router.get('/$_sessionToken', (Request request) {
      return Response.ok(_getHtmlInterface(), headers: {'Content-Type': 'text/html; charset=utf-8'});
    });

    // Handle File Upload from Mobile
    router.post('/upload/$_sessionToken', (Request request) async {
      final multipart = request.multipart();
      if (multipart == null) return Response.badRequest(body: 'Multipart missing');

      try {
        await for (final part in multipart.parts) {
          final contentDisposition = part.headers['content-disposition'];
          String? fileName;
          if (contentDisposition != null) {
            final match = RegExp('filename="([^"]+)"').firstMatch(contentDisposition);
            if (match != null) fileName = match.group(1);
          }

          if (fileName != null && _transferDirPath != null) {
            final file = File(p.join(_transferDirPath!, fileName));
            final sink = file.openWrite();
            await part.pipe(sink);
            await sink.close();
            _refreshFiles();
          }
        }
        return Response.ok('Dosya başarıyla yüklendi');
      } catch (e) {
        return Response.internalServerError(body: 'Hata: $e');
      }
    });

    // List Files for Mobile Download
    router.get('/list/$_sessionToken', (Request request) {
      final fileNames = _currentFiles.map((f) => p.basename(f.path)).toList();
      return Response.ok(fileNames.join('|'), headers: {'Content-Type': 'text/plain; charset=utf-8'});
    });

    // Download File to Mobile
    router.get('/download/$_sessionToken/<name>', (Request request, String name) async {
      final filePath = p.join(_transferDirPath!, Uri.decodeComponent(name));
      final file = File(filePath);
      if (await file.exists()) {
        return Response.ok(file.openRead(), headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition': 'attachment; filename="${p.basename(filePath)}"',
        });
      }
      return Response.notFound('Dosya bulunamadı');
    });

    _server = await io.serve(router, InternetAddress.anyIPv4, _port);
    debugPrint('Server running on http://${_server!.address.address}:${_server!.port}');
  }

  String _generateRandomToken() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _getHtmlInterface() {
    return '''
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DeepSafe - Güvenli Dosya Transferi</title>
    <link href="https://fonts.googleapis.com/css2?family=Segoe+UI:wght@400;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --primary: #27ae60; --secondary: #2f3542; --bg: #f1f2f6; --white: #ffffff; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg); margin: 0; padding: 20px; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 500px; }
        .card { background: var(--white); border-radius: 16px; padding: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); margin-bottom: 20px; }
        h1 { color: var(--secondary); font-size: 24px; margin: 0 0 8px 0; text-align: center; }
        h2 { color: var(--secondary); font-size: 18px; margin: 0 0 16px 0; border-bottom: 2px solid var(--bg); padding-bottom: 8px; }
        p { color: #666; text-align: center; margin-bottom: 24px; font-size: 14px; }
        
        .upload-box { border: 2px dashed #ccc; border-radius: 12px; padding: 32px; text-align: center; transition: all 0.3s; cursor: pointer; background: #fafafa; position: relative; }
        .upload-box:hover { border-color: var(--primary); background: #f0fff4; }
        .upload-box input { position: absolute; width: 100%; height: 100%; top: 0; left: 0; opacity: 0; cursor: pointer; }
        .upload-box i { font-size: 40px; color: var(--primary); display: block; margin-bottom: 8px; }
        
        .btn { display: block; width: 100%; padding: 14px; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; transition: 0.3s; margin-top: 16px; text-align: center; text-decoration: none; box-sizing: border-box; }
        .btn-primary { background: var(--primary); color: white; }
        .btn-primary:hover { background: #219150; }
        .btn-outline { background: transparent; border: 2px solid var(--secondary); color: var(--secondary); padding: 10px; }
        .btn:disabled { background: #ccc; cursor: not-allowed; }

        .file-list { list-style: none; padding: 0; margin: 0; }
        .file-item { display: flex; align-items: center; justify-content: space-between; padding: 12px; border-bottom: 1px solid #eee; }
        .file-item:last-child { border-bottom: none; }
        .file-name { font-size: 14px; color: #333; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 70%; }
        .download-link { color: var(--primary); font-weight: 600; font-size: 13px; text-decoration: none; }
        
        #status { margin-top: 16px; font-weight: 600; text-align: center; min-height: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>DeepSafe</h1>
            <p>Bilgisayara dosya gönderin</p>
            <form id="uploadForm">
                <div class="upload-box">
                    <i>📤</i>
                    <span id="fileName">Dosyaları buraya bırakın veya tıklayın</span>
                    <input type="file" id="fileInput" name="files" multiple onchange="showFiles()">
                </div>
                <button type="submit" id="uploadBtn" class="btn btn-primary">GÖNDERİMİ BAŞLAT</button>
            </form>
            <div id="status"></div>
        </div>

        <div class="card">
            <h2>Bilgisayardaki Dosyalar</h2>
            <ul id="fileList" class="file-list">
                <li style="text-align:center; color:#999; padding:20px;">Yükleniyor...</li>
            </ul>
            <button onclick="loadFiles()" class="btn btn-outline" style="font-size:12px; margin-top:20px;">LİSTEYİ YENİLE</button>
        </div>
    </div>

    <script>
        function showFiles() {
            const input = document.getElementById('fileInput');
            const label = document.getElementById('fileName');
            label.innerText = input.files.length > 0 ? input.files.length + ' dosya seçildi' : 'Dosyaları buraya bırakın veya tıklayın';
        }

        const form = document.getElementById('uploadForm');
        const status = document.getElementById('status');
        const btn = document.getElementById('uploadBtn');

        form.onsubmit = async (e) => {
            e.preventDefault();
            if (document.getElementById('fileInput').files.length === 0) return;

            btn.disabled = true;
            status.innerText = 'Yükleniyor...';
            status.style.color = '#f39c12';

            const formData = new FormData(form);
            try {
                const response = await fetch('/upload/$_sessionToken', { method: 'POST', body: formData });
                if (response.ok) {
                    status.innerText = 'Başarıyla yüklendi! ✅';
                    status.style.color = '#27ae60';
                    form.reset();
                    showFiles();
                    loadFiles();
                } else {
                    status.innerText = 'Hata: ' + await response.text();
                    status.style.color = '#e74c3c';
                }
            } catch (err) {
                status.innerText = 'Bağlantı hatası!';
                status.style.color = '#e74c3c';
            } finally {
                btn.disabled = false;
            }
        };

        async function loadFiles() {
            const list = document.getElementById('fileList');
            try {
                const response = await fetch('/list/$_sessionToken');
                const data = await response.text();
                const files = data ? data.split('|') : [];
                
                list.innerHTML = files.length > 0 ? '' : '<li style="text-align:center; color:#999; padding:20px;">Klasör boş</li>';
                
                files.forEach(name => {
                    const li = document.createElement('li');
                    li.className = 'file-item';
                    li.innerHTML = `
                        <span class="file-name">\${name}</span>
                        <a href="/download/$_sessionToken/\${encodeURIComponent(name)}" class="download-link" download>İNDİR</a>
                    `;
                    list.appendChild(li);
                });
            } catch (err) {
                list.innerHTML = '<li style="color:red; text-align:center;">Liste alınamadı!</li>';
            }
        }
        loadFiles();
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final url = 'http://$_ipAddress:$_port/$_sessionToken';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF010409) : const Color(0xFFf1f2f6),
      appBar: AppBar(
        title: const Text('Güvenli Dosya Aktarımı'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFiles,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                  border: isDark ? Border.all(color: Colors.white10) : null,
                ),
                child: Column(
                  children: [
                    Text('MOBİL BAĞLANTI', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2f3542))),
                    const SizedBox(height: 8),
                    const Text('Dosya alıp göndermek için kodu okutun', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SelectableText(
                      url,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF58A6FF), fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _openTransferFolder,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('AKTARRIM KLASÖRÜNÜ AÇ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1e90ff) : const Color(0xFF2f3542),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MEVCUT DOSYALAR', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2f3542))),
                  Text('${_currentFiles.length} Dosya', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              if (_currentFiles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
                  ),
                  child: const Text('Henüz dosya bulunmuyor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentFiles.length,
                  itemBuilder: (context, index) {
                    final file = _currentFiles[index];
                    final name = p.basename(file.path);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: isDark ? const Color(0xFF0D1117) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFf1f2f6),
                          child: const Icon(Icons.insert_drive_file, color: Color(0xFF58A6FF), size: 20),
                        ),
                        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            file.deleteSync();
                            _refreshFiles();
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
