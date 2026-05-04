import 'package:first_try/core/theme/theme.dart';
import 'package:first_try/core/widgets/ui/ui.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  // Entry animation.
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Shake-on-error.
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: Motion.epic)..forward();
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _intro, curve: Motion.standard));
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _shake.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().login(
            email: _email.text.trim(),
            password: _password.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _shake.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_friendlyError(state.message)),
              backgroundColor: cs.error,
            ),
          );
        }
        // go_router redirects on AuthAuthenticated.
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── Full-bleed gradient background ────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: palette.brandGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ── Atmospheric glow blobs ────────────────────────────────────
            const Positioned(
              top: -90,
              right: -70,
              child: _GlowBlob(size: 260, opacity: 0.22),
            ),
            const Positioned(
              top: 200,
              left: -80,
              child: _GlowBlob(size: 200, opacity: 0.14),
            ),

            // ── Animated content ──────────────────────────────────────────
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ── Hero: logo + app name ─────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 52, 24, 44),
                          child: Column(
                            children: [
                              const _BrandMark(),
                              const SizedBox(height: 22),
                              Text(
                                'School App',
                                style: tt.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your school, all in one place.',
                                style: tt.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Form card ─────────────────────────────────────
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            final t = _shake.value;
                            final dx =
                                (t == 0 ? 0 : (t * 8).remainder(2) - 1) *
                                    12 *
                                    (1 - t);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: Radii.sheetTopRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 40,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                                24, 32, 24, 32 + bottomPad),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 460),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back',
                                      style: tt.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sign in to continue to your school account.',
                                      style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 28),

                                    // Form fields
                                    Form(
                                      key: _formKey,
                                      child:
                                          BlocBuilder<AuthCubit, AuthState>(
                                        builder: (context, state) {
                                          final isLoading =
                                              state is AuthLoading;
                                          return Column(
                                            children: [
                                              TextFormField(
                                                controller: _email,
                                                enabled: !isLoading,
                                                keyboardType: TextInputType
                                                    .emailAddress,
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Email',
                                                  prefixIcon: Icon(
                                                      Icons.email_outlined),
                                                ),
                                                validator: (v) {
                                                  final t = (v ?? '').trim();
                                                  if (t.isEmpty) {
                                                    return 'Please enter your email';
                                                  }
                                                  if (!t.contains('@')) {
                                                    return 'Enter a valid email';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: _password,
                                                enabled: !isLoading,
                                                obscureText: _obscurePassword,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _submit(),
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  prefixIcon: const Icon(Icons
                                                      .lock_outline_rounded),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                        _obscurePassword
                                                            ? Icons
                                                                .visibility_off_outlined
                                                            : Icons
                                                                .visibility_outlined),
                                                    onPressed: () => setState(
                                                        () => _obscurePassword =
                                                            !_obscurePassword),
                                                  ),
                                                ),
                                                validator: (v) {
                                                  if (v == null || v.isEmpty) {
                                                    return 'Please enter your password';
                                                  }
                                                  if (v.length < 6) {
                                                    return 'At least 6 characters';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: isLoading
                                                      ? null
                                                      : () {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Ask your school admin to reset your password.'),
                                                            ),
                                                          );
                                                        },
                                                  child: const Text(
                                                      'Forgot password?'),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              AppButton.primary(
                                                label: 'Sign in',
                                                icon: Icons
                                                    .arrow_forward_rounded,
                                                size: AppButtonSize.lg,
                                                fullWidth: true,
                                                loading: isLoading,
                                                onPressed: isLoading
                                                    ? null
                                                    : _submit,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    Center(
                                      child: Text(
                                        'Need help? Contact your school administrator.',
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(String raw) {
    var msg = raw;
    msg = msg.replaceFirst(RegExp(r'^Login failed: '), '');
    msg = msg.replaceFirst(RegExp(r'^Exception: '), '');
    msg = msg.replaceFirst(RegExp(r'^DioException \[[^\]]+\]: '), '');
    if (msg.contains('credentials are incorrect')) {
      return 'Wrong email or password. Try again.';
    }
    if (msg.contains('Account is locked')) {
      return 'Account locked due to too many attempts. Try again later.';
    }
    if (msg.contains('XMLHttpRequest') || msg.contains('Connection')) {
      return "Couldn't reach the server. Check your connection.";
    }
    if (msg.length > 140) msg = '${msg.substring(0, 140)}…';
    return msg;
  }
}

// ── Decorative pieces ─────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: Radii.xlRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 46,
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowBlob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
