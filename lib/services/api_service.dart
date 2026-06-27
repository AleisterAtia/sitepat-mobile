import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/auth_user.dart';
import '../models/claim_result.dart';

/// Exception API dengan pesan ramah pengguna dan kode status (jika ada).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// Klien API ke backend Go (subsigo-backend). Singleton.
///
/// Menyimpan token JWT di SharedPreferences. Catatan keamanan: untuk produksi,
/// pertimbangkan flutter_secure_storage agar token terenkripsi.
class ApiService {
  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // Sisipkan header Authorization otomatis bila ada token.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._();

  late final Dio _dio;
  String? _token;
  AuthUser? _user;

  static const _kToken = 'token';
  static const _kUser = 'user';

  AuthUser? get user => _user;
  bool get isLoggedIn => _token != null;

  /// Memulihkan sesi dari penyimpanan lokal saat aplikasi dibuka.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    final raw = prefs.getString(_kUser);
    if (raw != null) {
      try {
        _user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
  }

  Future<void> _saveSession(String token, AuthUser user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  /// Login petugas. Menolak akun non-merchant (aplikasi ini khusus petugas).
  Future<AuthUser> login(String username, String password) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      if (user.role != 'merchant') {
        throw ApiException(
          'Akun ini bukan petugas. Aplikasi ini khusus untuk petugas lapangan.',
        );
      }
      await _saveSession(token, user);
      return user;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Memproses klaim subsidi. Mengembalikan ClaimResult untuk sukses MAUPUN
  /// penolakan bisnis (keduanya HTTP 200). Hanya error teknis yang dilempar.
  Future<ClaimResult> claim({
    required String nfcUid,
    required String commodity,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/claims',
        data: {'nfc_uid': nfcUid, 'commodity': commodity},
      );
      return ClaimResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        );
      default:
        break;
    }
    final res = e.response;
    if (res != null) {
      final data = res.data;
      if (data is Map && data['error'] != null) {
        return ApiException(data['error'].toString(), res.statusCode);
      }
      if (data is Map && data['message'] != null) {
        return ApiException(data['message'].toString(), res.statusCode);
      }
      return ApiException('Permintaan gagal (${res.statusCode}).', res.statusCode);
    }
    return ApiException('Terjadi kesalahan jaringan.');
  }
}
