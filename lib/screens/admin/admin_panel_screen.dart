// lib/screens/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Admin Console',
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
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: _firestoreService.streamAllCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load courses',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final courses = snapshot.data ?? [];

          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No courses available',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first course using the floating action button below!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseAdminCard(course, isDark)
                  .animate()
                  .fadeIn(
                      duration: 350.ms,
                      delay: Duration(milliseconds: 50 * index))
                  .slideY(begin: 0.08);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text(
          'Add Course',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        onPressed: () => _showAddCourseSheet(context),
      )
          .animate()
          .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildCourseAdminCard(CourseModel course, bool isDark) {
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
          // Banner Image & Metadata
          Stack(
            children: [
              Image.network(
                course.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_rounded,
                        color: AppColors.primary, size: 36),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.category,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.level,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Instructor: ${course.instructorName}',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    height: 1),
                const SizedBox(height: 12),

                // Statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${course.totalStudents} Enrolled',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${course.durationMinutes}m duration',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1.5,
                          ),
                        ),
                        icon: const Icon(Icons.group_rounded,
                            size: 18, color: AppColors.primary),
                        label: Text(
                          'Enrollments',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        onPressed: () => _showEnrollmentsSheet(context, course),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                            width: 1.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 22),
                        onPressed: () => _confirmDeleteCourse(context, course),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Show Enrollments Bottom Sheet ──────────────────────────────────────────
  void _showEnrollmentsSheet(BuildContext context, CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enrolled Students',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<EnrollmentModel>>(
                      stream:
                          _firestoreService.streamCourseEnrollments(course.id),
                      builder: (context, enrollSnap) {
                        if (enrollSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary));
                        }

                        final enrollments = enrollSnap.data ?? [];

                        if (enrollments.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline_rounded,
                                    size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  'No students enrolled yet',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: controller,
                          itemCount: enrollments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final enrollment = enrollments[idx];
                            return FutureBuilder<UserModel?>(
                              future: _firestoreService
                                  .fetchUser(enrollment.userId),
                              builder: (context, userSnap) {
                                if (userSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  );
                                }

                                final student = userSnap.data;
                                final studentName =
                                    student?.name ?? 'Unknown Student';
                                final studentEmail =
                                    student?.email ?? 'No Email';

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppColors.primary
                                                .withOpacity(0.1),
                                            radius: 20,
                                            child: Text(
                                              studentName.isNotEmpty
                                                  ? studentName[0].toUpperCase()
                                                  : 'S',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  studentName,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  studentEmail,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: enrollment.progress,
                                                minHeight: 6,
                                                backgroundColor: isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.borderLight,
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                        AppColors.success),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${(enrollment.progress * 100).toInt()}%',
                                            style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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

  // ── Confirm Delete Dialog ──────────────────────────────────────────────────
  void _confirmDeleteCourse(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Course?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete "${course.title}"? This will permanently delete the course, all associated lessons, quizzes, and student enrollments.',
            style: GoogleFonts.dmSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting course...')),
                );
                try {
                  await _firestoreService.deleteCourse(course.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Course successfully deleted.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete course: $e')),
                  );
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Show Add Course Dialog ─────────────────────────────────────────────────
  void _showAddCourseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddCourseSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD COURSE BOTTOM SHEET (With beautiful presets)
// ─────────────────────────────────────────────────────────────────────────────
class _AddCourseSheet extends StatefulWidget {
  const _AddCourseSheet();

  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers (Pre-populated with high-quality mock data for instant verification)
  final _titleCtrl =
      TextEditingController(text: 'Full-Stack Development with Node.js');
  final _descCtrl = TextEditingController(
      text:
          'Learn to build scalable backend systems, design robust APIs, and manage production databases using Node.js, Express, and MongoDB.');
  final _instructorCtrl = TextEditingController(text: 'Dr. Hazem Ehab');
  final _imgCtrl = TextEditingController(
      text:
          'https://images.unsplash.com/photo-1541462608143-67571c6738dd?auto=format&fit=crop&w=600&q=80');
  final _durationCtrl = TextEditingController(text: '180');

  String _selectedCategory = 'Development';
  String _selectedLevel = 'Intermediate';
  bool _isLoading = false;

  final List<String> _categories = [
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Data Science'
  ];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _instructorCtrl.dispose();
    _imgCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final courseId = _titleCtrl.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final course = CourseModel(
      id: courseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: _imgCtrl.text.trim(),
      instructorName: _instructorCtrl.text.trim(),
      rating: 0.0,
      totalLessons: 0,
      totalStudents: 0,
      category: _selectedCategory,
      level: _selectedLevel,
      durationMinutes: int.parse(_durationCtrl.text),
      isFeatured: false,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addCourse(course);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Course "${course.title}" successfully created!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating course: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create New Course',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Course Title',
                      hint: 'Enter course title',
                      controller: _titleCtrl,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Description',
                      hint: 'Enter course description',
                      controller: _descCtrl,
                      prefixIcon: Icons.description_rounded,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Instructor Name',
                            hint: 'Enter instructor name',
                            controller: _instructorCtrl,
                            prefixIcon: Icons.person_rounded,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Instructor is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Duration (Minutes)',
                            hint: '120',
                            controller: _durationCtrl,
                            prefixIcon: Icons.schedule_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (int.tryParse(v) == null) {
                                return 'Must be a number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Image URL',
                      hint: 'Enter image URL',
                      controller: _imgCtrl,
                      prefixIcon: Icons.image_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Image URL is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns (Category and Level)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    icon: const Icon(
                                        Icons.arrow_drop_down_rounded),
                                    dropdownColor: isDark
                                        ? AppColors.cardDark
                                        : AppColors.white,
                                    items: _categories.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCategory = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedLevel,
                                    isExpanded: true,
                                    icon: const Icon(
                                        Icons.arrow_drop_down_rounded),
                                    dropdownColor: isDark
                                        ? AppColors.cardDark
                                        : AppColors.white,
                                    items: _levels.map((l) {
                                      return DropdownMenuItem(
                                        value: l,
                                        child: Text(
                                          l,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedLevel = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      label: 'Create Course',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
