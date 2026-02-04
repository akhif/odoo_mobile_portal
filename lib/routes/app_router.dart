import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/server_setup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/hr/presentation/screens/hr_home_screen.dart';
import '../features/hr/presentation/screens/payslip_list_screen.dart';
import '../features/hr/presentation/screens/payslip_detail_screen.dart';
import '../features/hr/presentation/screens/leave_request_screen.dart';
import '../features/hr/presentation/screens/leave_form_screen.dart';
import '../features/hr/presentation/screens/vacation_request_screen.dart';
import '../features/hr/presentation/screens/attendance_screen.dart';
import '../features/hr/presentation/screens/hr_documents_screen.dart';
import '../features/sales/presentation/screens/sales_home_screen.dart';
import '../features/sales/presentation/screens/invoice_list_screen.dart';
import '../features/sales/presentation/screens/invoice_detail_screen.dart';
import '../features/sales/presentation/screens/customer_credit_screen.dart';
import '../features/sales/presentation/screens/product_info_screen.dart';
import '../features/purchase/presentation/screens/purchase_home_screen.dart';
import '../features/purchase/presentation/screens/purchase_products_screen.dart';
import '../features/purchase/presentation/screens/suppliers_list_screen.dart';
import '../features/purchase/presentation/screens/supplier_detail_screen.dart';
import '../features/purchase/presentation/screens/market_price_screen.dart';
import '../features/project/presentation/screens/project_home_screen.dart';
import '../features/project/presentation/screens/job_order_list_screen.dart';
import '../features/project/presentation/screens/job_order_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Read auth state without watching (prevents router recreation)
      final authState = ref.read(authProvider);

      final isLoggedIn = authState.isAuthenticated;
      final needsServerSetup = authState.needsServerSetup;
      final isOnSplash = state.matchedLocation == '/';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnServerSetup = state.matchedLocation == '/server-setup';

      // Don't redirect from splash (it handles its own navigation)
      if (isOnSplash) return null;

      // Allow navigation between server-setup and login
      if (isOnLogin || isOnServerSetup) return null;

      // If server setup is needed, go there
      if (needsServerSetup) {
        return '/server-setup';
      }

      // If not logged in, go to login
      if (!isLoggedIn) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/server-setup',
        builder: (context, state) => const ServerSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // HR Module
      GoRoute(
        path: '/hr',
        builder: (context, state) => const HrHomeScreen(),
      ),
      GoRoute(
        path: '/hr/payslips',
        builder: (context, state) => const PayslipListScreen(),
      ),
      GoRoute(
        path: '/hr/payslips/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PayslipDetailScreen(payslipId: id);
        },
      ),
      GoRoute(
        path: '/hr/leave',
        builder: (context, state) => const LeaveRequestScreen(),
      ),
      GoRoute(
        path: '/hr/leave/new',
        builder: (context, state) => const LeaveFormScreen(),
      ),
      GoRoute(
        path: '/hr/vacation',
        builder: (context, state) => const VacationRequestScreen(),
      ),
      GoRoute(
        path: '/hr/vacation/new',
        builder: (context, state) => const LeaveFormScreen(isVacation: true),
      ),
      GoRoute(
        path: '/hr/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/hr/documents',
        builder: (context, state) => const HrDocumentsScreen(),
      ),

      // Sales Module
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesHomeScreen(),
      ),
      GoRoute(
        path: '/sales/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/sales/invoices/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/sales/credit',
        builder: (context, state) => const CustomerCreditScreen(),
      ),
      GoRoute(
        path: '/sales/products',
        builder: (context, state) => const ProductInfoScreen(),
      ),

      // Purchase Module
      GoRoute(
        path: '/purchase',
        builder: (context, state) => const PurchaseHomeScreen(),
      ),
      GoRoute(
        path: '/purchase/products',
        builder: (context, state) => const PurchaseProductsScreen(),
      ),
      GoRoute(
        path: '/purchase/suppliers',
        builder: (context, state) => const SuppliersListScreen(),
      ),
      GoRoute(
        path: '/purchase/suppliers/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return SupplierDetailScreen(supplierId: id);
        },
      ),
      GoRoute(
        path: '/purchase/market-price',
        builder: (context, state) => const MarketPriceScreen(),
      ),

      // Project Module
      GoRoute(
        path: '/project',
        builder: (context, state) => const ProjectHomeScreen(),
      ),
      GoRoute(
        path: '/project/jobs',
        builder: (context, state) => const JobOrderListScreen(),
      ),
      GoRoute(
        path: '/project/jobs/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return JobOrderDetailScreen(jobOrderId: id);
        },
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
