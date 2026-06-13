import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brutal_button.dart';
import '../../widgets/brutal_card.dart';
import '../../widgets/brutal_input.dart';
import '../home/home_screen.dart';

/// Kayıt ekranı
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isValidatingCode = false;
  bool? _isCodeValid;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inviteCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Davet kodunu doğrula (debounce ile)
  void _onInviteCodeChanged(String value) {
    _debounceTimer?.cancel();

    if (value.length == 8) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _validateInviteCode(value);
      });
    } else {
      setState(() => _isCodeValid = null);
    }
  }

  Future<void> _validateInviteCode(String code) async {
    setState(() => _isValidatingCode = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.validateInvite(code);

    if (!mounted) return;

    setState(() {
      _isValidatingCode = false;
      _isCodeValid = result.valid;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCodeValid != true) {
      _showError('Geçerli bir davet kodu girin');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      inviteCode: _inviteCodeController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showError(authProvider.error ?? 'Kayıt başarısız');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInviteCodeSuffix() {
    if (_isValidatingCode) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_isCodeValid == true) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
      );
    }

    if (_isCodeValid == false) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.cancel, color: AppColors.error, size: 20),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: BrutalCard(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Başlık
                    const Text(
                      'JOIN CORDIT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Invite code required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Invite Code
                    BrutalInput(
                      label: 'INVITE CODE',
                      hint: 'A1B2C3D4',
                      controller: _inviteCodeController,
                      enabled: !isLoading,
                      onChanged: _onInviteCodeChanged,
                      suffixIcon: _buildInviteCodeSuffix(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Davet kodu gerekli';
                        }
                        if (value.length != 8) {
                          return 'Davet kodu 8 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Username
                    BrutalInput(
                      label: 'USERNAME',
                      hint: 'cooluser',
                      controller: _usernameController,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kullanıcı adı gerekli';
                        }
                        if (value.length < 3) {
                          return 'En az 3 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    BrutalInput(
                      label: 'PASSWORD',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        if (value.length < 6) {
                          return 'En az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Register Button
                    BrutalButton(
                      text: 'REGISTER',
                      backgroundColor: AppColors.grey,
                      onPressed: isLoading || _isCodeValid != true
                          ? null
                          : _register,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Container(
                      height: BrutalStyle.borderWidth,
                      color: AppColors.black,
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'LOGIN HERE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
