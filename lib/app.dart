import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'screens/about/about_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/camera_detection/camera_detection_screen.dart';
import 'screens/chatbot/vision_chatbot_screen.dart';
import 'screens/danger_alert/danger_alert_screen.dart';
import 'screens/document_screening/document_screening_screen.dart';
import 'screens/drowsiness/drowsiness_monitor_screen.dart';
import 'screens/face_recognition/face_recognition_screen.dart';
import 'screens/find_object/find_object_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/video_review/video_fast_review_screen.dart';
import 'widgets/main_layout_shell.dart';

class SmartVisionApp extends StatelessWidget {
  const SmartVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainLayoutShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const HomeScreen()),
            ),
            GoRoute(
              path: '/camera_detection',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const CameraDetectionScreen()),
            ),
            GoRoute(
              path: '/chatbot',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const VisionChatbotScreen()),
            ),
            GoRoute(
              path: '/document_screening',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const DocumentScreeningScreen()),
            ),
            GoRoute(
              path: '/find_object',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const FindObjectScreen()),
            ),
            GoRoute(
              path: '/alerts',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const DangerAlertScreen()),
            ),
            GoRoute(
              path: '/face_id',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const FaceRecognitionScreen()),
            ),
            GoRoute(
              path: '/drowsiness',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const DrowsinessMonitorScreen()),
            ),
            GoRoute(
              path: '/history',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const HistoryScreen()),
            ),
            GoRoute(
              path: '/statistics',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const AnalyticsScreen()),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const SettingsScreen()),
            ),
            GoRoute(
              path: '/video_review',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const VideoFastReviewScreen()),
            ),
            GoRoute(
              path: '/about',
              pageBuilder: (context, state) =>
                  _buildPageTransition(state, const AboutScreen()),
            ),
          ],
        )
      ],
    );

    return MaterialApp.router(
      title: 'Smart Vision AI',
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  static CustomTransitionPage _buildPageTransition(
      GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
