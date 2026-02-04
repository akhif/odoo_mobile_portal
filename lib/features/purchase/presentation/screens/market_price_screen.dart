import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/purchase_provider.dart';

class MarketPriceScreen extends ConsumerStatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  ConsumerState<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends ConsumerState<MarketPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedProductId;
  String? _selectedProductName;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _recentEntries = [];

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitPrice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Submit Market Price',
      message: 'Are you sure you want to record this market price?',
      confirmText: 'Submit',
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Try to create market price entry in Odoo
      final result = await ref.read(purchaseRepositoryProvider).createMarketPriceEntry(
        productId: _selectedProductId!,
        price: double.parse(_priceController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      setState(() {
        _isSubmitting = false;
        _recentEntries.insert(0, {
          'product': _selectedProductName ?? 'Unknown Product',
          'price': double.parse(_priceController.text),
          'date': _selectedDate,
          'notes': _notesController.text,
          'saved': result != null,
        });

        // Reset form
        _selectedProductId = null;
        _selectedProductName = null;
        _priceController.clear();
        _notesController.clear();
        _selectedDate = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result != null
              ? 'Market price recorded successfully'
              : 'Market price recorded locally (server sync pending)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record price: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(purchaseProductsProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Price Entry'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Selection
              Text(
                'Product',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              productsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Failed to load products',
                          style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(purchaseProductsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'No products available',
                        style: TextStyle(color: AppColors.warning, fontSize: 14.sp),
                      ),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: const InputDecoration(
                      hintText: 'Select product',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    isExpanded: true,
                    items: products.map((product) {
                      final id = product['id'] as int;
                      final name = product['name']?.toString() ?? 'Unknown';
                      final code = product['default_code'];
                      final displayName = code != null && code != false
                          ? '$name ($code)'
                          : name;
                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                        if (value != null) {
                          final product = products.firstWhere((p) => p['id'] == value);
                          _selectedProductName = product['name']?.toString();
                        }
                      });
                    },
                  );
                },
              ),

              SizedBox(height: 20.h),

              // Price Input
              Text(
                'Market Price',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Enter current market price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than zero';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20.h),

              // Date Selection
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),

              SizedBox(height: 20.h),

              // Notes
              Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter any additional notes',
                ),
              ),

              SizedBox(height: 24.h),

              // Submit Button
              AppButton(
                text: 'Record Market Price',
                isLoading: _isSubmitting,
                isFullWidth: true,
                onPressed: _submitPrice,
              ),

              // Recent Entries
              if (_recentEntries.isNotEmpty) ...[
                SizedBox(height: 32.h),
                Text(
                  'Recent Entries (This Session)',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentEntries.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final entry = _recentEntries[index];
                    final saved = entry['saved'] as bool? ?? false;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (saved ? AppColors.success : AppColors.warning).withOpacity(0.1),
                          child: Icon(
                            saved ? Icons.check : Icons.cloud_off,
                            color: saved ? AppColors.success : AppColors.warning,
                            size: 20.sp,
                          ),
                        ),
                        title: Text(entry['product']),
                        subtitle: Text(dateFormat.format(entry['date'])),
                        trailing: Text(
                          currencyFormat.format(entry['price']),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
