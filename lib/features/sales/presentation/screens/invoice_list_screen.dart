import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/sales_provider.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Invoices'),
      ),
      body: invoicesAsync.when(
        loading: () => const ListShimmer(),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load invoices',
          onRetry: () => ref.refresh(invoicesProvider),
        ),
        data: (invoices) {
          if (invoices.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Invoices',
              subtitle: 'Customer invoices will appear here',
              icon: Icons.receipt_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(invoicesProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final invoice = invoices[index];

                return Card(
                  child: InkWell(
                    onTap: () => context.push('/sales/invoices/${invoice.id}'),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                invoice.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _PaymentStatusBadge(
                                state: invoice.paymentState,
                                isOverdue: invoice.isOverdue,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            invoice.partnerName ?? 'Unknown Customer',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(invoice.amountTotal),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (invoice.amountResidual > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Due',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(invoice.amountResidual),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: invoice.isOverdue ? AppColors.error : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (invoice.invoiceDateDue != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              'Due: ${dateFormat.format(invoice.invoiceDateDue!)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: invoice.isOverdue
                                    ? AppColors.error
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
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
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String state;
  final bool isOverdue;

  const _PaymentStatusBadge({required this.state, this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (isOverdue) {
      color = AppColors.error;
      label = 'Overdue';
    } else {
      switch (state) {
        case 'paid':
          color = AppColors.success;
          label = 'Paid';
          break;
        case 'partial':
          color = AppColors.warning;
          label = 'Partial';
          break;
        case 'not_paid':
          color = AppColors.info;
          label = 'Open';
          break;
        case 'in_payment':
          color = AppColors.info;
          label = 'In Payment';
          break;
        default:
          color = AppColors.textSecondary;
          label = state;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
