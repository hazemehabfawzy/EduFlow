// lib/screens/lesson/lesson_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/lesson_model.dart';
import '../../models/enrollment_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/rating_dialog.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final FirestoreService _service = FirestoreService();
  bool _isMarkingComplete = false;

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Map<String, dynamic> get _args =>
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

  LessonModel get _lesson => _args['lesson'] as LessonModel;
  List<LessonModel> get _lessons => _args['lessons'] as List<LessonModel>;
  EnrollmentModel? get _enrollment => _args['enrollment'] as EnrollmentModel?;
  String get _courseId => _args['courseId'] as String;

  bool get _isCompleted =>
      _enrollment?.completedLessonIds.contains(_lesson.id) ?? false;

  LessonModel? get _nextLesson {
    final idx = _lessons.indexWhere((l) => l.id == _lesson.id);
    if (idx == -1 || idx >= _lessons.length - 1) return null;
    return _lessons[idx + 1];
  }

  LessonModel? get _prevLesson {
    final idx = _lessons.indexWhere((l) => l.id == _lesson.id);
    if (idx <= 0) return null;
    return _lessons[idx - 1];
  }

  int get _currentIndex => _lessons.indexWhere((l) => l.id == _lesson.id) + 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      endDrawer: _buildLessonDrawer(isDark),
      body: Column(
        children: [
          _buildHeader(isDark),
          if (_lesson.videoUrl.isNotEmpty) _buildVideoSection(isDark),
          Expanded(child: _buildNotes(isDark)),
          _buildActionBar(isDark),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.cardDark : AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + progress label
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Lesson $_currentIndex of ${_lessons.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_lesson.formattedDuration.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppColors.textHint, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _lesson.formattedDuration,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ]),
                  const SizedBox(width: 12),
                ],
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.playlist_play_rounded,
                          size: 24, color: AppColors.primary),
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      tooltip: 'Show Lessons Outline',
                    );
                  },
                ),
              ]),
            ),

            // Lesson title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                _lesson.title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: _lessons.isEmpty ? 0.0 : _currentIndex / _lessons.length,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes ───────────────────────────────────────────────────────────────────
  Widget _buildNotes(bool isDark) {
    if (_lesson.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded,
                size: 56, color: AppColors.textHint.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No notes for this lesson',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 6),
            Text("The instructor hasn't added notes yet.",
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes label
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notes_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Lesson Notes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                )),
          ]),
          const SizedBox(height: 16),

          // Notes content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
            ),
            child: Text(
              _lesson.notes,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.8,
                color:
                    isDark ? const Color(0xFFB0B8C4) : AppColors.textSecondary,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  // ── Action Bar ──────────────────────────────────────────────────────────────
  Widget _buildActionBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Take Quiz button
          StreamBuilder<List<dynamic>>(
            stream: _service.streamLessonQuizzes(_lesson.id),
            builder: (context, snapshot) {
              final quizzes = snapshot.data ?? [];
              if (quizzes.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GradientButton(
                  label: 'Take Quiz (${quizzes.length} questions)',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.quiz,
                      arguments: {
                        'lessonId': _lesson.id,
                        'courseId': _courseId,
                        'courseTitle': _lesson.title,
                        'userId': _enrollment?.userId ?? '',
                      },
                    );
                  },
                  gradientColors: const [AppColors.secondary, AppColors.accent],
                  icon: const Icon(Icons.quiz_rounded,
                      color: AppColors.white, size: 18),
                ),
              );
            },
          ),
          // Mark complete
          if (_enrollment != null && !_isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GradientButton(
                label: 'Mark as Completed',
                isLoading: _isMarkingComplete,
                onPressed: _isMarkingComplete ? null : _markComplete,
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.white, size: 18),
              ),
            ),

          if (_isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('Lesson Completed!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        )),
                  ],
                ),
              ),
            ),

          // Prev / Next
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevLesson == null ? null : _goToPrev,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: _prevLesson == null
                        ? AppColors.textHint.withOpacity(0.3)
                        : AppColors.primary,
                    width: 1.5,
                  ),
                  foregroundColor: _prevLesson == null
                      ? AppColors.textHint
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextLesson == null ? null : _goToNext,
                icon: const Text('Next'),
                label: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: _nextLesson == null
                      ? AppColors.textHint
                      : AppColors.primary,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  void _goToNext() {
    if (_nextLesson == null) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.lesson,
      arguments: {
        'lesson': _nextLesson!,
        'lessons': _lessons,
        'enrollment': _enrollment,
        'courseId': _courseId,
      },
    );
  }

  void _goToPrev() {
    if (_prevLesson == null) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.lesson,
      arguments: {
        'lesson': _prevLesson!,
        'lessons': _lessons,
        'enrollment': _enrollment,
        'courseId': _courseId,
      },
    );
  }

  Future<void> _markComplete() async {
    if (_enrollment == null) return;
    setState(() => _isMarkingComplete = true);
    try {
      await _service.markLessonComplete(
        enrollmentId: _enrollment!.id,
        lessonId: _lesson.id,
        totalLessons: _lessons.length,
        currentCompleted: _enrollment!.completedLessonIds,
      );

      final newCompleted =
          _enrollment!.completedLessonIds.length + 1;
      final isNowComplete = newCompleted >= _lessons.length;

      if (isNowComplete && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Text('🎉 Course completed! '),
            Expanded(child: Text('Amazing work!')),
          ]),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));

        // Create a notification for the course completion
        try {
          final courseObj = await _service.fetchCourse(_courseId);
          final courseTitle = courseObj?.title ?? 'the course';
          unawaited(_service.notifyStudentCourseComplete(
            studentId: _enrollment!.userId,
            courseTitle: courseTitle,
            courseId: _courseId,
          ));
        } catch (e) {
          print('[LessonScreen] Course completion notification error: $e');
        }

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          final userId = _enrollment!.userId;
          final existingRating = await _service.getUserRating(
            courseId: _courseId,
            userId: userId,
          );
          if (mounted) {
            await RatingDialog.show(
              context,
              courseId: _courseId,
              courseTitle: _lesson.title,
              userId: userId,
              existingRating: existingRating,
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline,
                color: AppColors.success),
            SizedBox(width: 10),
            Text('Lesson marked as completed!'),
          ]),
          behavior: SnackBarBehavior.floating,
        ));
        if (_nextLesson != null) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) _goToNext();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  Widget _buildLessonDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lessons Outline 📚',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jump between course lectures',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                itemCount: _lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  final isCurrent = lesson.id == _lesson.id;
                  final isCompleted =
                      _enrollment?.completedLessonIds.contains(lesson.id) ??
                          false;

                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary.withOpacity(0.08)
                          : isDark
                              ? AppColors.cardDark
                              : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: isCurrent
                            ? AppColors.primary
                            : AppColors.textHint.withOpacity(0.15),
                        child: Text(
                          (index + 1).toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      title: Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lesson.formattedDuration,
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                      trailing: isCompleted
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18)
                          : const Icon(Icons.radio_button_unchecked_rounded,
                              color: AppColors.textHint, size: 18),
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (!isCurrent) {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.lesson,
                            arguments: {
                              'lesson': lesson,
                              'lessons': _lessons,
                              'enrollment': _enrollment,
                              'courseId': _courseId,
                            },
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () async {
          try {
            String videoUrlStr = _lesson.videoUrl.trim().replaceAll(' ', '');
            if (!videoUrlStr.startsWith('http://') && !videoUrlStr.startsWith('https://')) {
              videoUrlStr = 'https://$videoUrlStr';
            }
            final url = Uri.parse(videoUrlStr);
            bool success = await launchUrl(url, mode: LaunchMode.platformDefault);
            if (!success) {
              success = await launchUrl(url, mode: LaunchMode.externalApplication);
            }
            if (!success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open video URL')),
              );
            }
          } catch (e) {
            try {
              String videoUrlStr = _lesson.videoUrl.trim().replaceAll(' ', '');
              if (!videoUrlStr.startsWith('http://') && !videoUrlStr.startsWith('https://')) {
                videoUrlStr = 'https://$videoUrlStr';
              }
              final url = Uri.parse(videoUrlStr);
              await launchUrl(url);
            } catch (innerError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open video: $innerError')),
                );
              }
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.9),
                AppColors.accent.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch Video Lesson',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to open video in browser',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
