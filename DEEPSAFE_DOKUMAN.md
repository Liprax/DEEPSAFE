# 🔐 DeepSafe — Proje Dokümantasyonu
> Versiyon: 1.0 | Dil: Flutter/Dart | Platform: Android + iOS + Windows + Mac + Linux

---

## 📋 İÇİNDEKİLER
1. Proje Nedir?
2. Teknoloji Seçimleri ve Nedenleri
3. Kurulum (Adım Adım)
4. Proje Klasör Yapısı
5. Modüller ve Kodların Açıklaması
6. Yapılacaklar Listesi

---

## 1. 📌 PROJE NEDİR?

DeepSafe; dosya şifreleme, şifre üretici, not alma ve desen kilidi özelliklerini
bir arada sunan, tamamen offline çalışan güvenlik uygulamasıdır.

### Özellikler:
- 🔒 9 noktalı desen kilidi (giriş ekranı)
- 📂 Dosya gezgini (dosya şifreleme/çözme)
- 🔑 Gelişmiş şifre üretici
- 📝 Zengin metin not editörü (SQLite ile yerel kayıt)
- ⚙️ Ayarlar (desen ve tuz değiştirme)

---

## 2. 🛠️ TEKNOLOJİ SEÇİMLERİ

### Framework: Flutter
**Neden Flutter?**
- Tek kod → Android + iOS + Windows + Mac + Linux
- Yapay zeka Dart kodunu çok iyi yazıyor
- SQLite entegrasyonu mükemmel
- Offline çalışma için ideal

### Dil: Dart
- Flutter'ın resmi dili
- JavaScript'e benzer sözdizimi, öğrenmesi kolay
- Hem mobil hem masaüstü için derlenir

### Veritabanı: SQLite (sqflite paketi)
**Neden SQLite?**
- Tek .db dosyası, internet gerektirmez
- Notları tablo yapısında saklar (id, başlık, içerik, tarih)
- Arama, filtreleme, sıralama yapılabilir
- .txt veya .docx'ten çok daha güvenli ve esnek

### Şifreleme: XOR + SHA256
**Nasıl çalışır?**
- Tuz değeri SHA256 ile 32 byte'lık anahtar oluşturur
- Bu anahtar dosyanın her byte'ı ile XOR işlemi yapar
- Sonuç: orijinal dosya okunamaz hale gelir
- Aynı işlem tekrar uygulanınca dosya geri açılır

### Şifre Üretici: SHA256 Hash
**Nasıl çalışır?**
- Master Anahtar + Tuz + Uygulama Adı birleştirilir
- SHA256 ile hash üretilir
- İlk 16 karakter şifre olarak kullanılır
- Aynı girdiler her zaman aynı şifreyi üretir
- Master anahtarı bilmeden şifre üretilemez

### Desen Kilidi: CustomPainter
- 9 nokta (3x3 grid) Canvas üzerinde çizilir
- Parmak/fare hareketi takip edilir
- Seçilen noktalar sırayla kaydedilir
- SharedPreferences'a şifreli şekilde saklanır

---

## 3. 💻 KURULUM (YENİ BİLGİSAYARDA)

### Adım 1: Flutter Kur
1. https://flutter.dev/docs/get-started/install adresine git
2. Windows için Flutter SDK indir
3. ZIP'i C:\flutter klasörüne çıkart
4. Sistem PATH'e C:\flutter\bin ekle

### Adım 2: Android Studio Kur (Android için)
1. https://developer.android.com/studio indir
2. Kur ve aç
3. SDK Manager'dan Android SDK'yı indir

### Adım 3: Visual Studio Kur (Windows masaüstü için)
1. https://visualstudio.microsoft.com/downloads/ → Community indir
2. Kurulumda "Desktop development with C++" seç (~5GB)
3. NOT: Sadece Android kullanacaksan bu adım gerekmez!

### Adım 4: Projeyi Oluştur
```cmd
flutter create deepsafe
cd deepsafe
```

### Adım 5: Dosyaları Kopyala
Aşağıdaki dosyaları doğru klasörlere kopyala:

```
deepsafe/
├── pubspec.yaml                          ← KÖK KLASÖR
└── lib/
    ├── main.dart                         ← lib/
    ├── core/
    │   ├── config/
    │   │   └── app_config.dart           ← lib/core/config/
    │   └── crypto/
    │       ├── xor_cipher.dart           ← lib/core/crypto/
    │       └── password_gen.dart         ← lib/core/crypto/
    ├── modules/
    │   ├── lock/
    │   │   └── pattern_lock_screen.dart  ← lib/modules/lock/
    │   ├── file_manager/
    │   │   └── file_manager_screen.dart  ← lib/modules/file_manager/
    │   ├── password_gen/
    │   │   └── password_gen_screen.dart  ← lib/modules/password_gen/
    │   └── notes/
    │       └── notes_screen.dart         ← lib/modules/notes/
    └── ui/
        ├── home_screen.dart              ← lib/ui/
        └── settings_screen.dart          ← lib/ui/
```

