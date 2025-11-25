import 'package:go_router/go_router.dart';
import 'package:p2/admin_ui/Pages/AdminDashboard.dart';
import 'package:p2/admin_ui/Pages/ChatsPage_admin.dart';
import 'package:p2/admin_ui/Pages/ComplaintsPage.dart';
import 'package:p2/admin_ui/Pages/InteractionsPage.dart';
import 'package:p2/admin_ui/Pages/ItemManagementPage.dart';
import 'package:p2/admin_ui/Pages/LoginPage_admin.dart';
import 'package:p2/admin_ui/Pages/ManageTripsPage.dart';
import 'package:p2/admin_ui/Pages/NotificationsPage.dart';
import 'package:p2/admin_ui/Pages/ReportsPage.dart';
import 'package:p2/admin_ui/Pages/TransactionsPage.dart';
import 'package:p2/admin_ui/Pages/UserManagement.dart';

import 'layout/admin_layout.dart';

final GoRouter adminRouter = GoRouter(
  initialLocation: '/adminLogin',

 
  redirect: (context, state) {
  
    return null;
  },

  routes: [
    
    GoRoute(
      path: '/adminLogin',
      builder: (context, state) => const AdminLoginPage(),
    ),

    
    ShellRoute(
      builder: (context, state, child) => AdminLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementPage(),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const ManageTripsPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/items',
          builder: (context, state) => const ItemManagementPage(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsPage(),
        ),
        GoRoute(
          path: '/complaints',
          builder: (context, state) => const ComplaintsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatsPage(),
        ),
        GoRoute(
          path: '/interactions',
          builder: (context, state) => const InteractionsPage(),
        ),
      ],
    ),
  ],
);
