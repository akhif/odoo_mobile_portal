import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';

class JobOrderListScreen extends StatefulWidget {
  const JobOrderListScreen({super.key});

  @override
  State<JobOrderListScreen> createState() => _JobOrderListScreenState();
}

class _JobOrderListScreenState extends State<JobOrderListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobOrders = [];

  @override
  void initState() {
    super.initState();
    _loadJobOrders();
  }

  Future<void> _loadJobOrders() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _jobOrders = [
        {
          'id': 1,
          'name': 'JOB-2024-001',
          'project': 'Website Redesign',
          'description': 'Update homepage layout and navigation',
          'date_deadline': DateTime.now().add(const Duration(days: 5)),
          'stage': 'In Progress',
          'priority': 'high',
          'progress': 60,
        },
        {
          'id': 2,
          'name': 'JOB-2024-002',
          'project': 'Mobile App Development',
          'description': 'Implement user authentication module',
          'date_deadline': DateTime.now().add(const Duration(days: 10)),
          'stage': 'In Progress',
          'priority': 'medium',
          'progress': 30,
        },
        {
          'id': 3,
          'name': 'JOB-2024-003',
          'project': 'Website Redesign',
          'description': 'Create responsive design for tablet devices',
          'date_deadline': DateTime.now().subtract(const Duration(days: 2)),
          'stage': 'Overdue',
          'priority': 'high',
          'progress': 80,
        },
        {
          'id': 4,
          'name': 'JOB-2024-004',
          'project': 'Documentation',
          'description': 'Write API documentation',
          'date_deadline': DateTime.now().add(const Duration(days: 15)),
          'stage': 'To Do',
          'priority': 'low',
          'progress': 0,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Orders'),
      ),
      body: _isLoading
          ? const ListShimmer()
          : _jobOrders.isEmpty
              ? const EmptyStateWidget(
                  title: 'No Job Orders',
                  subtitle: 'Assigned tasks will appear here',
                  icon: Icons.assignment_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadJobOrders,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _jobOrders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final job = _jobOrders[index];
                      final isOverdue = job['stage'] == 'Overdue';
                      final deadline = job['date_deadline'] as DateTime;

                      return Card(
                        child: InkWell(
                          onTap: () => context.push('/project/jobs/${job['id']}'),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      job['name'],
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    _PriorityBadge(priority: job['priority']),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  job['project'],
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  job['description'],
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12.h),

                                // Progress bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4.r),
                                        child: LinearProgressIndicator(
                                          value: job['progress'] / 100,
                                          minHeight: 6.h,
                                          backgroundColor: AppColors.divider,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            job['progress'] == 100
                                                ? AppColors.success
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      '${job['progress']}%',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12.h),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14.sp,
                                          color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          dateFormat.format(deadline),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _StageBadge(stage: job['stage']),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (priority) {
      case 'high':
        color = AppColors.error;
        icon = Icons.keyboard_double_arrow_up;
        break;
      case 'medium':
        color = AppColors.warning;
        icon = Icons.remove;
        break;
      default:
        color = AppColors.info;
        icon = Icons.keyboard_double_arrow_down;
    }

    return Icon(icon, color: color, size: 20.sp);
  }
}

class _StageBadge extends StatelessWidget {
  final String stage;

  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (stage) {
      case 'Done':
        color = AppColors.success;
        break;
      case 'In Progress':
        color = AppColors.info;
        break;
      case 'Overdue':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        stage,
        style: TextStyle(
          fontSize: 12.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
