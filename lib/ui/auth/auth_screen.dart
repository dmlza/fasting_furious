import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  String _error = '';
  String _success = '';
  bool _loading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(authStateProvider, (prev, next) {
        next.whenData((state) {
          if (state.session?.user != null && mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateUsername(String? value) {
    if (!_isLogin) {
      if (value == null || value.trim().isEmpty) return 'Username is required';
      if (value.trim().length < 3) return 'Username must be at least 3 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = ''; _success = ''; });

    try {
      final service = ref.read(supabaseServiceProvider);
      if (_isLogin) {
        final result = await service.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (result.user == null) {
          setState(() { _error = 'No account found with this email'; _loading = false; });
        } else if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        final result = await service.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          username: _usernameController.text.trim(),
        );
        if (result.user?.identities?.isEmpty ?? true) {
          setState(() { _error = 'An account with this email already exists'; _loading = false; });
          return;
        }
        setState(() {
          _success = 'Account created! You can now sign in.';
          _isLogin = true;
          _loading = false;
          _emailController.clear();
          _passwordController.clear();
          _usernameController.clear();
        });
      }
    } catch (e) {
      String message = e.toString();
      if (message.contains('rate_limit') || message.contains('429')) {
        message = 'Too many attempts. Please wait a few minutes and try again.';
      } else if (message.contains('invalid_login_credentials')) {
        message = 'Invalid email or password.';
      } else if (message.contains('email_address_invalid')) {
        message = 'Please enter a valid email address.';
      } else if (message.contains('over_email_send_rate_limit')) {
        message = 'Email limit reached. Please wait before trying again.';
      }
      setState(() { _error = message; _loading = false; });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _validateEmail(email) != null) {
      setState(() { _error = 'Enter your email above first'; });
      return;
    }
    setState(() { _loading = true; _error = ''; _success = ''; });
    try {
      await ref.read(supabaseServiceProvider).resetPassword(email);
      setState(() {
        _success = 'Password reset link sent to $email';
        _loading = false;
      });
    } catch (e) {
      String message = e.toString();
      if (message.contains('rate_limit') || message.contains('429')) {
        message = 'Too many attempts. Please wait before trying again.';
      }
      setState(() { _error = message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AppColors.purple.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      '\u{1F525} Fasting Furious',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'train hard. fast harder.',
                      style: GoogleFonts.poppins(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (!_isLogin)
                    FadeInDown(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 400),
                      child: TextFormField(
                        controller: _usernameController,
                        enabled: !_loading,
                        validator: _validateUsername,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                  if (!_isLogin) const SizedBox(height: 14),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: _emailController,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeInDown(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: _passwordController,
                      enabled: !_loading,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_success.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_success, style: const TextStyle(color: AppColors.green, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 500),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isLogin ? 'Sign In' : 'Create Account'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : () => setState(() {
                      _isLogin = !_isLogin;
                      _error = '';
                      _success = '';
                    }),
                    child: Text(
                      _isLogin ? "Don't have an account? Sign up" : 'Already have an account? Sign in',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
