/// Modelo de usuário e perfil de acesso conforme coleção Firestore users/{uid}.
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin', 'operator', 'viewer'
  final bool isActive;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin' && isActive;
  bool get isAuthorized => isActive && (role == 'admin' || role == 'operator');

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'active': isActive,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    final active = map['active'] as bool? ?? map['isActive'] as bool? ?? false;
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: map['role'] as String? ?? 'viewer',
      isActive: active,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
