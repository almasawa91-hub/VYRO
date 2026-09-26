import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('الرئيسية', style: TextStyle(color: AppColors.textSecondary)));
  }
}
