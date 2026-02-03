import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/hr_provider.dart';
import '../widgets/leave_status_timeline.dart';

class LeaveRequestScreen extends ConsumerWidget {
  const LeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveRequestsAsync = ref.watch(leaveRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hr/leave/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: leaveRequestsAsync.when(
        loading: () => const ListShimmer(),
        error: (error, stack) => AppErrorWidget(
          message: 'Failed to load leave requests',
          onRetry: () => ref.refresh(leaveRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return EmptyStateWidget(
              title: 'No Leave Requests',
              subtitle: 'Tap the button below to create a request',
              icon: Icons.event_busy_outlined,
              action: ElevatedButton.icon(
                onPressed: () => context.push('/hr/leave/new'),
                icon: const Icon(Icons.add),
                label: const Text('New Request'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(leaveRequestsProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: requests.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final request = requests[index];

                return Card(
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
                                request.holidayStatusName ?? 'Leave Request',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            LeaveStatusBadge(state: request.state),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              request.displayPeriod,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.timelapse,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${request.numberOfDays.toStringAsFixed(1)} day(s)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        if (request.notes != null && request.notes!.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            request.notes!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class LeaveStatusBadge extends StatelessWidget {
  final String state;

  const LeaveStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (state) {
      case 'draft':
        color = AppColors.warning;
        label = 'To Submit';
        break;
      case 'confirm':
        color = AppColors.info;
        label = 'To Approve';
        break;
      case 'validate':
        color = AppColors.success;
        label = 'Approved';
        break;
      case 'refuse':
        color = AppColors.error;
        label = 'Refused';
        break;
      case 'validate1':
        color = AppColors.info;
        label = 'Second Approval';
        break;
      default:
        color = AppColors.textSecondary;
        label = state;
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
