/// Identitas pengguna yang login (petugas lapangan).
class AuthUser {
  final String id;
  final String username;
  final String role; // "merchant" | "admin"
  final String merchantName;

  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.merchantName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      merchantName: (json['merchant_name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
    'merchant_name': merchantName,
  };
}
