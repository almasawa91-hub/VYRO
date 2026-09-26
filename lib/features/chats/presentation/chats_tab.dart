import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('الدردشات', style: TextStyle(color: AppColors.textSecondary)));
  }
}
