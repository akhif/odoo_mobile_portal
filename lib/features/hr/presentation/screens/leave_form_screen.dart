import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../providers/hr_provider.dart';

class LeaveFormScreen extends ConsumerStatefulWidget {
  final bool isVacation;

  const LeaveFormScreen({
    super.key,
    this.isVacation = false,
  });

  @override
  ConsumerState<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends ConsumerState<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  int? _selectedLeaveTypeId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    DateTime firstDate;
    DateTime initialDate;

    if (isFrom) {
      // For "from date", allow selecting from today onwards
      firstDate = now;
      initialDate = _dateFrom ?? now;
    } else {
      // For "to date", allow selecting from the start date (or today if not set)
      firstDate = _dateFrom ?? now;
      // Make sure initialDate is not before firstDate
      if (_dateTo != null && !_dateTo!.isBefore(firstDate)) {
        initialDate = _dateTo!;
      } else {
        initialDate = firstDate;
      }
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = pickedDate;
          // Reset end date if it's now before start date
          if (_dateTo != null && _dateTo!.isBefore(_dateFrom!)) {
            _dateTo = _dateFrom;
          }
        } else {
          _dateTo = pickedDate;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }

    if (_dateFrom == null || _dateTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Submit Request',
      message: 'Are you sure you want to submit this ${widget.isVacation ? 'vacation' : 'leave'} request?',
      confirmText: 'Submit',
    );

    if (confirmed != true) return;

    final success = await ref.read(leaveRequestNotifierProvider.notifier).createLeaveRequest(
          holidayStatusId: _selectedLeaveTypeId!,
          dateFrom: _dateFrom!,
          dateTo: _dateTo!,
          notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.refresh(leaveRequestsProvider);
      context.pop();
    } else if (mounted) {
      final state = ref.read(leaveRequestNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to submit request'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveTypesAsync = ref.watch(leaveTypesProvider);
    final requestState = ref.watch(leaveRequestNotifierProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVacation ? 'New Vacation Request' : 'New Leave Request'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Leave Type
            Text(
              'Leave Type',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            leaveTypesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) {
                final errorStr = error.toString().toLowerCase();
                if (errorStr.contains('access') || errorStr.contains('not allowed')) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Leave types are not accessible. Please contact your administrator.',
                      style: TextStyle(color: AppColors.warning, fontSize: 14.sp),
                    ),
                  );
                }
                return Text(
                  'Failed to load leave types',
                  style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                );
              },
              data: (types) {
                if (types.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'No leave types available. Please contact your administrator.',
                      style: TextStyle(color: AppColors.warning, fontSize: 14.sp),
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  value: _selectedLeaveTypeId,
                  decoration: const InputDecoration(
                    hintText: 'Select leave type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: types.map((type) {
                    return DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLeaveTypeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a leave type';
                    return null;
                  },
                );
              },
            ),

            SizedBox(height: 20.h),

            // Date From
            Text(
              'From Date',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  hintText: 'Select start date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateFrom != null ? dateFormat.format(_dateFrom!) : 'Select start date',
                  style: TextStyle(
                    color: _dateFrom != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Date To
            Text(
              'To Date',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  hintText: 'Select end date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateTo != null ? dateFormat.format(_dateTo!) : 'Select end date',
                  style: TextStyle(
                    color: _dateTo != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),

            // Days count
            if (_dateFrom != null && _dateTo != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '${_dateTo!.difference(_dateFrom!).inDays + 1} day(s)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // Notes
            Text(
              'Reason / Notes',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter reason for leave (optional)',
                alignLabelWithHint: true,
              ),
            ),

            SizedBox(height: 32.h),

            // Submit Button
            AppButton(
              text: 'Submit Request',
              isLoading: requestState.isLoading,
              isFullWidth: true,
              onPressed: _submitRequest,
            ),
          ],
        ),
      ),
    );
  }
}
