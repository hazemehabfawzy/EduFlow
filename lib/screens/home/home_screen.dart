// lib/screens/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  int _bottomNavIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),

    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────────
  
  // ── Body (CustomScrollView with Slivers) ────────────────────────────────────
  Widget _buildBody() {
    return StreamBuilder<List<CourseModel>>(
      stream: context.read<CourseProvider>().streamCourses(),
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            if (!snapshot.hasData || snapshot.data!.isNotEmpty)
              SliverToBoxAdapter(
                  child: _buildFeaturedBanner(snapshot.data ?? [])),
            SliverToBoxAdapter(child: _buildSectionHeader()),
            _buildCoursesGrid(snapshot),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  // ── Sliver AppBar ───────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar() {
    final user      = context.watch<AuthProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Learner';
    final isDark    = Theme.of(context).brightness == Brightness.dark;

return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      elevation: 0,
      actions: [
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout_rounded, color: AppColors.white),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
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
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.auth  , (_) => false);
            }
          },
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 100, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $firstName 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ))
                      .animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text('What will you learn today?',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.white.withOpacity(0.8),
                      ))
                      .animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (q) {
          context.read<CourseProvider>().search(q);
          setState(() {});
        },
        style: GoogleFonts.dmSans(
          color: isDark ? AppColors.white : AppColors.textPrimary),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1);
  }

  // ── Categories ──────────────────────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final categories = context.watch<CourseProvider>().categories;
    final selected   = context.watch<CourseProvider>().selectedCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Text('Categories',
              style: Theme.of(context).textTheme.titleLarge),
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
              onTap: () =>
                  context.read<CourseProvider>().selectCategory(categories[i]),
              icon: _categoryIcon(categories[i]),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'all':          return Icons.apps_rounded;
      case 'programming':  return Icons.code_rounded;
      case 'design':       return Icons.palette_rounded;
      case 'business':     return Icons.business_center_rounded;
      case 'marketing':    return Icons.campaign_rounded;
      case 'data science': return Icons.analytics_rounded;
      case 'music':        return Icons.music_note_rounded;
      default:             return Icons.school_rounded;
    }
  }

  // ── Featured Banner (horizontal scroll) ─────────────────────────────────────
  Widget _buildFeaturedBanner(List<CourseModel> courses) {
    final featured = courses.where((c) => c.isFeatured).take(4).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⭐  Featured',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => CourseCard(
              course: featured[i],
              width: 260,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.courseDetail,
                arguments: featured[i],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    final selected = context.watch<CourseProvider>().selectedCategory;
    final query    = context.watch<CourseProvider>().searchQuery;
    final count    = context.watch<CourseProvider>().courses.length;

    String title = selected == 'All' ? 'All Courses' : selected;
    if (query.isNotEmpty) title = 'Results for "$query"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count courses',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Courses Grid ────────────────────────────────────────────────────────────
 // ── Courses Section ──────────────────────────────────────────────────────────
Widget _buildCoursesGrid(AsyncSnapshot<List<CourseModel>> snapshot) {
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
          childAspectRatio: 0.62,
        ),
      ),
    );
  }

  if (snapshot.hasError) {
    return SliverToBoxAdapter(
      child: _ErrorState(message: snapshot.error.toString()),
    );
  }

  final provider = context.watch<CourseProvider>();
  final courses  = provider.courses;

  if (courses.isEmpty) {
    return const SliverToBoxAdapter(
      child: _EmptyState(),
    );
  }

return SliverToBoxAdapter(
  child: SizedBox(
    height: 260,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, i) {
        return CourseCard(
          width: 260,
          course: courses[i],
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.courseDetail,
            arguments: courses[i],
          ),
        )
            .animate()
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: 60 * i),
            )
            .slideX(begin: 0.08);
      },
    ),
  ),
);
}

}

// ── Empty / Error states ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('No courses found',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Try adjusting your search\nor select a different category.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text('Failed to load courses',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}