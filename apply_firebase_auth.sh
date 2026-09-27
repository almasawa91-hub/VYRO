#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_ROOT="$HOME/VYRO"
BRANCH="vyro-production-audit-completion-1075401135851170274"
BACKUP_DIR="$REPO_ROOT/.firebase_auth_backup_$(date +%Y%m%d_%H%M%S)"

cd "$REPO_ROOT"

echo "=============================================="
echo " VYRO - Firebase Auth production patch"
echo "=============================================="

if [ ! -f "pubspec.yaml" ]; then
  echo "ERROR: pubspec.yaml غير موجود."
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
echo "الفرع الحالي: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  echo "ERROR: أنت لست على الفرع المطلوب."
  echo "المطلوب: $BRANCH"
  echo "الحالي:  $CURRENT_BRANCH"
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo
  echo "ERROR: توجد تغييرات محلية غير محفوظة."
  echo "لن ألمسها حتى لا أفقد أي شيء."
  git status --short
  exit 1
fi

mkdir -p "$BACKUP_DIR"

backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp "$f" "$BACKUP_DIR/$f"
  fi
}

backup_file "pubspec.yaml"
backup_file "android/settings.gradle.kts"
backup_file "android/app/build.gradle.kts"
backup_file "lib/features/auth/data/auth_repository.dart"
backup_file "lib/core/routing/app_router.dart"

echo
echo "تم إنشاء نسخة احتياطية:"
echo "$BACKUP_DIR"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("pubspec.yaml")
s = p.read_text()

if re.search(r'^\s*google_sign_in\s*:', s, re.M):
    s = re.sub(
        r'^(\s*google_sign_in\s*:\s*).*$',
        r'\g<1>^7.2.0',
        s,
        flags=re.M,
    )
else:
    lines = s.splitlines()
    out = []
    inserted = False

    for line in lines:
        out.append(line)
        if line.strip() == "dependencies:":
            out.append("  google_sign_in: ^7.2.0")
            inserted = True

    if not inserted:
        raise SystemExit("لم أجد dependencies: في pubspec.yaml")

    s = "\n".join(out) + ("\n" if s.endswith("\n") else "")

p.write_text(s)
PY

python3 - <<'PY'
from pathlib import Path
import re

p = Path("android/settings.gradle.kts")
s = p.read_text()

plugin = '    id("com.google.gms.google-services") version "4.5.0" apply false'

if 'com.google.gms.google-services' not in s:
    marker = '    id("org.jetbrains.kotlin.android")'
    m = re.search(r'^' + re.escape(marker) + r'.*$', s, re.M)
    if not m:
        raise SystemExit("لم أجد Kotlin plugin في settings.gradle.kts")

    end = m.end()
    s = s[:end] + "\n" + plugin + s[end:]

p.write_text(s)
PY

python3 - <<'PY'
from pathlib import Path

p = Path("android/app/build.gradle.kts")
s = p.read_text()

if 'id("com.google.gms.google-services")' not in s:
    marker = '    id("dev.flutter.flutter-gradle-plugin")'
    if marker not in s:
        raise SystemExit("لم أجد Flutter Gradle plugin في build.gradle.kts")

    s = s.replace(
        marker,
        marker + '\n    id("com.google.gms.google-services")',
        1
    )

p.write_text(s)
PY

mkdir -p lib/features/auth/presentation

