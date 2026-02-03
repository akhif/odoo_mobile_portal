import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedProductId;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _products = [
    {'id': 1, 'name': 'Raw Material A', 'default_code': 'RM-A-001'},
    {'id': 2, 'name': 'Raw Material B', 'default_code': 'RM-B-001'},
    {'id': 3, 'name': 'Component X', 'default_code': 'COMP-X-001'},
    {'id': 4, 'name': 'Component Y', 'default_code': 'COMP-Y-001'},
  ];

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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final product = _products.firstWhere((p) => p['id'] == _selectedProductId);

    setState(() {
      _isSubmitting = false;
      _recentEntries.insert(0, {
        'product': product['name'],
        'price': double.parse(_priceController.text),
        'date': _selectedDate,
        'notes': _notesController.text,
      });

      // Reset form
      _selectedProductId = null;
      _priceController.clear();
      _notesController.clear();
      _selectedDate = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Market price recorded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  hintText: 'Select product',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: _products.map((product) {
                  return DropdownMenuItem(
                    value: product['id'] as int,
                    child: Text('${product['name']} (${product['default_code']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProductId = value;
                  });
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
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.success.withOpacity(0.1),
                          child: Icon(
                            Icons.check,
                            color: AppColors.success,
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
