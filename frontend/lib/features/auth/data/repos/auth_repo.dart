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
}
