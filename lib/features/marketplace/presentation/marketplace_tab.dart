import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MarketplaceTab extends StatelessWidget {
  const MarketplaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('السوق', style: TextStyle(color: AppColors.textSecondary)));
  }
}
