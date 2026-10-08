# Todo App — Android (Flutter)

Aplikasi Android untuk Todo App. Memakai backend Laravel yang sama dengan versi web,
di `https://api-todo.inovasionline.com/api`, dengan login bearer token Sanctum
(token disimpan terenkripsi lewat `flutter_secure_storage`, jadi tidak perlu login ulang).

Fitur: masuk/daftar, tugas hari ini + progres, daftar tugas dengan pencarian & filter
(kategori, status, tanggal/bulan/tahun) dikelompokkan per kategori, tambah/ubah tugas
dengan deskripsi panjang, centang selesai, hapus, serta kelola kategori.

## Menjalankan

```bash
flutter pub get
flutter run                       # ke HP/emulator yang terhubung
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
```

Backend lain (mis. lokal dari emulator):

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:8020/api
```

> Release build masih ditandatangani dengan debug key (bawaan `flutter create`).
> Sebelum rilis ke Play Store, buat keystore sendiri dan atur `signingConfigs`.
