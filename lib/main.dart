// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/course_detail/course_detail_screen.dart';
import 'screens/lesson/lesson_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'firebase_options.dart'; // ← Uncomment after `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
      ],
      child: const EduFlowApp(),
    ),
  );
}

class EduFlowApp extends StatefulWidget {
  const EduFlowApp({super.key});
  @override
  State<EduFlowApp> createState() => _EduFlowAppState();
}

class _EduFlowAppState extends State<EduFlowApp> {
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
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

