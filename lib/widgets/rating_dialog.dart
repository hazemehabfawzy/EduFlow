import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../services/firestore_service.dart';

class RatingDialog extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String userId;
  final double? existingRating;

  const RatingDialog({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.userId,
    this.existingRating,
  });

  static Future<void> show(
    BuildContext context, {
    required String courseId,
    required String courseTitle,
    required String userId,
    double? existingRating,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        courseId: courseId,
        courseTitle: courseTitle,
        userId: userId,
        existingRating: existingRating,
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _selectedRating = 0;
  bool _isSubmitting = false;
  final FirestoreService _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingRating ?? 0;
  }

  String _ratingLabel(double rating) {
    switch (rating.toInt()) {
      case 1: return '😞  Poor';
      case 2: return '😐  Fair';
      case 3: return '🙂  Good';
      case 4: return '😊  Very Good';
      case 5: return '🤩  Excellent!';
      default: return '';
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    try {
      await _service.submitCourseRating(
        courseId: widget.courseId,
        userId: widget.userId,
        rating: _selectedRating,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Thanks for rating! You gave ${_selectedRating.toInt()} ⭐'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child:
                      Text('🏆', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existingRating != null
                  ? 'Update Your Rating'
                  : 'Rate This Course',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.courseTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedRating = starValue),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 200),
                        child: Icon(
                          _selectedRating >= starValue
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          key: ValueKey(
                              '$starValue-$_selectedRating'),
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRating == 0
                  ? 'Tap a star to rate'
                  : _ratingLabel(_selectedRating),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedRating == 0
                    ? AppColors.textHint
                    : AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedRating == 0 || _isSubmitting
                        ? null
                        : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Submit Rating',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe Later',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
