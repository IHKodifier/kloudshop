class UserClaims {
  final String uid;
  final String? email;
  final String? tenantId;
  final String accountType;
  final List<String> roles;
  final bool isOwner;

  UserClaims({
    required this.uid,
    this.email,
    this.tenantId,
    required this.accountType,
    required this.roles,
    required this.isOwner,
  });

  factory UserClaims.fromJson(Map<String, dynamic> json) {
    return UserClaims(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      tenantId: json['tenant_id'] as String?,
      accountType: json['account_type'] as String? ?? 'staff',
      roles: List<String>.from(json['roles'] ?? []),
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'tenant_id': tenantId,
      'account_type': accountType,
      'roles': roles,
      'is_owner': isOwner,
    };
  }
}
