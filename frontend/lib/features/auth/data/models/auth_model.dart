import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  /// `users.id` — the auth identity. Use this for endpoints that operate on
  /// the user record itself (e.g. `/profile-picture`, messages between users).
  final int id;
  final String name;
  final String email;

  /// One of: student | parent | teacher | driver
  final String roleType;

  /// Role-specific PK from the corresponding table (`teachers.id`,
  /// `students.id`, `guardians.id`, `driver.driver_id`). Use this for
  /// `/teacher/{id}/...` style endpoints — `users.id` and the role table id
  /// are *different* PKs and mixing them up will return another user's data.
  final int? roleId;

  /// Storage-relative path returned by the backend, e.g.
  /// `profile-pictures/12/abc.jpg`. Null when no picture is set.
  final String? profilePicture;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleType,
    this.roleId,
    this.profilePicture,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? roleType,
    int? roleId,
    String? profilePicture,
    bool clearProfilePicture = false,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        roleType: roleType ?? this.roleType,
        roleId: roleId ?? this.roleId,
        profilePicture:
            clearProfilePicture ? null : (profilePicture ?? this.profilePicture),
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        roleType: json['role_type'] as String,
        roleId: json['role_id'] as int?,
        profilePicture: json['profile_picture'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role_type': roleType,
        if (roleId != null) 'role_id': roleId,
        if (profilePicture != null) 'profile_picture': profilePicture,
      };

  @override
  List<Object?> get props => [id, name, email, roleType, roleId, profilePicture];
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
