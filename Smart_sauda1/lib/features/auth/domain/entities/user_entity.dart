class UserEntity {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final bool isActive;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.phone,
  });
}
