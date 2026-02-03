import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/module_tile.dart';

class SalesHomeScreen extends StatelessWidget {
  const SalesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MenuListTile(
            title: 'Customer Invoices',
            subtitle: 'View and track invoices',
            icon: Icons.receipt_outlined,
            iconColor: AppColors.primary,
            onTap: () => context.push('/sales/invoices'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Customer Credit',
            subtitle: 'Credit limits and aging',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.info,
            onTap: () => context.push('/sales/credit'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Product Info',
            subtitle: 'Prices and availability',
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.secondary,
            onTap: () => context.push('/sales/products'),
          ),
        ],
      ),
    );
  }
}
