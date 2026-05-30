// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'My Profile 🎓',
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
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
      ),
      body: StreamBuilder<List<EnrollmentModel>>(
        stream: _firestoreService.streamUserEnrollments(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final enrollments = snapshot.data ?? [];

          // Aggregate user metrics
          final enrolledCount = enrollments.length;
          final completedLessons = enrollments.fold<int>(0, (sum, e) => sum + e.completedCount);
          final avgProgress = enrolledCount == 0
              ? 0.0
              : enrollments.fold<double>(0, (sum, e) => sum + e.progress) / enrolledCount;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Avatar & Info ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),

                      // Email
                      Text(
                        user.email,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getRoleColor(user.role).withOpacity(0.2), width: 1.5),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getRoleColor(user.role),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats Row ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(2), // acts as gradient border width
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Enrolled', enrolledCount.toString(), isDark),
                          _buildStatDivider(isDark),
                          _buildStatItem('Completed', '$completedLessons less.', isDark),
                          _buildStatDivider(isDark),
                          _buildStatItem('Avg. Progress', '${(avgProgress * 100).toInt()}%', isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── My Enrolled Courses Section ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'My Active Courses',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Enrollments List
              if (enrollments.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textHint.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No courses enrolled yet',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final enrollment = enrollments[index];
                        return _buildEnrolledCourseCard(enrollment, isDark)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: Duration(milliseconds: 50 * index))
                            .slideY(begin: 0.05);
                      },
                      childCount: enrollments.length,
                    ),
                  ),
                ),

              // ── Sign Out ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.white),
                    label: Text(
                      'Sign Out of Account',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.white),
                    ),
                    onPressed: () => _confirmSignOut(context),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1.5,
      height: 36,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  Widget _buildEnrolledCourseCard(EnrollmentModel enrollment, bool isDark) {
    return FutureBuilder<CourseModel?>(
      future: _firestoreService.fetchCourse(enrollment.courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }

        final course = snapshot.data;
        if (course == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Image.network(
                course.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${course.instructorName}',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: enrollment.progress,
                                minHeight: 5,
                                backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                                valueColor: const AlwaysStoppedAnimation(AppColors.success),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(enrollment.progress * 100).toInt()}%',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return AppColors.error;
      case 'teacher': return AppColors.accent;
      default: return AppColors.success;
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
      }
    }
  }
}
