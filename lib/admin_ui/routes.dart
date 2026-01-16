import 'package:go_router/go_router.dart';
import 'package:p2/admin_ui/views/AdminDashboard.dart';
import 'package:p2/admin_ui/views/ChatsPage_admin.dart';
import 'package:p2/admin_ui/views/issueReportsPage.dart';
import 'package:p2/admin_ui/views/systemWallet.dart';
import 'package:p2/admin_ui/views/ItemManagementPage.dart';
import 'package:p2/admin_ui/views/LoginPage_admin.dart';
import 'package:p2/admin_ui/views/NotificationsPage.dart';
import 'package:p2/admin_ui/views/ReportsPage.dart';
import 'package:p2/admin_ui/views/TransactionsPage.dart';
import 'package:p2/admin_ui/views/UserManagement.dart';
//import 'package:p2/admin_ui/views/item_notification.dart';
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
          builder: (context, state) => const AdminReportsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),

        /*// NEW ROUTE 
        GoRoute(
          path: '/item-notifications',
          builder: (context, state) => const ItemNotificationPage(),
        ),
         */

        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatsPage(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const SystemWalletPage(),
        ),
      ],
    ),
  ],
);
