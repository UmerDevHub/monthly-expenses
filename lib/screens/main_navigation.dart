import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
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
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: PremiumCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kharcha is Locked',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Authenticate to view your monthly budget and logs.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  BouncingButton(
                    onTap: _authenticate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.heroGlow,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Unlock App',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        onAddExpenseTap: () => _openQuickAddSheet(context),
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
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context, isDark),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context, bool isDark) {
    final navItems = [
      _NavItemData(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Overview'),
      _NavItemData(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'History'),
      _NavItemData(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Reports'),
      _NavItemData(icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161D19).withOpacity(0.85) : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                  width: 1.0,
                ),
                boxShadow: isDark ? AppShadows.softDark : AppShadows.softLight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: Home
                  _buildNavItem(0, navItems[0], isDark),
                  // Tab 1: History
                  _buildNavItem(1, navItems[1], isDark),

                  // Center Floating Quick Add FAB
                  BouncingButton(
                    onTap: () => _openQuickAddSheet(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
                  _buildNavItem(2, navItems[2], isDark),
                  // Tab 3: Settings
                  _buildNavItem(3, navItems[3], isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItemData item, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return BouncingButton(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 20,
              color: isSelected ? activeColor : inactiveColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
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

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
