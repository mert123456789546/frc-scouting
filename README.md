# FRC Scouting – Kurulum

## 1) Windows desteğini ekle (bir kere)
Klasörün içinde terminal aç:
    powershell -ExecutionPolicy Bypass -File setup_platforms.ps1
Bu komut Windows, Android ve iOS klasörlerini oluşturur, Android'e internet iznini ekler.
(lib/main.dart ve pubspec.yaml üzerine yazılırsa bu dosyaları yeniden kopyala.)

## 2) Worker
Cloudflare tarafı hazır (https://frc-scouting.dincermertozer.workers.dev). lib/main.dart içindeki appToken, Worker'daki APP_TOKEN secret'ı ile aynı olmalı.

## 3) Test
    flutter run -d windows

## 4) .exe + kurulum sihirbazı
Inno Setup 6'yı kur (jrsoftware.org), sonra proje klasöründe build_installer.bat çalıştır.
Çıktı: installer\output\FRC_Scouting_Setup.exe -> web sitene indirme linki olarak koy.

## 5) Android ve iOS
Gereken araçlar: Windows için Visual Studio (C++), Android için Android Studio. iOS için Mac gerekir.
- Android test: telefonda USB hata ayıklamayı aç, `flutter run`. APK: `flutter build apk --release`.
- Mac yoksa: projeyi GitHub'a yükle, Actions sekmesinden "Build mobile" çalıştır; APK ve iOS derlemesi
  bulutta üretilir. iOS'u gerçek iPhone'a kurmak/dağıtmak için Apple Developer hesabı (99 USD/yıl)
  ve imzalama gerekir.

## 6) Yayınlama (indirme sayfası + otomatik derleme)
1. lib/main.dart'taki appToken, Cloudflare'deki APP_TOKEN secret'ı ile aynı olmalı.
2. Projeyi GitHub'a yükle (public repo, GitHub Pages ücretsiz).
3. Repo > Settings > Pages > Source: **GitHub Actions**.
4. Sürüm çıkar:  `git tag v1.0.0` ardından `git push origin v1.0.0`
5. Actions sekmesi bitince:
   - Releases'ta FRC_Scouting_Setup.exe ve FRC_Scouting.apk hazır olur,
   - https://KULLANICI.github.io/REPO/ indirme sayfası ve iPhone web uygulaması (/app/) yayında olur.
Sayfadaki indirme linkleri kullanıcı/repo adını otomatik bulur, elle düzenleme gerekmez.
