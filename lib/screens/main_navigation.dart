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
      // If biometrics fail completely/not supported, allow access as fallback or keep locked
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 64,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kharcha is Locked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
          selectedItemColor: isDark ? AppColors.primaryDark : AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          selectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.history_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.history),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.analytics_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.analytics),
              ),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.settings_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.settings),
              ),
              label: 'Settings',
            ),
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
