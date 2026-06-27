/// Konfigurasi aplikasi.
///
/// Base URL backend Go (subsigo-backend). Default ke deployment Vercel.
/// Untuk menguji ke backend lokal, jalankan dengan:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// (10.0.2.2 = alamat host dari emulator Android; perangkat fisik pakai IP LAN PC).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://subsigo-backend.vercel.app',
);

/// Komoditas subsidi yang dapat diklaim (harus sama dengan konstanta di backend).
class Commodity {
  static const String lpg3kg = 'LPG_3KG';
  static const String pertalite = 'PERTALITE';

  static const List<String> all = [lpg3kg, pertalite];

  static String label(String code) {
    switch (code) {
      case lpg3kg:
        return 'LPG 3 Kg';
      case pertalite:
        return 'Pertalite';
      default:
        return code;
    }
  }
}
