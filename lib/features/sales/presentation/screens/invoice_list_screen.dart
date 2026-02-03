import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    // Simulated data - replace with actual Odoo API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _invoices = [
        {
          'id': 1,
          'name': 'INV/2024/0001',
          'partner_name': 'ABC Company',
          'amount_total': 5000.00,
          'amount_residual': 2500.00,
          'invoice_date': DateTime.now().subtract(const Duration(days: 30)),
          'invoice_date_due': DateTime.now().subtract(const Duration(days: 15)),
          'state': 'posted',
          'payment_state': 'partial',
        },
        {
          'id': 2,
          'name': 'INV/2024/0002',
          'partner_name': 'XYZ Trading',
          'amount_total': 3500.00,
          'amount_residual': 0.00,
          'invoice_date': DateTime.now().subtract(const Duration(days: 20)),
          'invoice_date_due': DateTime.now().add(const Duration(days: 10)),
          'state': 'posted',
          'payment_state': 'paid',
        },
        {
          'id': 3,
          'name': 'INV/2024/0003',
          'partner_name': 'Global Supplies',
          'amount_total': 8000.00,
          'amount_residual': 8000.00,
          'invoice_date': DateTime.now().subtract(const Duration(days: 60)),
          'invoice_date_due': DateTime.now().subtract(const Duration(days: 30)),
          'state': 'posted',
          'payment_state': 'not_paid',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Invoices'),
      ),
      body: _isLoading
          ? const ListShimmer()
          : _invoices.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Invoices',
                  subtitle: 'Customer invoices will appear here',
                  icon: Icons.receipt_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      final isOverdue = invoice['payment_state'] == 'not_paid' &&
                          (invoice['invoice_date_due'] as DateTime).isBefore(DateTime.now());

                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/sales/invoices/${invoice['id']}'),
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
                                      invoice['name'],
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    _PaymentStatusBadge(
                                      state: invoice['payment_state'],
                                      isOverdue: isOverdue,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  invoice['partner_name'],
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
                                          currencyFormat.format(invoice['amount_total']),
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (invoice['amount_residual'] > 0)
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
                                            currencyFormat.format(invoice['amount_residual']),
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: isOverdue ? AppColors.error : AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Due: ${dateFormat.format(invoice['invoice_date_due'])}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
