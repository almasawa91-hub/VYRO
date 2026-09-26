import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../data/auth_repository.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _authRepo = AuthRepository();

  File? _avatarFile;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<void> _validateAndSubmit() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة الاسم الكامل')),
      );
      return;
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'اسم المستخدم يجب أن يتكون من 3 أحرف على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final available = await _authRepo.isUsernameAvailable(username);
      setState(() => _isCheckingUsername = false);

      if (!available) {
        setState(() {
          _isLoading = false;
          _usernameError = 'اسم المستخدم هذا مستخدم بالفعل، يرجى اختيار اسم آخر';
        });
        return;
      }

      await _authRepo.createProfile(
        displayName: name,
        username: username,
        bio: bio,
        avatarFile: _avatarFile,
      );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في إنشاء الملف الشخصي: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء الملف الشخصي'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                        child: _avatarFile == null
                            ? const Icon(Icons.person_outline, size: 50, color: AppColors.textSecondary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  hintText: 'مثال: محمد علي',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم (Unique Username)',
                  hintText: 'مثال: mohammed_vyro',
                  errorText: _usernameError,
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'السيرة الذاتية (Bio)',
                  hintText: 'اكتب نبذة قصيرة عن نفسك...',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _validateAndSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('حفظ والانتقال للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
