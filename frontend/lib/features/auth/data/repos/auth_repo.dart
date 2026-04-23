import 'package:dio/dio.dart';
import 'package:first_try/core/api/api_consumer.dart';
import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/data/models/auth_model.dart';

class AuthRepo {
  final ApiConsumer api;

  AuthRepo({required this.api});

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await api.post(
      AppUrl.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await api.post(AppUrl.logout);
  }

  /// Validate the stored token and refresh user data from the server.
  /// Backend shape: { user: { id, name, email, phone, profile_picture }, role }
  Future<UserModel> me() async {
    final response = await api.getApi(AppUrl.me) as Map<String, dynamic>;
    final userMap = Map<String, dynamic>.from(
      response['user'] as Map<String, dynamic>,
    );
    userMap['role_type'] = response['role'] as String;
    return UserModel.fromJson(userMap);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await api.put(
      AppUrl.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
  }

  /// Upload a new profile picture (multipart form-data).
  Future<String?> updateProfilePicture(String filePath) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(filePath),
    });
    final response = await api.post(
      AppUrl.profilePicture,
      data: formData,
    ) as Map<String, dynamic>;
    return response['profile_picture'] as String?;
  }

  Future<void> deleteProfilePicture() async {
    await api.delete(AppUrl.profilePicture);
  }
}
