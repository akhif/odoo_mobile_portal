import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_shimmer.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _supplier;
  List<Map<String, dynamic>> _purchaseHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSupplierData();
  }

  Future<void> _loadSupplierData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _supplier = {
        'id': widget.supplierId,
        'name': 'ABC Supplies Co.',
        'phone': '+966 12 345 6789',
        'email': 'info@abcsupplies.com',
        'street': '123 Industrial Area',
        'city': 'Riyadh',
        'country': 'Saudi Arabia',
      };
      _purchaseHistory = [
        {
          'product': 'Raw Material A',
          'last_price': 45.00,
          'last_date': DateTime.now().subtract(const Duration(days: 7)),
          'qty': 100,
        },
        {
          'product': 'Raw Material B',
          'last_price': 120.00,
          'last_date': DateTime.now().subtract(const Duration(days: 15)),
          'qty': 50,
        },
        {
          'product': 'Component X',
          'last_price': 85.50,
          'last_date': DateTime.now().subtract(const Duration(days: 30)),
          'qty': 200,
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
        title: const Text('Supplier Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Info Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30.r,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  _supplier!['name'].toString().substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _supplier!['name'],
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${_supplier!['city']}, ${_supplier!['country']}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          const Divider(),
                          SizedBox(height: 8.h),
                          _ContactRow(
                            icon: Icons.phone_outlined,
                            label: _supplier!['phone'],
                          ),
                          SizedBox(height: 8.h),
                          _ContactRow(
                            icon: Icons.email_outlined,
                            label: _supplier!['email'],
                          ),
                          SizedBox(height: 8.h),
                          _ContactRow(
                            icon: Icons.location_on_outlined,
                            label: _supplier!['street'],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Purchase History
                  Text(
                    'Last Purchase Prices',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _purchaseHistory.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final item = _purchaseHistory[index];
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product'],
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Qty: ${item['qty']} | ${dateFormat.format(item['last_date'])}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Last Price',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(item['last_price']),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }
}
