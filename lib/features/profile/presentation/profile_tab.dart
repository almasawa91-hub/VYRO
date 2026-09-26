import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('الملف الشخصي', style: TextStyle(color: AppColors.textSecondary)));
  }
}
