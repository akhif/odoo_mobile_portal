import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/module_tile.dart';

class PurchaseHomeScreen extends StatelessWidget {
  const PurchaseHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MenuListTile(
            title: 'Products',
            subtitle: 'View products with cost prices and suppliers',
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            onTap: () => context.push('/purchase/products'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Suppliers',
            subtitle: 'View supplier details and prices',
            icon: Icons.business_outlined,
            iconColor: AppColors.secondary,
            onTap: () => context.push('/purchase/suppliers'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Market Price Entry',
            subtitle: 'Record current market prices',
            icon: Icons.trending_up,
            iconColor: AppColors.warning,
            onTap: () => context.push('/purchase/market-price'),
          ),
        ],
      ),
    );
  }
}
