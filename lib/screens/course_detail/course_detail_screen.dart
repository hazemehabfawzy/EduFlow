// lib/screens/course_detail/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../models/lesson_model.dart';
import '../../models/enrollment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Course passed via Navigator arguments
    final course = ModalRoute.of(context)!.settings.arguments as CourseModel;
    final userId = context.read<AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<EnrollmentModel?>(
        stream: _firestoreService.streamEnrollment(
            userId: userId, courseId: course.id),
        builder: (context, enrollSnap) {
          final enrollment = enrollSnap.data;
          return StreamBuilder<List<LessonModel>>(
            stream: _firestoreService.streamLessons(course.id),
            builder: (context, lessonSnap) {
              final lessons = lessonSnap.data ?? [];
              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      _buildHeroAppBar(course, enrollment),
                      SliverToBoxAdapter(
                          child: _buildBody(course, enrollment, lessons)),
                    ],
                  ),
                  // Floating enroll / continue button
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _buildBottomBar(
                        course, enrollment, lessons, userId),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Hero AppBar ─────────────────────────────────────────────────────────────
  SliverAppBar _buildHeroAppBar(
      CourseModel course, EnrollmentModel? enrollment) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: AppColors.black.withOpacity(0.35),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 16),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: AppColors.black.withOpacity(0.35),
            child: IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: AppColors.white, size: 18),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Course image
            course.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: course.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient)),
                    errorWidget: (_, __, ___) => _heroBannerPlaceholder(),
                  )
                : _heroBannerPlaceholder(),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparent,
                    AppColors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Course level + category badges (bottom left)
            Positioned(
              bottom: 16, left: 16,
              child: Row(children: [
                _Badge(label: course.category, color: AppColors.primary),
                const SizedBox(width: 8),
                _Badge(
                  label: course.level,
                  color: _levelColor(course.level),
                ),
              ]),
            ),

            // Progress bar overlay if enrolled
            if (enrollment != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: enrollment.progress,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroBannerPlaceholder() => Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
          child: Icon(Icons.school_rounded, color: AppColors.white, size: 64),
        ),
      );

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody(CourseModel course, EnrollmentModel? enrollment,
      List<LessonModel> lessons) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      // Extra bottom padding for the floating bar
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Course title + stats ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(height: 1.3))
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 16),
                _buildStatsRow(course, enrollment)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Progress card (only when enrolled) ─────────────────────────
          if (enrollment != null)
            _buildProgressCard(enrollment, lessons)
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms),


          // ── Description ─────────────────────────────────────────────────
          _buildDescriptionSection(course)
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms),

          // ── Divider ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(),
          ),

          // ── Lessons list ────────────────────────────────────────────────
          _buildLessonsSection(course, enrollment, lessons)
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  // ── Stats Row ───────────────────────────────────────────────────────────────
  Widget _buildStatsRow(CourseModel course, EnrollmentModel? enrollment) {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        _StatItem(
          icon: Icons.star_rounded,
          iconColor: AppColors.warning,
          label: '${course.rating.toStringAsFixed(1)} rating',
        ),
        _StatItem(
          icon: Icons.people_outline_rounded,
          iconColor: AppColors.primary,
          label: '${course.totalStudents} students',
        ),
        _StatItem(
          icon: Icons.play_circle_outline_rounded,
          iconColor: AppColors.accent,
          label: '${course.totalLessons} lessons',
        ),
        if (course.durationMinutes > 0)
          _StatItem(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.secondary,
            label: course.formattedDuration,
          ),
      ],
    );
  }

  // ── Progress Card ───────────────────────────────────────────────────────────
  Widget _buildProgressCard(
      EnrollmentModel enrollment, List<LessonModel> lessons) {
    final pct = (enrollment.progress * 100).toInt();
    final completed = enrollment.completedLessonIds.length;
    final total = lessons.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.success.withOpacity(0.12),
              AppColors.accent.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.success.withOpacity(0.25), width: 1.5),
        ),
        child: Row(children: [
          // Circular progress
          SizedBox(
            width: 60, height: 60,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: enrollment.progress,
                backgroundColor: AppColors.success.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
                strokeWidth: 5,
              ),
              Text('$pct%',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  )),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text('$completed of $total lessons completed',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: enrollment.progress,
                    backgroundColor: AppColors.success.withOpacity(0.15),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }



  // ── Description ─────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection(CourseModel course) {
    const maxLines = 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this course',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _descExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              course.description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 14, height: 1.7,
                color: isDark ? const Color(0xFFB0B8C4) : AppColors.textSecondary,
              ),
            ),
            secondChild: Text(
              course.description,
              style: GoogleFonts.dmSans(
                fontSize: 14, height: 1.7,
                color: isDark ? const Color(0xFFB0B8C4) : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Show less' : 'Read more',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lessons List ────────────────────────────────────────────────────────────
  Widget _buildLessonsSection(CourseModel course, EnrollmentModel? enrollment,
      List<LessonModel> lessons) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Course Content',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('${lessons.length} lessons',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          if (lessons.isEmpty)
            _NoLessonsPlaceholder()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final lesson = lessons[i];
                final isCompleted = enrollment?.completedLessonIds
                        .contains(lesson.id) ?? false;
                final isLocked =
                    enrollment == null && !lesson.isPreview;
                return _LessonTile(
                  lesson: lesson,
                  index: i + 1,
                  isCompleted: isCompleted,
                  isLocked: isLocked,
                  onTap: isLocked
                      ? () => _showEnrollPrompt()
                      : () => Navigator.of(context).pushNamed(
                            AppRoutes.lesson,
                            arguments: {
                              'lesson': lesson,
                              'lessons': lessons,
                              'enrollment': enrollment,
                              'courseId': course.id,
                            },
                          ),
                ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: 40 * i));
              },
            ),
        ],
      ),
    );
  }

  // ── Bottom Bar (Enroll / Continue) ──────────────────────────────────────────
  Widget _buildBottomBar(CourseModel course, EnrollmentModel? enrollment,
      List<LessonModel> lessons, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnrolling = context.watch<CourseProvider>().isEnrolling;

    // Find first incomplete lesson for "Continue" button
    LessonModel? nextLesson;
    if (enrollment != null && lessons.isNotEmpty) {
      nextLesson = lessons.firstWhere(
        (l) => !enrollment.completedLessonIds.contains(l.id),
        orElse: () => lessons.last,
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: enrollment == null
          ? GradientButton(
              label: 'Enroll for Free',
              isLoading: isEnrolling,
              onPressed: isEnrolling
                  ? null
                  : () => _enrollInCourse(course, userId),
              icon: const Icon(Icons.rocket_launch_rounded,
                  color: AppColors.white, size: 18),
            )
          : enrollment.isCompleted
              ? GradientButton(
                  label: '🎉  Course Completed!',
                  gradientColors: [AppColors.success, AppColors.accent],
                  onPressed: () {},
                )
              : GradientButton(
                  label: nextLesson != null
                      ? 'Continue: ${nextLesson.title}'
                      : 'Continue Learning',
                  onPressed: nextLesson == null
                      ? null
                      : () => Navigator.of(context).pushNamed(
                            AppRoutes.lesson,
                            arguments: {
                              'lesson': nextLesson!,
                              'lessons': lessons,
                              'enrollment': enrollment,
                              'courseId': course.id,
                            },
                          ),
                ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> _enrollInCourse(CourseModel course, String userId) async {
    final result = await context.read<CourseProvider>().enroll(
          userId: userId, courseId: course.id);

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 10),
            const Expanded(child: Text('Enrolled successfully! Start learning.')),
          ]),
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.white,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final err = context.read<CourseProvider>().errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)));
      }
    }
  }

  void _showEnrollPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.lock_rounded,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Enroll to unlock this lesson',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('This lesson is only available to enrolled students.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Enroll for Free',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':     return AppColors.success;
      case 'intermediate': return AppColors.warning;
      case 'advanced':     return AppColors.error;
      default:             return AppColors.primary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _StatItem(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: iconColor),
      const SizedBox(width: 5),
      Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 13, color: AppColors.textSecondary)),
    ]);
  }
}

class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.06)
              : (isDark ? AppColors.cardDark : AppColors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.3)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // Index / status icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withOpacity(0.12)
                  : isLocked
                      ? AppColors.textHint.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20)
                  : isLocked
                      ? const Icon(Icons.lock_rounded,
                          color: AppColors.textHint, size: 18)
                      : Text('$index',
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isLocked
                          ? AppColors.textHint
                          : (isDark
                              ? AppColors.white
                              : AppColors.textPrimary),
                    )),
                if (lesson.formattedDuration.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(lesson.formattedDuration,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ],
            ),
          ),

          // Preview label or play icon
          if (lesson.isPreview && !isCompleted)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Free',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
            )
          else if (!isLocked && !isCompleted)
            const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.primary, size: 22),
        ]),
      ),
    );
  }
}

class _NoLessonsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          const Icon(Icons.video_library_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No lessons yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Lessons will appear here once added.',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}