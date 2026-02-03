import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class LeaveStatusTimeline extends StatelessWidget {
  final String currentState;

  const LeaveStatusTimeline({
    super.key,
    required this.currentState,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Submitted',
        state: 'draft',
        isCompleted: _isStepCompleted('draft'),
        isCurrent: currentState == 'draft',
      ),
      _TimelineStep(
        title: 'Pending Approval',
        state: 'confirm',
        isCompleted: _isStepCompleted('confirm'),
        isCurrent: currentState == 'confirm',
      ),
      _TimelineStep(
        title: currentState == 'refuse' ? 'Refused' : 'Approved',
        state: currentState == 'refuse' ? 'refuse' : 'validate',
        isCompleted: _isStepCompleted('validate') || currentState == 'refuse',
        isCurrent: currentState == 'validate' || currentState == 'refuse',
        isError: currentState == 'refuse',
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _StepIndicator(
                  isCompleted: step.isCompleted,
                  isCurrent: step.isCurrent,
                  isError: step.isError,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40.h,
                    color: step.isCompleted
                        ? (step.isError ? AppColors.error : AppColors.success)
                        : AppColors.divider,
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: step.isError
                            ? AppColors.error
                            : step.isCurrent
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  bool _isStepCompleted(String state) {
    final order = ['draft', 'confirm', 'validate'];
    final currentIndex = order.indexOf(currentState == 'refuse' ? 'validate' : currentState);
    final stateIndex = order.indexOf(state);
    return stateIndex <= currentIndex;
  }
}

class _TimelineStep {
  final String title;
  final String state;
  final bool isCompleted;
  final bool isCurrent;
  final bool isError;

  _TimelineStep({
    required this.title,
    required this.state,
    required this.isCompleted,
    required this.isCurrent,
    this.isError = false,
  });
}

class _StepIndicator extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final bool isError;

  const _StepIndicator({
    required this.isCompleted,
    required this.isCurrent,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? AppColors.error
        : isCompleted
            ? AppColors.success
            : AppColors.divider;

    if (isCompleted) {
      return Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isError ? Icons.close : Icons.check,
          color: Colors.white,
          size: 16.sp,
        ),
      );
    }

    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: isCurrent
          ? Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
