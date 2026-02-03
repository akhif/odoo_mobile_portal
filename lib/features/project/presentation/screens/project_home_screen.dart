import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/module_tile.dart';

class ProjectHomeScreen extends StatelessWidget {
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          MenuListTile(
            title: 'Job Orders',
            subtitle: 'View and update assigned tasks',
            icon: Icons.assignment_outlined,
            iconColor: AppColors.primary,
            onTap: () => context.push('/project/jobs'),
          ),
        ],
      ),
    );
  }
}
