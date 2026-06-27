/// Hasil pemrosesan klaim subsidi dari backend.
///
/// Catatan: penolakan bisnis (UID tak terdaftar, tidak layak, kuota habis) tetap
/// dikembalikan dengan HTTP 200 + status "rejected" (bukan error). Hanya error
/// teknis yang dilempar sebagai exception.
class ClaimResult {
  final String status; // "success" | "rejected"
  final String message;
  final int quotaRemaining;
  final String transactionId;

  const ClaimResult({
    required this.status,
    required this.message,
    required this.quotaRemaining,
    required this.transactionId,
  });

  bool get isSuccess => status == 'success';

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    return ClaimResult(
      status: (json['status'] ?? 'rejected') as String,
      message: (json['message'] ?? '') as String,
      quotaRemaining: (json['quota_remaining'] as num?)?.toInt() ?? 0,
      transactionId: (json['transaction_id'] ?? '') as String,
    );
  }
}
