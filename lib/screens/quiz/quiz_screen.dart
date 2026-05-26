// lib/screens/quiz/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../models/quiz_model.dart';
import '../../widgets/gradient_button.dart';

/// Quiz screen receives a Map argument:
/// { 'courseId': String, 'courseTitle': String }
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  List<QuizModel> _questions = [];
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  int? _selectedOption;          // null = not answered yet
  bool _answered = false;        // true after tapping an option
  List<int?> _userAnswers = [];  // stores selected index per question

  Timer? _timer;
  int _secondsLeft = 30;         // per-question timer

  late final AnimationController _shakeCtrl;

  // ── Init ────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _loadQuestions(args['courseId'] as String);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<void> _loadQuestions(String courseId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();

      final questions = snap.docs
          .map((d) => QuizModel.fromMap(d.data(), d.id))
          .toList();

      setState(() {
        _questions = questions;
        _userAnswers = List.filled(questions.length, null);
        _loading = false;
      });

      if (questions.isNotEmpty) _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Timer ────────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_answered) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          // Time's up — auto-mark as wrong
          _selectOption(-1); // -1 = timed out
        }
      });
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    _timer?.cancel();

    setState(() {
      _selectedOption = index;
      _answered = true;
      _userAnswers[_currentIndex] = index;
    });

    // Shake animation on wrong answer
    final correct = _questions[_currentIndex].correctAnswer;
    if (index != correct) {
      _shakeCtrl.forward(from: 0);
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      _showResultDialog();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = _userAnswers[_currentIndex];
      _answered = _selectedOption != null;
    });
    if (!_answered) _startTimer();
  }

  void _prevQuestion() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      _selectedOption = _userAnswers[_currentIndex];
      _answered = _selectedOption != null;
    });
  }

  // ── Score Calculation ────────────────────────────────────────────────────────
  int get _score {
    int s = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctAnswer) s++;
    }
    return s;
  }

  double get _scorePercent =>
      _questions.isEmpty ? 0 : _score / _questions.length;

  bool get _passed => _scorePercent >= 0.7; // 70% to pass

  // ── Result Dialog ────────────────────────────────────────────────────────────
  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        score: _score,
        total: _questions.length,
        percent: _scorePercent,
        passed: _passed,
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _currentIndex = 0;
            _selectedOption = null;
            _answered = false;
            _userAnswers = List.filled(_questions.length, null);
          });
          _startTimer();
        },
        onExit: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // back to course detail
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final courseTitle = args['courseTitle'] as String? ?? 'Quiz';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _loading
            ? const _LoadingState()
            : _error != null
                ? _ErrorState(message: _error!, onRetry: () {})
                : _questions.isEmpty
                    ? const _EmptyState()
                    : _buildQuizBody(courseTitle),
      ),
    );
  }

  Widget _buildQuizBody(String courseTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = _questions[_currentIndex];

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────
        _buildHeader(courseTitle, isDark),

        // ── Progress bar ─────────────────────────────────────────────────
        _buildProgressBar(),

        // ── Scrollable question area ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Question card
                _buildQuestionCard(question, isDark)
                    .animate(key: ValueKey(_currentIndex))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05),

                const SizedBox(height: 24),

                // Options
                ...List.generate(question.options.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOptionTile(
                      option: question.options[i],
                      index: i,
                      correctIndex: question.correctAnswer,
                      isDark: isDark,
                    )
                        .animate(key: ValueKey('opt_${_currentIndex}_$i'))
                        .fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 60 * i))
                        .slideX(begin: 0.05),
                  );
                }),

                // Explanation (shown after answering)
                if (_answered && question.explanation != null)
                  _buildExplanation(question.explanation!, isDark)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1),
              ],
            ),
          ),
        ),

        // ── Bottom nav ────────────────────────────────────────────────────
        _buildBottomBar(isDark),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(String courseTitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          color: isDark ? AppColors.white : AppColors.textPrimary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(courseTitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                  )),
              Text('Question ${_currentIndex + 1} of ${_questions.length}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),

        // Circular countdown timer
        _TimerCircle(
          secondsLeft: _secondsLeft,
          total: 30,
          answered: _answered,
        ),
      ]),
    );
  }

  // ── Progress bar (dots) ──────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(_questions.length, (i) {
          Color color;
          if (i < _currentIndex) {
            color = _userAnswers[i] == _questions[i].correctAnswer
                ? AppColors.success
                : AppColors.error;
          } else if (i == _currentIndex) {
            color = AppColors.primary;
          } else {
            color = AppColors.textHint.withOpacity(0.3);
          }

          return Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Question card ────────────────────────────────────────────────────────────
  Widget _buildQuestionCard(QuizModel question, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.accent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Q${_currentIndex + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(question.question,
              style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600,
                color: AppColors.white, height: 1.5,
              )),
        ],
      ),
    );
  }

  // ── Option tile ──────────────────────────────────────────────────────────────
  Widget _buildOptionTile({
    required String option,
    required int index,
    required int correctIndex,
    required bool isDark,
  }) {
    // Determine visual state
    Color borderColor;
    Color bgColor;
    Color textColor;
    Widget? trailingIcon;

    if (!_answered) {
      // Default state
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      bgColor = isDark ? AppColors.cardDark : AppColors.white;
      textColor = isDark ? AppColors.white : AppColors.textPrimary;
    } else {
      if (index == correctIndex) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.08);
        textColor = AppColors.success;
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 20);
      } else if (index == _selectedOption && index != correctIndex) {
        borderColor = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.08);
        textColor = AppColors.error;
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 20);
      } else {
        borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        bgColor = isDark ? AppColors.cardDark : AppColors.white;
        textColor = AppColors.textHint;
      }
    }

    final optionLetters = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: _answered ? null : () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _selectedOption == index && _answered
              ? [
                  BoxShadow(
                    color: (index == correctIndex
                            ? AppColors.success
                            : AppColors.error)
                        .withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          // Option letter bubble
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _answered && index == correctIndex
                  ? AppColors.success
                  : _answered &&
                          index == _selectedOption &&
                          index != correctIndex
                      ? AppColors.error
                      : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(optionLetters[index % 4],
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: _answered &&
                            (index == correctIndex || index == _selectedOption)
                        ? AppColors.white
                        : AppColors.primary,
                  )),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(option,
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: textColor,
                )),
          ),
          if (trailingIcon != null) trailingIcon,
        ]),
      ),
    );
  }

  // ── Explanation ──────────────────────────────────────────────────────────────
  Widget _buildExplanation(String explanation, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.info.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explanation',
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    )),
                const SizedBox(height: 4),
                Text(explanation,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, height: 1.6,
                      color: isDark
                          ? const Color(0xFFB0B8C4)
                          : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
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
      child: Row(children: [
        if (_currentIndex > 0) ...[
          OutlinedButton(
            onPressed: _prevQuestion,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              foregroundColor: AppColors.primary,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GradientButton(
            label: !_answered
                ? 'Select an answer'
                : isLast
                    ? 'See Results 🎯'
                    : 'Next Question',
            onPressed: _answered ? _nextQuestion : null,
            gradientColors: isLast && _answered
                ? [AppColors.secondary, AppColors.primary]
                : null,
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESULT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _ResultDialog extends StatelessWidget {
  final int score;
  final int total;
  final double percent;
  final bool passed;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _ResultDialog({
    required this.score,
    required this.total,
    required this.percent,
    required this.passed,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (percent * 100).toInt();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy / fail icon
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: (passed ? AppColors.success : AppColors.error)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  passed ? '🏆' : '😔',
                  style: const TextStyle(fontSize: 44),
                ),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut)
                .fadeIn(),

            const SizedBox(height: 20),

            Text(
              passed ? 'You Passed!' : 'Keep Trying!',
              style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: passed ? AppColors.success : AppColors.error,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 8),

            Text(
              passed
                  ? 'Great work! You scored $pct%'
                  : 'You scored $pct%. Need 70% to pass.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 24),

            // Score breakdown
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ScoreStat(
                      label: 'Correct',
                      value: '$score',
                      color: AppColors.success),
                  _ScoreStat(
                      label: 'Wrong',
                      value: '${total - score}',
                      color: AppColors.error),
                  _ScoreStat(
                      label: 'Score',
                      value: '$pct%',
                      color: passed ? AppColors.success : AppColors.error),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Buttons
            GradientButton(
              label: 'Exit Quiz',
              onPressed: onExit,
              gradientColors: passed
                  ? [AppColors.success, AppColors.accent]
                  : [AppColors.primary, AppColors.accent],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms),

            const SizedBox(height: 10),

            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 650.ms),
          ],
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

// ── Timer Widget ──────────────────────────────────────────────────────────────
class _TimerCircle extends StatelessWidget {
  final int secondsLeft;
  final int total;
  final bool answered;

  const _TimerCircle({
    required this.secondsLeft,
    required this.total,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final progress = answered ? 1.0 : secondsLeft / total;
    final color = answered
        ? AppColors.success
        : secondsLeft <= 10
            ? AppColors.error
            : AppColors.primary;

    return SizedBox(
      width: 44, height: 44,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
          strokeWidth: 3,
        ),
        Text(
          answered ? '✓' : '$secondsLeft',
          style: GoogleFonts.poppins(
            fontSize: answered ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ]),
    );
  }
}

// ── Loading / empty / error states ────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 16),
        Text('Loading questions…'),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.quiz_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 20),
          Text('No questions yet',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Quiz questions will appear here once added.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load quiz',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}