### Adım 6: Klasörleri Oluştur (CMD)
```cmd
cd deepsafe\lib
mkdir core\config
mkdir core\crypto
mkdir modules\lock
mkdir modules\file_manager
mkdir modules\password_gen
mkdir modules\notes
mkdir ui
```

### Adım 7: Paketleri Yükle
```cmd
cd deepsafe
flutter pub get
```

### Adım 8: Çalıştır
```cmd
# Android telefon için (USB bağlı olmalı, USB Hata Ayıklama açık):
flutter run

# Windows masaüstü için (Visual Studio kurulu olmalı):
flutter run -d windows
```

---

## 4. 📦 KULLANILAN PAKETLER

| Paket | Versiyon | Ne İşe Yarıyor |
|-------|----------|----------------|
| shared_preferences | ^2.2.2 | Desen ve tuz değerini saklar |
| sqflite | ^2.3.0 | Notları SQLite'a kaydeder |
| path_provider | ^2.1.2 | Dosya yollarını bulur (Android/iOS/PC) |
| path | ^1.9.0 | Dosya yolu birleştirme |
| crypto | ^3.0.3 | SHA256 şifreleme |
| fleather | ^1.12.0 | Zengin metin not editörü |
| cupertino_icons | ^1.0.6 | iOS ikonları |

---

## 5. 🧩 MODÜLLER VE KOD AÇIKLAMASI

### main.dart
Uygulamanın giriş noktası. Uygulama açıldığında direkt
PatternLockScreen (desen kilidi) ekranı açılır.

### core/config/app_config.dart
Ayarları yönetir. Desen ve tuz değerini telefon/bilgisayarın
yerel hafızasına (SharedPreferences) kaydeder ve okur.
- getPattern() → kayıtlı deseni getirir
- savePattern() → yeni deseni kaydeder
- getSalt() → tuz değerini getirir
- saveSalt() → yeni tuz kaydeder

### core/crypto/xor_cipher.dart
Dosya şifreleme motoru.
- Tuz değeri SHA256 ile 32 byte anahtar olur
- Her dosya byte'ı anahtarla XOR işlemine girer
- Aynı işlem tekrar uygulanınca dosya açılır
- Kullanım: XorCipher.process(veri, tuz)

### core/crypto/password_gen.dart
Şifre üretici motoru.
- Master + Tuz + UygulamaAdı birleştirilir
- SHA256 hash alınır
- İlk 16 karakter döndürülür
- Kullanım: PasswordGen.generate(master, appAdi, tuz)

### modules/lock/pattern_lock_screen.dart
9 noktalı desen kilidi ekranı.
- Canvas üzerinde 3x3 grid çizilir
- Parmak/fare hareketi GestureDetector ile takip edilir
- Çizilen desen kayıtlı desenle karşılaştırılır
- Doğruysa HomeScreen'e geçer, yanlışsa kırmızı gösterir

### modules/file_manager/file_manager_screen.dart
Dosya gezgini ekranı.
- Telefon/bilgisayar dosyalarını listeler
- Uzun basınca dosya seçilir
- Seçili dosyalar XorCipher ile şifrelenir/çözülür
- Şifreli dosyalara .deep uzantısı eklenir

### modules/password_gen/password_gen_screen.dart
Şifre üretici ekranı.
- Master anahtar ve uygulama adı girilir
- PasswordGen sınıfı ile 16 haneli şifre üretilir
- Kopyala butonu ile panoya kopyalanır

### modules/notes/notes_screen.dart
Not alma ekranı.
- Notlar SQLite veritabanında saklanır (notes.db)
- Fleather ile zengin metin editörü (kalın, italik, liste vb.)
- Not listesi, yeni not oluşturma, silme özellikleri

### ui/home_screen.dart
Ana menü ekranı.
- 4 modüle giriş butonları

### ui/settings_screen.dart
Ayarlar ekranı.
- Desen değiştirme (yeni desen çizme)
- Tuz değiştirme (metin girişi)

---

## 6. ✅ YAPILACAKLAR LİSTESİ

### Tamamlanan:
- [x] Desen kilidi
- [x] Dosya gezgini
- [x] XOR dosya şifreleme/çözme
- [x] SHA256 şifre üretici
- [x] Not alma modülü (SQLite)
- [x] Ayarlar ekranı

### Sonraki Modüller (Planlanıyor):
- [ ] SQLCipher ile veritabanı şifreleme
- [ ] Notlarda arama/filtreleme
- [ ] Dosya gezgininde arama
- [ ] Tema seçeneği (açık/koyu)
- [ ] Dışa aktarma (PDF, TXT)
- [ ] Bulut yedekleme (isteğe bağlı)

---

## 7. ⚠️ ÖNEMLİ NOTLAR

- Tuz değerini unutmayın! Tuz değişirse şifreli dosyalar açılamaz
- Desen kilidi minimum 4 nokta seçmeyi gerektiriyor
- .deep uzantılı dosyalar şifreli, normal programlarla açılamaz
- notes.db dosyası uygulama klasöründe saklanır
- Şu an XOR şifreleme kullanılıyor, ileride AES-256 eklenecek
