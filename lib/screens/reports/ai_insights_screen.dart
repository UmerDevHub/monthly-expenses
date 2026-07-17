import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/hive_service.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../category_detail/category_detail_screen.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  bool _isLoading = false;
  String _loadingMessage = 'Kharcha AI is preparing...';
  Timer? _messageTimer;
  List<String> _insights = [];

  final List<String> _loadingMessages = [
    'Kharcha AI is scanning your logs...',
    'Analyzing category boundaries...',
    'Comparing spends to set limits...',
    'Generating custom savings tips...',
    'Brewing personalized trends...',
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedInsights();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _loadCachedInsights() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final box = HiveService.insightsBox;
    final cached = box.get(selectedMonth);
    if (cached != null) {
      setState(() {
        _insights = cached.insights;
      });
    }
  }

  void _startLoadingAnimation() {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    int msgIndex = 1;
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _loadingMessage = _loadingMessages[msgIndex % _loadingMessages.length];
          msgIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _generateAiInsights(String apiKey) async {
    _startLoadingAnimation();

    final expenses = ref.read(monthlyExpensesProvider);
    final categories = ref.read(categoriesProvider);
    final totalSpent = ref.read(totalSpentProvider);
    final selectedMonth = ref.read(selectedMonthProvider);

    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    try {
      final result = await GeminiService.generateInsights(
        apiKey: apiKey,
        expenses: expenses,
        categories: categories,
        totalSpent: totalSpent,
        monthName: monthName,
      );

      // Save to Hive
      final newInsight = MonthlyInsight(
        monthKey: selectedMonth,
        insights: result,
        generatedAt: DateTime.now(),
      );
      await HiveService.insightsBox.put(selectedMonth, newInsight);

      if (mounted) {
        setState(() {
          _insights = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insights generation failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _messageTimer?.cancel();
    }
  }

  void _showApiKeySheet(AppSettings settings) {
    final controller = TextEditingController(text: settings.geminiApiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Gemini AI Key Setup',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your free Google Gemini API Key to enable automated budgeting recommendations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  helperText: 'Get a key for free from Google AI Studio',
                  helperStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final keyStr = controller.text.trim();
                    ref.read(appSettingsProvider.notifier).updateSettings(
                      settings.copyWith(geminiApiKey: keyStr),
                    );
                    Navigator.pop(context);
                    _loadCachedInsights();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(keyStr.isEmpty ? 'Gemini Key Removed' : 'Gemini Key Configured Successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);
    final hasKey = settings.geminiApiKey != null && settings.geminiApiKey!.trim().isNotEmpty;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kharcha AI Insights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasKey && !_isLoading && _insights.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => _generateAiInsights(settings.geminiApiKey!),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(theme, isDark)
            : !hasKey
                ? _buildSetupState(theme, isDark, settings)
                : _insights.isEmpty
                    ? _buildEmptyState(theme, isDark, settings)
                    : _buildInsightsList(theme, isDark, categories),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium Pulsing AI Spinner
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Shifting Status Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _loadingMessage,
                key: ValueKey(_loadingMessage),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This usually takes about 5-10 seconds.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupState(ThemeData theme, bool isDark, AppSettings settings) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Unlock Smart AI Insights',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kharcha AI uses the Google Gemini API to analyze your category spending, identify high variance, and deliver actionable savings tips directly to your feed.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            _buildSetupStep(
              number: '1',
              title: 'Get a Free API Key',
              description: 'Visit Google AI Studio to generate your free Gemini Developer Key in seconds.',
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSetupStep(
              number: '2',
              title: 'Configure Securely',
              description: 'Save the key locally on your device. It is never uploaded to any external server.',
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _showApiKeySheet(settings),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text(
                  'Set Up Gemini Key',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupStep({
    required String number,
    required String title,
    required String description,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, AppSettings settings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Analysis Generated Yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Click below to trigger a secure analysis of your current month\'s spending logs.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _generateAiInsights(settings.geminiApiKey!),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Generate AI Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList(ThemeData theme, bool isDark, List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: _insights.length + 1,
      itemBuilder: (context, idx) {
        if (idx == _insights.length) {
          // Bottom Disclaimer
          return Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 32.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Insights are generated locally via Gemini API.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final rawText = _insights[idx];
        
        // Parse type and content
        String type = 'TIP';
        String cleanText = rawText;
        IconData icon = Icons.lightbulb_outline;
        Color accentColor = AppColors.primary;

        if (rawText.toLowerCase().contains('alert:')) {
          type = 'ALERT';
          cleanText = rawText.replaceAll(RegExp(r'alert:\s*', caseSensitive: false), '');
          icon = Icons.warning_amber_rounded;
          accentColor = AppColors.danger;
        } else if (rawText.toLowerCase().contains('trend:')) {
          type = 'TREND';
          cleanText = rawText.replaceAll(RegExp(r'trend:\s*', caseSensitive: false), '');
          icon = Icons.trending_up;
          accentColor = const Color(0xFF5A7A9E); // slate blue
        }

        // Try to identify if a category is mentioned to enable deep-linking
        Category? matchedCat;
        for (var cat in categories) {
          if (cleanText.toLowerCase().contains(cat.name.toLowerCase())) {
            matchedCat = cat;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left color bar
                  Container(
                    width: 6,
                    color: accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 16, color: accentColor),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cleanText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          if (matchedCat != null) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryDetailScreen(category: matchedCat!),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View ${matchedCat.name} details',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
