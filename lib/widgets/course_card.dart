import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants/app_colors.dart';
import '../models/course_model.dart';

/// Reusable course card used in the Home grid and search results.
/// Tapping navigates to Course Detail; the [onTap] callback is required.
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  final double? width;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelColor = _levelColor(course.level);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Thumbnail ─────────────────────────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _CourseThumbnail(imageUrl: course.imageUrl),
                          // "Popular" badge overlay
                          if (course.totalStudents > 500)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Popular',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Info ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Instructor
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.instructorName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Rating + lessons + duration row
                        Row(
                          children: [
                            // Star rating
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Lessons count
                            const Icon(Icons.play_circle_outline_rounded, size: 13, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '${course.totalLessons} less.',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            const Spacer(),

                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course.level,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Left border accent
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  color: levelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return AppColors.success;
      case 'intermediate': return AppColors.warning;
      case 'advanced': return AppColors.error;
      default: return AppColors.primary;
    }
  }
}

/// Thumbnail with placeholder gradient and network image using animated Shimmers.
class _CourseThumbnail extends StatelessWidget {
  final String imageUrl;
  const _CourseThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _shimmerPlaceholder(context);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, __) => _shimmerPlaceholder(context),
      errorWidget: (context, __, ___) => _shimmerPlaceholder(context),
    );
  }

  Widget _shimmerPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A4A) : const Color(0xFFE8E8F0);
    final high = isDark ? const Color(0xFF3A3A5A) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: high,
      child: Container(
        color: base,
        child: const Center(
          child: Icon(Icons.school_rounded, color: Colors.white30, size: 36),
        ),
      ),
    );
  }
}