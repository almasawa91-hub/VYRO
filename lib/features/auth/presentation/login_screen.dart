import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        await _authRepository.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

        await _authRepository.sendEmailVerification();
        await _authRepository.signOut();

        if (!mounted) return;
        setState(() => _isRegister = false);
        _showMessage(
          'تم إنشاء الحساب. افتح بريدك واضغط رابط التحقق، ثم سجل الدخول.',
        );
        return;
      }

      await _authRepository.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final verified =
          await _authRepository.reloadAndCheckEmailVerified();

      if (!verified) {
        await _authRepository.sendEmailVerification();
        await _authRepository.signOut();
        _showError(
          'البريد غير متحقق. أرسلنا لك رابط تحقق جديد إلى بريدك.',
        );
        return;
      }

      await _continueAfterAuth();
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseError(e));
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAfterAuth() async {
    final user = _authRepository.currentUser;

    if (user == null) {
      throw Exception('تعذر الحصول على بيانات المستخدم');
    }

    final profile =
        await _authRepository.getUserProfile(user.uid);

    if (!mounted) return;

    if (profile == null) {
      context.go('/create-profile');
    } else {
      context.go('/home');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('أدخل بريدك الإلكتروني أولاً');
      return;
    }

    try {
      await _authRepository.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك',
      );
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseError(e));
    }
  }

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';

      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';

      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';

      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف أو أكثر';

      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';

      case 'too-many-requests':
        return 'تم إجراء محاولات كثيرة، حاول لاحقاً';

      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بطريقة تسجيل دخول أخرى';

      case 'google-id-token-missing':
        return 'تعذر الحصول على بيانات Google';

      default:
        return e.message ?? 'حدث خطأ أثناء المصادقة';
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 64,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'فايرو',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _isRegister
                            ? 'أنشئ حسابك في فايرو'
                            : 'مرحباً بك في فايرو',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon:
                              Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'أدخل البريد الإلكتروني';
                          }

                          if (!email.contains('@')) {
                            return 'أدخل بريداً إلكترونياً صحيحاً';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon:
                              const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                          border:
                              const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف أو أكثر';
                          }

                          return null;
                        },
                      ),

                      if (!_isRegister)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _resetPassword,
                            child:
                                const Text('نسيت كلمة المرور؟'),
                          ),
                        ),

                      const SizedBox(height: 8),

                      FilledButton(
                        onPressed:
                            _isLoading ? null : _submitEmail,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          child: Text(
                            _isRegister
                                ? 'إنشاء الحساب'
                                : 'تسجيل الدخول',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegister =
                                      !_isRegister;
                                });
                              },
                        child: Text(
                          _isRegister
                              ? 'لديك حساب؟ تسجيل الدخول'
                              : 'ليس لديك حساب؟ إنشاء حساب',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
