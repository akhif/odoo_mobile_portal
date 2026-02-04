import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/models/payslip_model.dart';
import '../providers/hr_provider.dart';

class PayslipListScreen extends ConsumerStatefulWidget {
  const PayslipListScreen({super.key});

  @override
  ConsumerState<PayslipListScreen> createState() => _PayslipListScreenState();
}

class _PayslipListScreenState extends ConsumerState<PayslipListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PayslipModel> _filterPayslips(List<PayslipModel> payslips) {
    if (_searchQuery.isEmpty) return payslips;

    return payslips.where((payslip) {
      final query = _searchQuery.toLowerCase();
      return payslip.name.toLowerCase().contains(query) ||
          payslip.displayPeriod.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final payslipsAsync = ref.watch(payslipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslips'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search payslips...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Payslip List
          Expanded(
            child: payslipsAsync.when(
              loading: () => const ListShimmer(),
              error: (error, stack) => AppErrorWidget(
                message: 'Failed to load payslips',
                details: error.toString(),
                onRetry: () => ref.refresh(payslipsProvider),
              ),
              data: (payslips) {
                final filteredPayslips = _filterPayslips(payslips);

                if (filteredPayslips.isEmpty) {
                  return EmptyStateWidget(
                    title: _searchQuery.isNotEmpty ? 'No Results' : 'No Payslips',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No payslips found for "$_searchQuery"'
                        : 'Your payslips will appear here',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(payslipsProvider);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: filteredPayslips.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final payslip = filteredPayslips[index];
                      final currencyFormat = NumberFormat.currency(
                        symbol: '',
                        decimalDigits: 2,
                      );

                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/hr/payslips/${payslip.id}'),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        payslip.name,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: payslip.isDone
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        payslip.stateLabel,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: payslip.isDone
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  payslip.displayPeriod,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Net Wage',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          currencyFormat.format(payslip.netWage),
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
