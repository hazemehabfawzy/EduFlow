// lib/screens/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/shimmer_card.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../services/auth_session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchCtrl = TextEditingController();
  late Stream<List<CourseModel>> _coursesStream;
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _coursesStream = context.read<CourseProvider>().streamCourses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthSessionService.startMonitoring(context);
    });
  }

  @override
  void dispose() {
    AuthSessionService.stopMonitoring();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    // 1. Role-based redirect for Teacher
    if (user != null && user.isTeacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherDashboard);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = user?.name.split(' ').first ?? 'Learner';

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<List<EnrollmentModel>>(
      stream: _firestoreService.streamUserEnrollments(user.uid),
      builder: (context, enrollmentsSnapshot) {
        final enrollments = enrollmentsSnapshot.data ?? [];
        final enrolledCount = enrollments.length;
        final overallProgress = enrolledCount == 0
            ? 0.0
            : enrollments.fold<double>(0, (sum, e) => sum + e.progress) / enrolledCount;

        return Scaffold(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          body: StreamBuilder<List<CourseModel>>(
            stream: _coursesStream,
            builder: (context, snapshot) {
              // Update local state based on snapshot
              if (snapshot.connectionState == ConnectionState.active ||
                  snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  _courses = context.read<CourseProvider>().courses;
                  _loading = false;
                }
                if (snapshot.hasError) {
                  _error = snapshot.error.toString();
                  _loading = false;
                }
              }

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // ── App Bar ─────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 125,
                    floating: false,
                    pinned: true,
                    snap: false,
                    forceElevated: innerBoxIsScrolled,
                    automaticallyImplyLeading: false,
                    backgroundColor: AppColors.primary,
                    surfaceTintColor: AppColors.primary,
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
                      if (user.isAdmin) ...[
                        IconButton(
                          tooltip: 'Admin Panel',
                          icon: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: AppColors.white,
                          ),
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AppRoutes.admin),
                        ),
                      ],
                      IconButton(
                        tooltip: 'My Profile',
                        icon: const Icon(
                          Icons.person_rounded,
                          color: AppColors.white,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.profile),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.white,
                        ),
                        onPressed: () => _confirmSignOut(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              Color(0xFF7C74FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.white.withOpacity(0.18),
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hello, $firstName 👋',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Level $enrolledCount Scholar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircularPercentIndicator(
                                  radius: 25.0,
                                  lineWidth: 4.5,
                                  percent: overallProgress,
                                  center: Text(
                                    "${(overallProgress * 100).toInt()}%",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  progressColor: AppColors.white,
                                  backgroundColor: AppColors.white.withOpacity(0.2),
                                  animation: true,
                                  animationDuration: 800,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: _buildScrollBody(user.uid, isDark, snapshot, enrollments),
              );
            },
          ),
        );
      },
    );
  }

  // ── Main Scroll Body ─────────────────────────────────────────────
  Widget _buildScrollBody(
      String userId, bool isDark, AsyncSnapshot<List<CourseModel>> snapshot, List<EnrollmentModel> enrollments) {
    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(child: _buildSearchBar(isDark)),

        // Continue Learning Section
        SliverToBoxAdapter(child: _buildContinueLearning(userId, isDark)),

        // Categories
        SliverToBoxAdapter(child: _buildCategoriesSection()),

        // Featured section
        if (!_loading && _courses.isNotEmpty)
          SliverToBoxAdapter(child: _buildFeaturedBanner(_courses)),

        // Section header
        SliverToBoxAdapter(child: _buildSectionHeader()),

        // Courses content
        _buildCoursesSliver(snapshot),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

Widget _buildContinueLearning(String userId, bool isDark) {
  return StreamBuilder<List<EnrollmentModel>>(
    stream: FirestoreService().streamUserEnrollments(userId),
    builder: (context, enrollSnap) {
      // Still loading enrollments
      if (enrollSnap.connectionState == ConnectionState.waiting) {
        return const SizedBox.shrink();
      }

      // No enrollments at all — hide section
      final enrollments = enrollSnap.data ?? [];
      if (enrollments.isEmpty) return const SizedBox.shrink();

      // Sort by lastAccessedAt to show most recent first
      enrollments.sort((a, b) =>
          b.lastAccessedAt.compareTo(a.lastAccessedAt));

      final latestEnrollment = enrollments.first;

      return FutureBuilder<CourseModel?>(
        future: FirestoreService()
            .fetchCourse(latestEnrollment.courseId),
        builder: (context, courseSnap) {
          // Still fetching course
          if (courseSnap.connectionState ==
              ConnectionState.waiting) {
            return _buildContinueLearningShimmer(isDark);
          }

          // Course not found or error — hide section silently
          final course = courseSnap.data;
          if (course == null) return const SizedBox.shrink();

          final progress = latestEnrollment.progress;
          final completedCount =
              latestEnrollment.completedLessonIds.length;
          final totalLessons = course.totalLessons;

          return Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Section header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            'Continue Learning',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course card
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.courseDetail,
                      arguments: {'courseId': course.id},
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(isDark ? 0.2 : 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Course thumbnail
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(12),
                          child: course.imageUrl.isNotEmpty
                              ? Image.network(
                                  course.imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _coursePlaceholder(),
                                )
                              : _coursePlaceholder(),
                        ),
                        const SizedBox(width: 14),

                        // Course info
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                course.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by ${course.instructorName}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Progress bar
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    progress >= 1.0
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Progress text
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$completedCount/$totalLessons lessons',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: progress >= 1.0
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Arrow
                        const SizedBox(width: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _coursePlaceholder() {
  return Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(
      Icons.school_rounded,
      color: AppColors.primary,
      size: 28,
    ),
  );
}

Widget _buildContinueLearningShimmer(bool isDark) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    ),
  );
}

  // ── Search Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (q) {
            context.read<CourseProvider>().search(q);
            setState(() {});
          },
          style: GoogleFonts.dmSans(
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search courses, instructors…',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      context.read<CourseProvider>().search('');
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFCBD0DC),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFCBD0DC),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  // ── Categories ───────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final categories = context.watch<CourseProvider>().categories;
    final selected = context.watch<CourseProvider>().selectedCategory;

    if (categories.isEmpty) return const SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => CategoryChip(
              label: categories[i],
              isSelected: categories[i] == selected,
              onTap: () => context
                  .read<CourseProvider>()
                  .selectCategory(categories[i]),
              icon: _categoryIcon(categories[i]),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'all':          return Icons.apps_rounded;
      case 'development':  return Icons.code_rounded;
      case 'programming':  return Icons.code_rounded;
      case 'design':       return Icons.palette_rounded;
      case 'business':     return Icons.business_center_rounded;
      case 'marketing':    return Icons.campaign_rounded;
      case 'data science': return Icons.analytics_rounded;
      case 'music':        return Icons.music_note_rounded;
      default:             return Icons.school_rounded;
    }
  }

  // ── Featured Banner ──────────────────────────────────────────────
  Widget _buildFeaturedBanner(List<CourseModel> courses) {
    final featured = courses.where((c) => c.isFeatured).take(4).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '⭐ Featured',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => CourseCard(
              course: featured[i],
              width: 200,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.courseDetail,
                arguments: featured[i],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }

  // ── Section Header ───────────────────────────────────────────────
  Widget _buildSectionHeader() {
    final selected = context.watch<CourseProvider>().selectedCategory;
    final query = context.watch<CourseProvider>().searchQuery;
    final count = context.watch<CourseProvider>().courses.length;

    String title = selected == 'All' ? 'All Courses' : selected;
    if (query.isNotEmpty) title = 'Results for "$query"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count courses',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Courses Sliver ───────────────────────────────────────────────
  Widget _buildCoursesSliver(AsyncSnapshot<List<CourseModel>> snapshot) {
    // Loading shimmer
    if (snapshot.connectionState == ConnectionState.waiting) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ShimmerCourseCard(),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
        ),
      );
    }

    // Error
    if (snapshot.hasError || _error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load courses',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error ?? snapshot.error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final courses = context.read<CourseProvider>().courses;

    // Empty
    if (courses.isEmpty && !_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: _EmptyState(),
        ),
      );
    }

    // Grid of courses
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i >= courses.length) return const SizedBox.shrink();
            return CourseCard(
              course: courses[i],
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.courseDetail,
                arguments: courses[i],
              ),
            )
                .animate()
                .fadeIn(
                  duration: 350.ms,
                  delay: Duration(milliseconds: 50 * i),
                )
                .slideY(begin: 0.1);
          },
          childCount: courses.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
      ),
    );
  }

  // ── Sign Out Dialog ──────────────────────────────────────────────
  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<NotificationProvider>().stopListening();
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
      }
    }
  }
}

// ── Empty State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No courses found',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your search\nor select a different category.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}