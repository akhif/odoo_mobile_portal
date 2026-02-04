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
    final dashboardAsync = ref.watch(invoiceDashboardProvider);
    final currentFilter = ref.watch(invoiceFilterProvider);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Invoices'),
      ),
      body: Column(
        children: [
          // Mini Dashboard
          dashboardAsync.when(
            loading: () => Padding(
              padding: EdgeInsets.all(16.w),
              child: const LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (dashboard) => _InvoiceDashboard(
              dashboard: dashboard,
              currencyFormat: currencyFormat,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: currentFilter == null,
                  onTap: () {
                    ref.read(invoiceFilterProvider.notifier).state = null;
                    ref.invalidate(invoicesProvider);
                  },
                ),
                SizedBox(width: 8.w),
                _FilterChip(
                  label: 'Paid',
                  isSelected: currentFilter == 'paid',
                  color: AppColors.success,
                  onTap: () {
                    ref.read(invoiceFilterProvider.notifier).state = 'paid';
                    ref.invalidate(invoicesProvider);
                  },
                ),
                SizedBox(width: 8.w),
                _FilterChip(
                  label: 'Open',
                  isSelected: currentFilter == 'not_paid',
                  color: AppColors.info,
                  onTap: () {
                    ref.read(invoiceFilterProvider.notifier).state = 'not_paid';
                    ref.invalidate(invoicesProvider);
                  },
                ),
                SizedBox(width: 8.w),
                _FilterChip(
                  label: 'Partial',
                  isSelected: currentFilter == 'partial',
                  color: AppColors.warning,
                  onTap: () {
                    ref.read(invoiceFilterProvider.notifier).state = 'partial';
                    ref.invalidate(invoicesProvider);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
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

          SizedBox(height: 8.h),

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
                        : currentFilter != null
                            ? 'No invoices with this filter'
                            : 'Customer invoices will appear here',
                    icon: Icons.receipt_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(invoicesProvider);
                    ref.invalidate(invoiceDashboardProvider);
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

class _InvoiceDashboard extends StatelessWidget {
  final InvoiceDashboard dashboard;
  final NumberFormat currencyFormat;

  const _InvoiceDashboard({
    required this.dashboard,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardItem(
                  label: 'This Month',
                  value: currencyFormat.format(dashboard.monthlyTotal),
                  icon: Icons.calendar_month,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white24,
              ),
              Expanded(
                child: _DashboardItem(
                  label: 'Outstanding',
                  value: currencyFormat.format(dashboard.totalOutstanding),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _DashboardItem(
                  label: 'Overdue',
                  value: currencyFormat.format(dashboard.totalOverdue),
                  icon: Icons.warning_amber,
                  valueColor: dashboard.totalOverdue > 0 ? Colors.red[200] : null,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white24,
              ),
              Expanded(
                child: _DashboardItem(
                  label: 'Overdue Count',
                  value: dashboard.overdueCount.toString(),
                  icon: Icons.receipt_long,
                  valueColor: dashboard.overdueCount > 0 ? Colors.red[200] : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DashboardItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: chipColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : chipColor,
          ),
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
