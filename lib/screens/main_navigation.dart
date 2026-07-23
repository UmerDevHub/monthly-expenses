import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_add_sheet.dart';
import '../services/notification_service.dart';
import '../providers/app_providers.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  bool _isAuthenticated = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    NotificationService.selectNotificationPayload.addListener(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationPayload();
      _checkAppLock();
    });
  }

  Future<void> _checkAppLock() async {
    final settings = ref.read(appSettingsProvider);
    if (settings.appLockEnabled) {
      setState(() {
        _isAuthenticated = false;
      });
      _authenticate();
    } else {
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Unlock Kharcha to manage your expenses',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (didAuthenticate) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  @override
  void dispose() {
    NotificationService.selectNotificationPayload.removeListener(_handleNotificationPayload);
    super.dispose();
  }

  void _handleNotificationPayload() {
    final payload = NotificationService.selectNotificationPayload.value;
    if (payload != null && payload.isNotEmpty) {
      NotificationService.selectNotificationPayload.value = null;
      final parts = payload.split(',');
      if (parts.length == 2) {
        final categoryId = parts[0];
        final amount = double.tryParse(parts[1]) ?? 0.0;
        _openQuickAddSheet(
          context,
          initialCategoryId: categoryId,
          initialAmount: amount,
          isFromRecurring: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCardDark : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: Color(0xFF073826),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kharcha is Locked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF073826),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to access your financial ledger.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073826),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        onAddExpenseTap: () => _openQuickAddSheet(context),
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      HistoryScreen(
        onBackTap: () {
          setState(() {
            _currentIndex = 0;
          });
        },
        onAddExpenseTap: () => _openQuickAddSheet(context),
      ),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F8),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // FLOATING BOTTOM NAVIGATION BAR (Exact screenshot match)
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2622) : Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFEFEFEF),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tab 0: Overview
                  _buildNavItem(
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    label: 'Overview',
                    isDark: isDark,
                  ),

                  // Tab 1: History
                  _buildNavItem(
                    index: 1,
                    icon: Icons.access_time_rounded,
                    label: 'History',
                    isDark: isDark,
                  ),

                  // CENTER FLOATING (+) ADD EXPENSE BUTTON
                  GestureDetector(
                    onTap: () => _openQuickAddSheet(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF073826),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40073826),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  // Tab 2: Reports
                  _buildNavItem(
                    index: 2,
                    icon: Icons.show_chart_rounded,
                    label: 'Reports',
                    isDark: isDark,
                  ),

                  // Tab 3: Settings
                  _buildNavItem(
                    index: 3,
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    if (isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF073826).withOpacity(0.4) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF073826),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF073826),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Icon(
        icon,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
        size: 22,
      ),
    );
  }

  void _openQuickAddSheet(
    BuildContext context, {
    String? initialCategoryId,
    double? initialAmount,
    bool isFromRecurring = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuickAddSheet(
          initialCategoryId: initialCategoryId,
          initialAmount: initialAmount,
          isFromRecurring: isFromRecurring,
        );
      },
    );
  }
}
