import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/rh_dashboard/dashboard_page.dart';
import 'features/rh_requests/pending_requests_page.dart';
import 'features/rh_users/user_management_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authState = context.watch<AuthService>().user;
    final isLogged = authState != null;
    final isLogin = state.matchedLocation == '/login';

    if (isLogged && isLogin) return '/dashboard';
    if (!isLogged && !isLogin) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/pending-requests',
      builder: (context, state) => const PendingRequestsPage(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UserManagementPage(),
    ),
  ],
);