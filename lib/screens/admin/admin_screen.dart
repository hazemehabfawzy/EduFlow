// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

import '../../services/auth_session_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/course_enrollments_sheet.dart';
import '../../widgets/notification_bell.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthSessionService.startMonitoring(context);
    });
  }

  @override
  void dispose() {
    AuthSessionService.stopMonitoring();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard 🛡️',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Toggle Dark Mode',
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: AppColors.white,
            ),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'Teachers'),
            Tab(icon: Icon(Icons.book_rounded, size: 20), text: 'Courses'),
            Tab(
                icon: Icon(Icons.analytics_rounded, size: 20),
                text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeachersTab(firestoreService: _firestoreService, isDark: isDark),
          _CoursesTab(firestoreService: _firestoreService, isDark: isDark),
          _AnalyticsTab(firestoreService: _firestoreService, isDark: isDark),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USERS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _TeachersTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final bool isDark;
  const _TeachersTab({required this.firestoreService, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: firestoreService.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final teachers = (snapshot.data ?? [])
            .where((u) => u.role == 'teacher')
            .toList();

        if (teachers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text('No teachers yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: teachers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _TeacherCard(
              teacher: teachers[index],
              firestoreService: firestoreService,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final UserModel teacher;
  final FirestoreService firestoreService;
  final bool isDark;
  const _TeacherCard({required this.teacher, required this.firestoreService, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourseModel>>(
      stream: firestoreService.streamTeacherCourses(teacher.name),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? [];
        
        // Calculate average rating out of 5.0
        // Firebase stores rating out of 5
        final avgRating = courses.isEmpty
            ? 0.0
            : courses.fold<double>(0, (sum, c) => sum + c.rating) / courses.length;
        final totalEnrollments = courses.fold<int>(0, (sum, c) => sum + c.totalStudents);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Teacher Header ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : 'T',
                        style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher.name,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(teacher.email,
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                i < avgRating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: AppColors.warning,
                                size: 16,
                              )),
                              const SizedBox(width: 6),
                              Text(
                                '${avgRating.toStringAsFixed(1)} / 5.0',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.people_alt_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('$totalEnrollments enrolled',
                                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),

              // ── Course List ──
              if (courses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No courses yet',
                    style: GoogleFonts.dmSans(color: AppColors.textHint)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final course = courses[i];
                    return InkWell(
                      onTap: () => CourseEnrollmentsSheet.show(context, course),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text('${course.totalStudents} enrollments',
                                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text('${course.rating.toStringAsFixed(1)}/5.0',
                                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.warning)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Delete course button
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error, size: 20),
                            onPressed: () => _confirmDeleteCourse(context, course, firestoreService),
                          ),
                        ],
                      ),
                    ),
                  );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteCourse(BuildContext context, CourseModel course, FirestoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Course?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete "${course.title}"? This cannot be undone.', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await service.deleteCourse(course.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Course deleted successfully.')),
              );
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSES TAB
// ─────────────────────────────────────────────────────────────────────────────
class _CoursesTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final bool isDark;

  const _CoursesTab({required this.firestoreService, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourseModel>>(
      stream: firestoreService.streamAllCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return const Center(child: Text('No courses available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final course = courses[index];
            return InkWell(
              onTap: () => CourseEnrollmentsSheet.show(context, course),
              borderRadius: BorderRadius.circular(20),
              child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        course.imageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 130,
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Center(
                              child: Icon(Icons.school_rounded,
                                  color: AppColors.primary, size: 40)),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.category,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instructor: ${course.instructorName}',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${course.totalStudents} enrolled | ${course.totalLessons} lessons',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint),
                            ),
                            Row(
                              children: [
                                // Feature toggle star button
                                IconButton(
                                  icon: Icon(
                                    course.isFeatured
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: AppColors.warning,
                                    size: 26,
                                  ),
                                  onPressed: () =>
                                      firestoreService.toggleCourseFeatured(
                                          course.id, !course.isFeatured),
                                  tooltip: 'Toggle Feature',
                                ),
                                const SizedBox(width: 8),
                                // Delete button
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                        size: 20),
                                    onPressed: () =>
                                        _confirmDelete(context, course),
                                    tooltip: 'Delete Course',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
                .fadeIn(
                    duration: 350.ms, delay: Duration(milliseconds: 50 * index))
                .slideY(begin: 0.05);
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Course?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${course.title}"? All associated lessons, quizzes, and enrollments will be deleted permanently.',
            style: GoogleFonts.dmSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting course...')),
                );
                try {
                  await firestoreService.deleteCourse(course.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Course successfully deleted.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting course: $e')),
                  );
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final bool isDark;

  const _AnalyticsTab({required this.firestoreService, required this.isDark});

  Future<Map<String, int>> _getAnalyticsData() async {
    final results = await Future.wait([
      firestoreService.countUsers(),
      firestoreService.countCourses(),
      firestoreService.countEnrollments(),
    ]);

    return {
      'users': results[0],
      'courses': results[1],
      'enrollments': results[2],
    };
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'development':
      case 'programming':
        return AppColors.primary;
      case 'design':
        return AppColors.accent;
      case 'business':
        return AppColors.warning;
      case 'marketing':
        return AppColors.error;
      case 'data science':
        return AppColors.success;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getAnalyticsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading analytics: ${snapshot.error}'));
        }

        final data =
            snapshot.data ?? {'users': 0, 'courses': 0, 'enrollments': 0};

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Overview 🚀',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dynamic metrics aggregated from active database collections.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Summary metric tiles
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Users',
                      data['users'].toString(),
                      Icons.people_alt_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Courses',
                      data['courses'].toString(),
                      Icons.book_rounded,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Enrollments',
                      data['enrollments'].toString(),
                      Icons.school_rounded,
                      AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Bar Chart comparing metrics
              Text(
                'Platform Statistics Comparison 📊',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [data['users']!, data['courses']!, data['enrollments']!]
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble() + 5,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => isDark ? AppColors.cardDark : AppColors.white,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}',
                            GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            switch (value.toInt()) {
                              case 0:
                                text = 'Users';
                                break;
                              case 1:
                                text = 'Courses';
                                break;
                              case 2:
                                text = 'Enrollments';
                                break;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                text,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: data['users']!.toDouble(),
                            color: AppColors.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: data['courses']!.toDouble(),
                            color: AppColors.success,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: data['enrollments']!.toDouble(),
                            color: AppColors.accent,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Pie Chart Category Breakdown
              Text(
                'Seeded Courses by Category 🎨',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<CourseModel>>(
                stream: firestoreService.streamAllCourses(),
                builder: (context, courseSnap) {
                  final courses = courseSnap.data ?? [];
                  if (courses.isEmpty) {
                    return Container(
                      height: 150,
                      alignment: Alignment.center,
                      child: Text(
                        'No courses found for distribution.',
                        style: GoogleFonts.dmSans(color: AppColors.textHint),
                      ),
                    );
                  }

                  final categoryCounts = <String, int>{};
                  for (var course in courses) {
                    categoryCounts[course.category] =
                        (categoryCounts[course.category] ?? 0) + 1;
                  }

                  final pieSections = categoryCounts.entries.map((entry) {
                    final percentage = (entry.value / courses.length) * 100;
                    return PieChartSectionData(
                      color: _getCategoryColor(entry.key),
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 30,
                              sections: pieSections,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: categoryCounts.keys.map((cat) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(cat),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$cat (${categoryCounts[cat]})',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
