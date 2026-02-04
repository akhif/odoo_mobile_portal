import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../data/models/invoice_model.dart';
import '../providers/sales_provider.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    if (_searchQuery.isEmpty) return invoices;

    return invoices.where((invoice) {
      final query = _searchQuery.toLowerCase();
      return invoice.name.toLowerCase().contains(query) ||
          (invoice.partnerName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Invoices'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search invoices...',
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

          // Invoice List
          Expanded(
            child: invoicesAsync.when(
              loading: () => const ListShimmer(),
              error: (error, _) => AppErrorWidget(
                message: 'Failed to load invoices',
                onRetry: () => ref.refresh(invoicesProvider),
              ),
              data: (invoices) {
                final filteredInvoices = _filterInvoices(invoices);

                if (filteredInvoices.isEmpty) {
                  return EmptyStateWidget(
                    title: _searchQuery.isNotEmpty
                        ? 'No Results'
                        : 'No Invoices',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No invoices found for "$_searchQuery"'
                        : 'Customer invoices will appear here',
                    icon: Icons.receipt_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(invoicesProvider);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];

                      return Card(
                        child: InkWell(
                          onTap: () =>
                              context.push('/sales/invoices/${invoice.id}'),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          currencyFormat
                                              .format(invoice.amountTotal),
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (invoice.amountResidual > 0)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Due',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          Text(
                                            currencyFormat
                                                .format(invoice.amountResidual),
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: invoice.isOverdue
                                                  ? AppColors.error
                                                  : AppColors.warning,
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
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
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
          ),
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
