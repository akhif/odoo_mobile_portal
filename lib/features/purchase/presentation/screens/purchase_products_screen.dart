import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/purchase_provider.dart';

class PurchaseProductsScreen extends ConsumerStatefulWidget {
  const PurchaseProductsScreen({super.key});

  @override
  ConsumerState<PurchaseProductsScreen> createState() =>
      _PurchaseProductsScreenState();
}

class _PurchaseProductsScreenState
    extends ConsumerState<PurchaseProductsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = _searchQuery.isNotEmpty
        ? ref.watch(purchaseProductsSearchProvider(_searchQuery))
        : ref.watch(purchaseProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
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

          // Product List
          Expanded(
            child: productsAsync.when(
              loading: () => const ListShimmer(),
              error: (error, _) => AppErrorWidget(
                message: 'Failed to load products',
                onRetry: () {
                  if (_searchQuery.isNotEmpty) {
                    ref.refresh(purchaseProductsSearchProvider(_searchQuery));
                  } else {
                    ref.refresh(purchaseProductsProvider);
                  }
                },
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No products found for "$_searchQuery"'
                              : 'No products available',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (_searchQuery.isNotEmpty) {
                      ref.refresh(purchaseProductsSearchProvider(_searchQuery));
                    } else {
                      ref.refresh(purchaseProductsProvider);
                    }
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _PurchaseProductCard(product: product);
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

class _PurchaseProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _PurchaseProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final costPrice =
        (product['standard_price'] as num?)?.toDouble() ?? 0.0;
    final qtyAvailable =
        (product['qty_available'] as num?)?.toDouble() ?? 0.0;
    final suppliers =
        product['suppliers'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name & Code
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']?.toString() ?? 'Unknown Product',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product['default_code'] != null &&
                          product['default_code'] != false) ...[
                        SizedBox(height: 4.h),
                        Text(
                          product['default_code'].toString(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '${qtyAvailable.toStringAsFixed(0)} in stock',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Cost Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Price',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                Text(
                  currencyFormat.format(costPrice),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),

            // Suppliers
            if (suppliers.isNotEmpty) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 8.h),
              Text(
                'Suppliers',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              ...suppliers.map((supplier) {
                final partnerName = supplier['partner_id'] is List
                    ? (supplier['partner_id'] as List).length > 1
                        ? supplier['partner_id'][1].toString()
                        : 'Unknown'
                    : 'Unknown';
                final price =
                    (supplier['price'] as num?)?.toDouble() ?? 0.0;
                final minQty =
                    (supplier['min_qty'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16.sp,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          partnerName,
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(price),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (minQty > 0)
                            Text(
                              'Min: ${minQty.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
