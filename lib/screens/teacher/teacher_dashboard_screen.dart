// lib/screens/teacher/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final teacherName = user?.name ?? 'Teacher';

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: StreamBuilder<List<CourseModel>>(
        stream: _firestoreService.streamTeacherCourses(teacherName),
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
                      'Failed to load dashboard',
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

          // Aggregate statistics dynamically
          final totalCourses = courses.length;
          final totalStudents =
              courses.fold<int>(0, (sum, c) => sum + c.totalStudents);
          final totalLessons =
              courses.fold<int>(0, (sum, c) => sum + c.totalLessons);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient Header ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                surfaceTintColor: AppColors.primary,
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
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.white),
                    onPressed: () => _confirmSignOut(context),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF7C74FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome, $teacherName 👨‍🏫',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your courses and view student progress.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppColors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Statistics Cards Grid ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.85,
                    children: [
                      _buildStatCard('My Courses', totalCourses.toString(),
                          Icons.school_rounded, AppColors.primary, isDark),
                      _buildStatCard('Total Students', totalStudents.toString(),
                          Icons.people_alt_rounded, AppColors.success, isDark),
                      _buildStatCard(
                          'Total Lessons',
                          totalLessons.toString(),
                          Icons.play_circle_fill_rounded,
                          AppColors.accent,
                          isDark),
                    ],
                  ),
                ),
              ),

              // ── Section Header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Curated Courses',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalCourses active',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Courses List ───────────────────────────────────────────
              if (courses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                            child: const Icon(Icons.class_outlined,
                                size: 64, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No courses created yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to publish your first course!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = courses[index];
                        return _buildCourseRowItem(course, isDark)
                            .animate()
                            .fadeIn(
                                duration: 350.ms,
                                delay: Duration(milliseconds: 50 * index))
                            .slideY(begin: 0.05);
                      },
                      childCount: courses.length,
                    ),
                  ),
                ),
            ],
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
        onPressed: () => _showAddCourseSheet(context, teacherName),
      )
          .animate()
          .scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRowItem(CourseModel course, bool isDark) {
    final levelColor = _getLevelColor(course.level);

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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left border indicator corresponding to level
            Container(
              width: 5,
              color: levelColor,
            ),
            // Course Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(course.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Course Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.category,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.level,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: levelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              '${course.totalStudents} stud.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.play_circle_fill_rounded,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              '${course.totalLessons} less.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          course.formattedDuration,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _showAddCourseSheet(BuildContext context, String teacherName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCourseSheet(teacherName: teacherName),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD COURSE BOTTOM SHEET FOR TEACHERS
// ─────────────────────────────────────────────────────────────────────────────
class _AddCourseSheet extends StatefulWidget {
  final String teacherName;
  const _AddCourseSheet({required this.teacherName});

  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80',
  );
  final _durationCtrl = TextEditingController(text: '120');

  String _selectedCategory = 'Development';
  String _selectedLevel = 'Beginner';
  bool _isFeatured = false;
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
    _imgCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Slugify course title for a readable ID and append timestamp
    final courseId =
        '${_titleCtrl.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_').replaceAll(RegExp(r'_+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';

    final course = CourseModel(
      id: courseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: _imgCtrl.text.trim(),
      instructorName: widget.teacherName,
      rating: 4.8, // Set a beautiful default initial rating
      totalLessons: 0,
      totalStudents: 0,
      category: _selectedCategory,
      level: _selectedLevel,
      durationMinutes: int.parse(_durationCtrl.text),
      isFeatured: _isFeatured,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addCourse(course);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      Text('Course "${course.title}" created successfully!')),
            ],
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardDark
              : AppColors.white,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish course: $e')),
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
            'Create New Course ➕',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Course Title',
                      hint: 'e.g. Flutter Masterclass 2026',
                      controller: _titleCtrl,
                      prefixIcon: Icons.title_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Course Description',
                      hint: 'Describe what students will master...',
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Featured Course',
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
                                height: 54,
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
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isFeatured ? 'Yes ⭐' : 'No',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isFeatured
                                            ? AppColors.warning
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: _isFeatured,
                                      activeThumbColor: AppColors.primary,
                                      onChanged: (val) =>
                                          setState(() => _isFeatured = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Thumbnail Image URL',
                      hint: 'Enter unslash or absolute image web url',
                      controller: _imgCtrl,
                      prefixIcon: Icons.image_rounded,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Image URL is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
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
                      label: 'Publish Course',
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
