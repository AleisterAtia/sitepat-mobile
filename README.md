# SI-TEPAT — Aplikasi Petugas (Mobile)

Aplikasi Flutter untuk **petugas lapangan** (SPBU/pangkalan gas) pada sistem
**SI-TEPAT**. Petugas login, memindai UID chip **e-KTP via NFC**, lalu memproses
klaim subsidi ke backend Go [`subsigo-backend`](../subsigo-backend).

## Alur

1. **Login** (khusus akun role `merchant`; admin ditolak).
2. Pilih **komoditas** (LPG 3 Kg / Pertalite).
3. Tekan **Scan e-KTP** → tempelkan kartu → app membaca UID via NFC.
4. App mengirim `POST /api/v1/claims` → menampilkan hasil **Berhasil** (dengan sisa
   kuota) atau **Ditolak** (dengan alasan).

## Teknologi

- Flutter 3.44 / Dart 3.12
- `flutter_nfc_kit` (baca UID NFC), `dio` (HTTP), `shared_preferences` (token)

## Prasyarat (PENTING untuk Windows)

- **Aktifkan Developer Mode** agar Flutter bisa build app berplugin:
  ```powershell
  start ms-settings:developers
  ```
  (tanpa ini, build gagal: *"Building with plugins requires symlink support"*).
- **Perangkat Android fisik ber-NFC** (emulator tidak punya NFC). Aktifkan USB
  debugging + NFC di perangkat.
- Backend `subsigo-backend` aktif (default app menembak deployment Vercel).

## Menjalankan

```bash
flutter pub get
flutter run                         # pakai backend Vercel (default)
# atau arahkan ke backend lokal (emulator -> host pakai 10.0.2.2):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Login dengan akun **petugas** (mis. seed: `petugas1` / `petugas123`).

## Konfigurasi

| Define | Default | Keterangan |
|---|---|---|
| `API_BASE_URL` | `https://subsigo-backend.vercel.app` | Base URL backend. Override via `--dart-define`. |

## Struktur

```
lib/
  config.dart                Base URL API & konstanta komoditas
  models/                    AuthUser, ClaimResult
  services/
    api_service.dart         Klien dio + token (login, claim)
    nfc_service.dart         Pembacaan UID NFC (flutter_nfc_kit)
  screens/
    login_screen.dart        Login petugas
    home_screen.dart         Pilih komoditas + scan + hasil klaim
  main.dart                  Entry: muat sesi -> Login/Home
```

## Catatan

- **NFC tidak bisa diuji di emulator** — perlu perangkat fisik ber-NFC.
- Token JWT disimpan di `shared_preferences` (sederhana). Untuk produksi,
  pertimbangkan `flutter_secure_storage` (terenkripsi).
- iOS belum dikonfigurasi (perlu entitlement NFC + `NFCReaderUsageDescription`);
  fokus saat ini Android sesuai PRD.
