import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/hr_provider.dart';

class PayslipDetailScreen extends ConsumerWidget {
  final int payslipId;

  const PayslipDetailScreen({
    super.key,
    required this.payslipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipAsync = ref.watch(payslipDetailProvider(payslipId));
    final linesAsync = ref.watch(payslipLinesProvider(payslipId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading PDF...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing to share...')),
              );
            },
          ),
        ],
      ),
      body: payslipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorWidget(
          message: 'Failed to load payslip',
          onRetry: () => ref.refresh(payslipDetailProvider(payslipId)),
        ),
        data: (payslip) {
          if (payslip == null) {
            return const EmptyStateWidget(
              title: 'Payslip Not Found',
              icon: Icons.error_outline,
            );
          }

          final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payslip.name,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          payslip.displayPeriod,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                title: 'Gross Wage',
                                value: currencyFormat.format(payslip.grossWage),
                                color: AppColors.info,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _InfoCard(
                                title: 'Net Wage',
                                value: currencyFormat.format(payslip.netWage),
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Payslip Lines
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),

                linesAsync.when(
                  loading: () => const ListShimmer(itemCount: 5, showLeading: false),
                  error: (error, stack) => Text('Failed to load details: $error'),
                  data: (lines) {
                    if (lines.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No line items'),
                        ),
                      );
                    }

                    // Group lines by category
                    final grouped = <String, List<dynamic>>{};
                    for (final line in lines) {
                      final category = line.categoryName ?? 'Other';
                      grouped.putIfAbsent(category, () => []).add(line);
                    }

                    return Card(
                      child: Column(
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...entry.value.map((line) => ListTile(
                                    title: Text(
                                      line.name,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    trailing: Text(
                                      currencyFormat.format(line.total),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: line.total >= 0
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.title,
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
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