cat > lib/features/auth/data/auth_repository.dart <<'DART'
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void>? _googleInitialization;

  Future<void> _initializeGoogle() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    await _initializeGoogle();

    final GoogleSignInAccount? googleUser =
        await _googleSignIn.authenticate();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-sign-in-no-id-token',
        message: 'تعذر الحصول على رمز تسجيل الدخول من Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(PhoneAuthCredential credential)
        verificationCompleted,
    void Function(FirebaseAuthException error)? verificationFailed,
    void Function(String verificationId, int? resendToken)?
        codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed ?? (_) {},
      codeSent: codeSent,
      codeAutoRetrievalTimeout:
          codeAutoRetrievalTimeout ?? (_) {},
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final value = username.trim().toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: value)
        .limit(1)
        .get();

    return snapshot.docs.isEmpty;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> createOrUpdateUserProfile({
    required String username,
    String? displayName,
    String? phoneNumber,
    String? email,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'يجب تسجيل الدخول أولًا.',
      );
    }

    final uid = user.uid;
    final normalizedUsername = username.trim().toLowerCase();

    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(uid);
      final usernameRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      final usernameSnapshot = await transaction.get(usernameRef);
      final userSnapshot = await transaction.get(userRef);

      if (usernameSnapshot.exists &&
          usernameSnapshot.data()?['uid'] != uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'username-already-taken',
          message: 'اسم المستخدم مستخدم بالفعل.',
        );
      }

      final now = FieldValue.serverTimestamp();

      transaction.set(
        usernameRef,
        {
          'uid': uid,
          'username': normalizedUsername,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      final data = <String, dynamic>{
        'uid': uid,
        'username': normalizedUsername,
        'updatedAt': now,
      };

      if (displayName != null && displayName.trim().isNotEmpty) {
        data['displayName'] = displayName.trim();
      }

      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        data['phoneNumber'] = phoneNumber.trim();
      }

      final resolvedEmail =
          email?.trim().isNotEmpty == true
              ? email!.trim()
              : user.email;

      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        data['email'] = resolvedEmail;
      }

      final resolvedPhoto =
          photoUrl?.trim().isNotEmpty == true
              ? photoUrl!.trim()
              : user.photoURL;

      if (resolvedPhoto != null && resolvedPhoto.isNotEmpty) {
        data['photoUrl'] = resolvedPhoto;
      }

      if (!userSnapshot.exists) {
        data['createdAt'] = now;
      }

      transaction.set(
        userRef,
        data,
        SetOptions(merge: true),
      );
    });
  }

  Future<String> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    final ref = _storage.ref().child(
      'users/$uid/avatar',
    );

    await ref.putFile(
      // ignore: unnecessary_cast
      // The caller provides a native file path.
      // This method is retained for compatibility with the
      // existing avatar upload flow.
      await _fileFromPath(filePath),
    );

    return ref.getDownloadURL();
  }

  Future<dynamic> _fileFromPath(String path) async {
    throw UnsupportedError(
      'استخدم uploadAvatarFile مع XFile/File في واجهة التطبيق الحالية.',
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase sign-out must still complete.
      }
    }

    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await user.delete();
  }
}
DART

