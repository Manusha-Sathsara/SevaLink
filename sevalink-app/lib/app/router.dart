import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/reset_success_screen.dart';
import '../features/auth/screens/email_verification_sent_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/dashboard/screens/client_dashboard_screen.dart';
import '../features/worker/screens/worker_home_screen.dart';
import '../features/worker/screens/job_details_screen.dart';
import '../features/worker/screens/send_quote_screen.dart';
import '../features/worker/screens/worker_profile_screen.dart';
import '../features/profile/screens/client_profile_screen.dart';
import '../features/profile/screens/edit_client_profile_screen.dart';
import '../features/jobs/screens/client_jobs_screen.dart';
import '../features/jobs/screens/post_job_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../data/models/job.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (state.matchedLocation == '/') return null; // Allow splash screen
      if (authState.isLoading) return null;
      
      final isLoggedIn = authState.user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      
      if (state.matchedLocation == '/check-auth') {
        if (!isLoggedIn) return '/auth/role-selection';
        return authState.user?.role == 'CLIENT' ? '/client/home' : '/worker/home';
      }

      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/') {
        return '/auth/role-selection';
      }
      if (isLoggedIn && isAuthRoute) {
        return authState.user?.role == 'CLIENT' ? '/client/home' : '/worker/home';
      }
      return null;
    },
   
    routes: [
    
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/check-auth',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/auth/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'CLIENT';
          return SignupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth/reset-success',
        builder: (context, state) => const ResetSuccessScreen(),
      ),
      GoRoute(
        path: '/auth/email-verification',
        builder: (context, state) => const EmailVerificationSentScreen(),
      ),
      GoRoute(
        path: '/client/home',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/client/profile',
        builder: (context, state) => const ClientProfileScreen(),
      ),
      GoRoute(
        path: '/client/edit-profile',
        builder: (context, state) => const EditClientProfileScreen(),
      ),
      GoRoute(
        path: '/client/jobs',
        builder: (context, state) => const ClientJobsScreen(),
      ),
      GoRoute(
        path: '/client/jobs/post',
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        path: '/client/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/client/chat/:userId',
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          final name = extra?['name'] as String? ?? 'User';
          final jobTitle = extra?['jobTitle'] as String?;
          final jobBudget = extra?['jobBudget'] as String?;
          return ChatScreen(
            otherUserId: userId,
            otherUserName: name,
            jobTitle: jobTitle,
            jobBudget: jobBudget,
          );
        },
      ),
      GoRoute(
        path: '/worker/home',
        builder: (context, state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: '/worker/job-details',
        builder: (context, state) {
          final job = state.extra as Job;
          return JobDetailsScreen(job: job);
        },
      ),
      GoRoute(
        path: '/worker/send-quote',
        builder: (context, state) {
          final job = state.extra as Job;
          return SendQuoteScreen(job: job);
        },
      ),
      GoRoute(
        path: '/worker/profile',
        builder: (context, state) =>
            const WorkerProfileScreen(showBackButton: true),
      ),
    ],
  );
});
