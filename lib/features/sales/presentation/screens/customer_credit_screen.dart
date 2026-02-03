import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_shimmer.dart';

class CustomerCreditScreen extends StatefulWidget {
  const CustomerCreditScreen({super.key});

  @override
  State<CustomerCreditScreen> createState() => _CustomerCreditScreenState();
}

class _CustomerCreditScreenState extends State<CustomerCreditScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _customers = [
        {
          'id': 1,
          'name': 'ABC Company Ltd.',
          'credit_limit': 50000.00,
          'total_due': 15000.00,
          'aging_0_30': 5000.00,
          'aging_31_60': 3000.00,
          'aging_61_90': 4000.00,
          'aging_90_plus': 3000.00,
        },
        {
          'id': 2,
          'name': 'XYZ Trading',
          'credit_limit': 30000.00,
          'total_due': 8500.00,
          'aging_0_30': 8500.00,
          'aging_31_60': 0.00,
          'aging_61_90': 0.00,
          'aging_90_plus': 0.00,
        },
        {
          'id': 3,
          'name': 'Global Supplies',
          'credit_limit': 75000.00,
          'total_due': 45000.00,
          'aging_0_30': 10000.00,
          'aging_31_60': 15000.00,
          'aging_61_90': 12000.00,
          'aging_90_plus': 8000.00,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Credit'),
      ),
      body: _isLoading
          ? const ListShimmer()
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _customers.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return _CustomerCreditCard(customer: customer);
                },
              ),
            ),
    );
  }
}

class _CustomerCreditCard extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _CustomerCreditCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final creditLimit = customer['credit_limit'] as double;
    final totalDue = customer['total_due'] as double;
    final usagePercent = (totalDue / creditLimit * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              customer['name'],
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
                      currencyFormat.format(creditLimit),
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
                      currencyFormat.format(totalDue),
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

            SizedBox(height: 16.h),

            // Aging Table
            Text(
              'Aging Analysis',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _AgingCell(
                  label: '0-30',
                  amount: customer['aging_0_30'],
                  color: AppColors.success,
                ),
                _AgingCell(
                  label: '31-60',
                  amount: customer['aging_31_60'],
                  color: AppColors.info,
                ),
                _AgingCell(
                  label: '61-90',
                  amount: customer['aging_61_90'],
                  color: AppColors.warning,
                ),
                _AgingCell(
                  label: '90+',
                  amount: customer['aging_90_plus'],
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AgingCell({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.w),
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