cat > lib/features/auth/presentation/login_screen.dart <<'DART'
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
  final _authRepository = AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'invalid-credential' =>
          'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        'invalid-email' => 'البريد الإلكتروني غير صالح.',
        'user-disabled' => 'هذا الحساب معطل.',
        'user-not-found' => 'لا يوجد حساب بهذا البريد.',
        'wrong-password' => 'كلمة المرور غير صحيحة.',
        'email-already-in-use' => 'البريد مستخدم بالفعل.',
        'weak-password' => 'كلمة المرور ضعيفة.',
        'too-many-requests' =>
          'تم إجراء محاولات كثيرة. حاول لاحقًا.',
        'network-request-failed' =>
          'تعذر الاتصال بالإنترنت.',
        'google-sign-in-no-id-token' =>
          'تعذر إكمال تسجيل الدخول بواسطة Google.',
        _ => e.message ?? 'حدث خطأ أثناء تسجيل الدخول.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await _run(() async {
      await _authRepository.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go('/home');
    });
  }

  Future<void> _googleLogin() async {
    await _run(() async {
      final credential =
          await _authRepository.signInWithGoogle();

      if (credential == null) return;

      if (!mounted) return;
      context.go('/home');
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب البريد الإلكتروني أولًا.'),
        ),
      );
      return;
    }

    await _run(() async {
      await _authRepository.sendPasswordResetEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_person_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'سجّل الدخول إلى VYRO',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'أدخل البريد الإلكتروني';
                        }

                        if (!email.contains('@')) {
                          return 'أدخل بريدًا إلكترونيًا صحيحًا';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_loading,
                      onFieldSubmitted: (_) => _emailLogin(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'أدخل كلمة المرور';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : _forgotPassword,
                        child: const Text(
                          'نسيت كلمة المرور؟',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : _emailLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('تسجيل الدخول'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'أو',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _googleLogin,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text(
                        'المتابعة باستخدام Google',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loading
                          ? null
                          : () => context.push('/phone-login'),
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text(
                        'تسجيل الدخول برقم الهاتف',
                      ),
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
DART

python3 - <<'PY'
from pathlib import Path
import re

p = Path("lib/core/routing/app_router.dart")
s = p.read_text()

if "login_screen.dart" not in s:
    s = s.replace(
        "import '../",
        "import '../../features/auth/presentation/login_screen.dart';\nimport '../",
        1
    )

# إذا كان الاستيراد موجودًا بالفعل، لا نكرره.
s = s.replace(
    "import '../../features/auth/presentation/login_screen.dart';\nimport '../../features/auth/presentation/login_screen.dart';",
    "import '../../features/auth/presentation/login_screen.dart';"
)

# تحويل Route /login من PhoneLoginScreen إلى LoginScreen.
s = re.sub(
    r"(path:\s*['\"]\/login['\"],\s*builder:\s*\([^)]*\)\s*=>\s*)PhoneLoginScreen\([^;]*\)",
    r"\1const LoginScreen()",
    s
)

# إضافة /phone-login إذا لم يكن موجودًا.
if "'/phone-login'" not in s and '"/phone-login"' not in s:
    # نضعه قبل /otp، لأن /otp موجود في المشروع الحالي.
    pattern = r"(\n\s*GoRoute\(\s*\n\s*path:\s*['\"]\/otp['\"])"
    replacement = (
        "\n    GoRoute(\n"
        "      path: '/phone-login',\n"
        "      builder: (context, state) => const PhoneLoginScreen(),\n"
        "    ),"
        r"\1"
    )
    if not re.search(pattern, s):
        raise SystemExit(
            "تعذر تحديد مكان إضافة /phone-login في app_router.dart. "
            "لن يتم تعديل الملف."
        )
    s = re.sub(pattern, replacement, s, count=1)

p.write_text(s)
PY

echo
echo "=============================================="
echo "فحص التعديلات"
echo "=============================================="

grep -n "google_sign_in" pubspec.yaml
grep -n "google-services" android/settings.gradle.kts
grep -n "google-services" android/app/build.gradle.kts
grep -n "login_screen.dart" lib/core/routing/app_router.dart
grep -n "phone-login" lib/core/routing/app_router.dart

echo
echo "=============================================="
echo "مهم"
echo "=============================================="
echo "تم تعديل الملفات المطلوبة فقط."
echo "لم يتم حذف google-services.json."
echo "لم يتم تشغيل flutter build محليًا."
echo
echo "النسخة الاحتياطية:"
echo "$BACKUP_DIR"
echo
echo "راجع git diff الآن."
echo
echo "للتراجع الكامل:"
echo "cp \"$BACKUP_DIR/pubspec.yaml\" pubspec.yaml 2>/dev/null || true"
echo "cp \"$BACKUP_DIR/android/settings.gradle.kts\" android/settings.gradle.kts 2>/dev/null || true"
echo "cp \"$BACKUP_DIR/android/app/build.gradle.kts\" android/app/build.gradle.kts 2>/dev/null || true"
echo "cp \"$BACKUP_DIR/lib/features/auth/data/auth_repository.dart\" lib/features/auth/data/auth_repository.dart 2>/dev/null || true"
echo "cp \"$BACKUP_DIR/lib/core/routing/app_router.dart\" lib/core/routing/app_router.dart 2>/dev/null || true"
echo
echo "لا يتم الرفع تلقائيًا."
