import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Exception NFC dengan pesan ramah pengguna.
class NfcException implements Exception {
  final String message;
  NfcException(this.message);
  @override
  String toString() => message;
}

/// Pembungkus pembacaan UID e-KTP via NFC (flutter_nfc_kit), mode polling.
class NfcService {
  /// Membaca UID kartu e-KTP. Mengembalikan UID dalam string heksadesimal.
  /// Melempar [NfcException] bila NFC tidak tersedia/nonaktif atau gagal baca.
  static Future<String> readUid() async {
    final availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      throw NfcException(
        availability == NFCAvailability.disabled
            ? 'NFC nonaktif. Aktifkan NFC di pengaturan perangkat.'
            : 'Perangkat ini tidak mendukung NFC.',
      );
    }

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Tempelkan e-KTP ke perangkat',
      );
      final uid = tag.id.trim();
      if (uid.isEmpty) {
        throw NfcException('Gagal membaca UID kartu. Coba lagi.');
      }
      return uid;
    } on NfcException {
      rethrow;
    } catch (e) {
      // poll() melempar bila timeout / dibatalkan.
      throw NfcException('Pembacaan NFC gagal atau dibatalkan. Coba lagi.');
    } finally {
      // Selalu akhiri sesi NFC agar reader bebas untuk pemindaian berikutnya.
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
    }
  }
}
