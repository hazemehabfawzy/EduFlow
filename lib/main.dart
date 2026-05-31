// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/course_detail/course_detail_screen.dart';
import 'screens/lesson/lesson_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart'; // ← Uncomment after `flutterfire configure`

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Prevent Firestore DNS failures from crashing the app
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      await NotificationService.initialize();
    } catch (e) {
      print('[EduFlow] Firebase or Notification initialization failed: $e');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CourseProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const EduFlowApp(),
      ),
    );
  }, (error, stack) {
    print('[EduFlow] Unhandled error: $error');
  });
}

class EduFlowApp extends StatefulWidget {
  const EduFlowApp({super.key});
  @override
  State<EduFlowApp> createState() => _EduFlowAppState();
}

class _EduFlowAppState extends State<EduFlowApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'EduFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.auth: (_) => const AuthScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.courseDetail: (_) => const CourseDetailScreen(),
        AppRoutes.lesson: (_) => const LessonScreen(),
        AppRoutes.quiz: (_) => const QuizScreen(),
        AppRoutes.admin: (_) => const AdminScreen(),
        AppRoutes.teacherDashboard: (_) => const TeacherDashboardScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.notifications: (_) => const NotificationsScreen(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Page not found')),
        ),
      ),
    );
  }
}

typedef MyApp = EduFlowApp;

