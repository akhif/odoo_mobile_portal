import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/sales_provider.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing invoice...')),
              );
            },
          ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const LoadingShimmer(),
        error: (error, _) => AppErrorWidget(
          message: 'Failed to load invoice details',
          onRetry: () => ref.refresh(invoiceDetailProvider(invoiceId)),
        ),
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                invoice.name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
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
                            fontSize: 16.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoItem(
                                label: 'Invoice Date',
                                value: invoice.invoiceDate != null
                                    ? dateFormat.format(invoice.invoiceDate!)
                                    : '-',
                              ),
                            ),
                            Expanded(
                              child: _InfoItem(
                                label: 'Due Date',
                                value: invoice.invoiceDateDue != null
                                    ? dateFormat.format(invoice.invoiceDateDue!)
                                    : '-',
                                valueColor: invoice.isOverdue ? AppColors.error : null,
                              ),
                            ),
                          ],
                        ),
                        if (invoice.currency != null) ...[
                          SizedBox(height: 8.h),
                          _InfoItem(
                            label: 'Currency',
                            value: invoice.currency!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Amount Summary
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        _AmountRow(
                          label: 'Total',
                          amount: currencyFormat.format(invoice.amountTotal),
                          isBold: true,
                        ),
                        const Divider(),
                        _AmountRow(
                          label: 'Paid',
                          amount: currencyFormat.format(invoice.amountPaid),
                          color: AppColors.success,
                        ),
                        const Divider(),
                        _AmountRow(
                          label: 'Amount Due',
                          amount: currencyFormat.format(invoice.amountResidual),
                          isBold: true,
                          color: invoice.amountResidual > 0
                              ? (invoice.isOverdue ? AppColors.error : AppColors.warning)
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),

                // Invoice Lines (Products)
                if (invoice.lines.isNotEmpty) ...[
                  SizedBox(height: 24.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ...invoice.lines.map((line) => _InvoiceLineItem(
                            line: line,
                            currencyFormat: currencyFormat,
                          )),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

                // Invoice State Info
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Information',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoItem(
                                label: 'Invoice State',
                                value: invoice.stateLabel,
                              ),
                            ),
                            Expanded(
                              child: _InfoItem(
                                label: 'Payment State',
                                value: invoice.paymentStateLabel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceLineItem extends StatelessWidget {
  final dynamic line;
  final NumberFormat currencyFormat;

  const _InvoiceLineItem({required this.line, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.productName ?? line.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${line.quantity.toStringAsFixed(2)} x ${currencyFormat.format(line.priceUnit)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                currencyFormat.format(line.priceSubtotal),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (line.discount > 0) ...[
            SizedBox(height: 2.h),
            Text(
              'Discount: ${line.discount.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.success,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          const Divider(height: 1),
        ],
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isBold;
  final Color? color;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
