import 'package:first_try/core/theme/app_colors.dart';
import 'package:first_try/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.lightError,
                behavior: SnackBarBehavior.floating,
                shape: const RoundedRectangleBorder(
                    borderRadius: Radii.mdRadius),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Brand mark ───────────────────────────────────────
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: Radii.lgRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF4F46E5),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Headline ─────────────────────────────────────────
                      const Text(
                        'School App',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Card ─────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: Radii.xxlRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email
                              _Label('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDeco(
                                  hint: 'you@school.edu',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Password
                              _Label('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _inputDeco(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'At least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // Sign in button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF6366F1),
                                      ],
                                    ),
                                    borderRadius: Radii.mdRadius,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: Radii.mdRadius),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F7FB),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: Radii.smRadius,
        borderSide: const BorderSide(color: Color(0xFFE3E3EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Radii.smRadius,
        borderSide: const BorderSide(color: Color(0xFFE3E3EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.smRadius,
        borderSide:
            const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.smRadius,
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Radii.smRadius,
        borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      errorStyle:
          const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        letterSpacing: 0.1,
      ),
    );
  }
}
