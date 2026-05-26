// lib/screens/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/shimmer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  late Stream<List<CourseModel>> _coursesStream;
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _coursesStream = context.read<CourseProvider>().streamCourses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Learner';

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
                expandedHeight: 140,
                floating: false,
                pinned: true,
                snap: false,
                forceElevated: innerBoxIsScrolled,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                surfaceTintColor: AppColors.primary,
                actions: [
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
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 80, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hello, $firstName 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'What will you learn today?',
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
            ],
            // ── Scrollable Body ────────────────────────────────────
            body: _buildScrollBody(isDark, snapshot),
          );
        },
      ),
    );
  }

  // ── Main Scroll Body ─────────────────────────────────────────────
  Widget _buildScrollBody(
      bool isDark, AsyncSnapshot<List<CourseModel>> snapshot) {
    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(child: _buildSearchBar(isDark)),

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

  // ── Search Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          fillColor: isDark ? AppColors.cardDark : AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
          child: Text(
            '⭐  Featured',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => CourseCard(
              course: featured[i],
              width: 240,
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ShimmerCourseCard(),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.65,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
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
      await FirebaseAuth.instance.signOut();
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