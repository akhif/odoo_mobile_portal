import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/hr_provider.dart';
import 'leave_request_screen.dart';

class VacationRequestScreen extends ConsumerWidget {
  const VacationRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacationRequestsAsync = ref.watch(vacationRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation Requests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hr/vacation/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Vacation'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vacationRequestsProvider);
        },
        child: vacationRequestsAsync.when(
          loading: () => const ListShimmer(),
          error: (error, stack) {
            final errorStr = error.toString().toLowerCase();
            if (errorStr.contains('access') || errorStr.contains('not allowed')) {
              return EmptyStateWidget(
                title: 'Access Restricted',
                subtitle: 'Vacation requests are not available. Please contact your administrator.',
                icon: Icons.lock_outlined,
              );
            }
            return AppErrorWidget(
              message: 'Failed to load vacation requests',
              onRetry: () => ref.refresh(vacationRequestsProvider),
            );
          },
          data: (requests) {
            if (requests.isEmpty) {
              return EmptyStateWidget(
                title: 'No Vacation Requests',
                subtitle: 'Tap the button below to request vacation',
                icon: Icons.beach_access_outlined,
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/hr/vacation/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Vacation'),
                ),
              );
            }

            return ListView.separated(
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
                                request.holidayStatusName ?? 'Vacation Request',
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
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
