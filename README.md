🔐 DeepSafe — Project Documentation

Version: 1.02 | Language: Flutter/Dart | 

WHAT IS THE PROJECT?

DeepSafe is a fully offline security application that combines
file encryption, password generator, note taking, and pattern lock features
in a single app.

Features:
🔒 9-dot pattern lock (login screen)
📂 File explorer (file encryption/decryption)
🔑 Advanced password generator
📝 Rich text note editor (local storage with SQLite)
⚙️ Settings (change pattern and salt)
Encryption: XOR + SHA256

How does it work?

The salt value generates a 32-byte key using SHA256
This key performs an XOR operation on every byte of the file
Result: the original file becomes unreadable
Applying the same process again restores the file
Password Generator: SHA256 Hash

How does it work?

Master Key + Salt + Application Name are combined
A SHA256 hash is generated
The first 16 characters are used as the password
The same inputs always generate the same password
Passwords cannot be generated without knowing the master key

Pattern Lock: CustomPainter
9 dots (3x3 grid) are drawn on the Canvas
Finger/mouse movement is tracked
Selected dots are recorded in order
Stored in SharedPreferences in encrypted form

7. ⚠️ IMPORTANT NOTES

Do not forget the salt value! If the salt changes, encrypted files cannot be opened
The pattern lock requires selecting at least 4 dots
Default salt is "1" or "DEEPSAFE_TUZ_2026"
Default login pattern is "Z"

********************************************************************************************************************************************************************************************

🔐 DeepSafe — Proje Dokümantasyonu
> Versiyon: 1.02 | Dil: Flutter/Dart | 
---
 PROJE NEDİR?

DeepSafe; dosya şifreleme, şifre üretici, not alma ve desen kilidi özelliklerini
bir arada sunan, tamamen offline çalışan güvenlik uygulamasıdır.

### Özellikler:
- 🔒 9 noktalı desen kilidi (giriş ekranı)
- 📂 Dosya gezgini (dosya şifreleme/çözme)
- 🔑 Gelişmiş şifre üretici
- 📝 Zengin metin not editörü (SQLite ile yerel kayıt)
- ⚙️ Ayarlar (desen ve tuz değiştirme)

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

## 7. ⚠️ ÖNEMLİ NOTLAR

- Tuz değerini unutmayın! Tuz değişirse şifreli dosyalar açılamaz
- Desen kilidi minimum 4 nokta seçmeyi gerektiriyor
- Varsayılan tuz "1" yada "DEEPSAFE_TUZ_2026"
- Varsayılan giriş deseni "Z"
