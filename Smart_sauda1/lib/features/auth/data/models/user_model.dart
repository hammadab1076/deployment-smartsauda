import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.isActive,
    super.phone,
  });

  // From Firestore (camelCase)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id:       id,
      name:     map['name'] ?? '',
      email:    map['email'] ?? '',
      role:     map['role'] ?? 'customer',
      isActive: map['isActive'] ?? true,
      phone:    map['phone'],
    );
  }

  // From MySQL API response (snake_case columns)
  factory UserModel.fromApiMap(Map<String, dynamic> map) {
    return UserModel(
      id:       map['id'] ?? '',
      name:     map['name'] ?? '',
      email:    map['email'] ?? '',
      role:     map['role'] ?? 'customer',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      phone:    map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':       id,
      'name':     name,
      'email':    email,
      'role':     role,
      'isActive': isActive,
      'phone':    phone,
    };
  }
}
