import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/module_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final roles = user?.roles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor: AppColors.white.withOpacity(0.2),
                          child: Text(
                            user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                user?.displayName ?? 'User',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _getRoleText(roles),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Modules Section
              Text(
                'Modules',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // Module Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.1,
                children: [
                  // HR Module - Always visible for all employees
                  if (roles?.hasHrAccess ?? true)
                    ModuleTile(
                      title: 'HR',
                      subtitle: 'Payslips, Leave, Attendance',
                      icon: Icons.people_outline,
                      color: AppColors.primary,
                      onTap: () => context.push('/hr'),
                    ),

                  // Sales Module
                  if (roles?.hasSalesAccess ?? false)
                    ModuleTile(
                      title: 'Sales',
                      subtitle: 'Invoices, Credit, Products',
                      icon: Icons.point_of_sale_outlined,
                      color: AppColors.secondary,
                      onTap: () => context.push('/sales'),
                    ),

                  // Purchase Module
                  if (roles?.hasPurchaseAccess ?? false)
                    ModuleTile(
                      title: 'Purchase',
                      subtitle: 'Suppliers, Market Prices',
                      icon: Icons.shopping_cart_outlined,
                      color: const Color(0xFF7B68EE),
                      onTap: () => context.push('/purchase'),
                    ),

                  // Project Module
                  if (roles?.hasProjectAccess ?? false)
                    ModuleTile(
                      title: 'Project',
                      subtitle: 'Job Orders, Progress',
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFFFF7043),
                      onTap: () => context.push('/project'),
                    ),
                ],
              ),

              SizedBox(height: 24.h),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // Quick Action Cards
              Row(
                children: [
                  if (roles?.hasHrAccess ?? true)
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.access_time,
                        title: 'Attendance',
                        color: AppColors.success,
                        onTap: () => context.push('/hr/attendance'),
                      ),
                    ),
                  if (roles?.hasHrAccess ?? true) SizedBox(width: 12.w),
                  if (roles?.hasHrAccess ?? true)
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.event_note,
                        title: 'Request Leave',
                        color: AppColors.info,
                        onTap: () => context.push('/hr/leave/new'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleText(roles) {
    if (roles == null) return 'Employee';

    final accessList = <String>[];
    if (roles.hasHrAccess) accessList.add('HR');
    if (roles.hasSalesAccess) accessList.add('Sales');
    if (roles.hasPurchaseAccess) accessList.add('Purchase');
    if (roles.hasProjectAccess) accessList.add('Project');

    return accessList.isEmpty ? 'Employee' : accessList.join(' | ');
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
