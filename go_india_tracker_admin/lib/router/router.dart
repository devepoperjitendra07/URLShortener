import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/link_details_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/dashboard' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(isLogin: true),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AuthScreen(isLogin: false),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(currentTab: 0),
      ),
      GoRoute(
        path: '/apps',
        builder: (context, state) => const DashboardScreen(currentTab: 1),
      ),
      GoRoute(
        path: '/links',
        builder: (context, state) => const DashboardScreen(currentTab: 2),
      ),
      GoRoute(
        path: '/link-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LinkDetailsScreen(linkId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      if (!authState.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) {
        return '/dashboard';
      }
      return null;
    },
  );
});
