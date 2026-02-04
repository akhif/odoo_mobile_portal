import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/models/invoice_model.dart';
import '../providers/sales_provider.dart';

class CustomerCreditScreen extends ConsumerWidget {
  const CustomerCreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerCreditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Credit'),
      ),
      body: customersAsync.when(
        loading: () => const ListShimmer(),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load customer credits',
          onRetry: () => ref.refresh(customerCreditsProvider),
        ),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No customer credit data available',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(customerCreditsProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: customers.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return _CustomerCreditCard(customer: customer);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomerCreditCard extends StatelessWidget {
  final CustomerCreditModel customer;

  const _CustomerCreditCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final usagePercent = customer.creditLimit > 0
        ? (customer.creditUsed / customer.creditLimit * 100).clamp(0, 100)
        : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              customer.partnerName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // Credit Usage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Limit',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      customer.creditLimit > 0
                          ? currencyFormat.format(customer.creditLimit)
                          : 'No limit',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Outstanding',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      currencyFormat.format(customer.totalDue),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: usagePercent > 80 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (customer.creditLimit > 0) ...[
              SizedBox(height: 12.h),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: usagePercent / 100,
                  minHeight: 8.h,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usagePercent > 80
                        ? AppColors.error
                        : usagePercent > 50
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${usagePercent.toStringAsFixed(0)}% of credit used',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Credit Details
            Row(
              children: [
                Expanded(
                  child: _CreditInfoTile(
                    label: 'Credit Used',
                    value: currencyFormat.format(customer.creditUsed),
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _CreditInfoTile(
                    label: 'Available',
                    value: currencyFormat.format(customer.creditAvailable),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CreditInfoTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
