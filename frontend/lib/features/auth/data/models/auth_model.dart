import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;

  /// One of: student | parent | teacher | driver
  final String roleType;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        roleType: json['role_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role_type': roleType,
      };

  @override
  List<Object> get props => [id, name, email, roleType];
}

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Backend shape: { token, role, user: { id, name, email, phone, profile_picture } }
    // "role" is at the TOP level — NOT inside user. Inject it as role_type.
    final userMap = Map<String, dynamic>.from(
      json['user'] as Map<String, dynamic>,
    );
    userMap['role_type'] = json['role'] as String;
    return AuthResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(userMap),
    );
  }
}
