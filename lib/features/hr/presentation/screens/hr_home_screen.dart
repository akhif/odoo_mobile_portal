import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/module_tile.dart';

class HrHomeScreen extends StatelessWidget {
  const HrHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MenuListTile(
            title: 'Payslips',
            subtitle: 'View your salary slips',
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.primary,
            onTap: () => context.push('/hr/payslips'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Leave Requests',
            subtitle: 'Apply for leave',
            icon: Icons.event_busy_outlined,
            iconColor: AppColors.info,
            onTap: () => context.push('/hr/leave'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Vacation Requests',
            subtitle: 'Apply for vacation',
            icon: Icons.beach_access_outlined,
            iconColor: AppColors.secondary,
            onTap: () => context.push('/hr/vacation'),
          ),
          const Divider(),
          MenuListTile(
            title: 'Remote Attendance',
            subtitle: 'Check in/out with GPS',
            icon: Icons.location_on_outlined,
            iconColor: AppColors.success,
            onTap: () => context.push('/hr/attendance'),
          ),
          const Divider(),
          MenuListTile(
            title: 'HR Documents',
            subtitle: 'Submit required documents',
            icon: Icons.folder_outlined,
            iconColor: AppColors.warning,
            onTap: () => context.push('/hr/documents'),
          ),
        ],
      ),
    );
  }
}
