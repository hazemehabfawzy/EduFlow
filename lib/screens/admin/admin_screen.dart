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
  }

  @override
  void dispose() {
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
        
        // Calculate average rating out of 4.0
        // Firebase stores rating out of 5, convert: (rating/5)*4
        final avgRating = courses.isEmpty
            ? 0.0
            : courses.fold<double>(0, (sum, c) => sum + c.rating) / courses.length;
        final ratingOutOf4 = (avgRating / 5.0) * 4.0;
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
                          // Rating out of 4 + star display
                          Row(
                            children: [
                              ...List.generate(4, (i) => Icon(
                                i < ratingOutOf4.round()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: AppColors.warning,
                                size: 16,
                              )),
                              const SizedBox(width: 6),
                              Text(
                                '${ratingOutOf4.toStringAsFixed(1)} / 4.0',
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
                    return Container(
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
                                    Text('${((course.rating / 5.0) * 4.0).toStringAsFixed(1)}/4.0',
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
          padding: const EdgeInsets.all(24.0),
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
                'High-performance aggregations dynamically counted server-side.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Metric Tile 1: Total Users
              _buildMetricTile(
                context,
                title: 'Total Active Users',
                value: data['users'].toString(),
                subtitle: 'Students, Teachers & Administrators',
                icon: Icons.people_alt_rounded,
                iconBgColor: AppColors.primary.withOpacity(0.12),
                iconColor: AppColors.primary,
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
              const SizedBox(height: 16),

              // Metric Tile 2: Total Courses
              _buildMetricTile(
                context,
                title: 'Total Courses Seeded',
                value: data['courses'].toString(),
                subtitle: 'Across Development, Design & Cloud',
                icon: Icons.book_rounded,
                iconBgColor: AppColors.success.withOpacity(0.12),
                iconColor: AppColors.success,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideX(begin: -0.05),
              const SizedBox(height: 16),

              // Metric Tile 3: Total Enrollments
              _buildMetricTile(
                context,
                title: 'Total Active Enrollments',
                value: data['enrollments'].toString(),
                subtitle: 'Real-time student course subscriptions',
                icon: Icons.school_rounded,
                iconBgColor: AppColors.accent.withOpacity(0.12),
                iconColor: AppColors.accent,
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 200.ms)
                  .slideX(begin: -0.05),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: iconBgColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
