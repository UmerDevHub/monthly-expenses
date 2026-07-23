import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/hive_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../recurring_expenses/recurring_expenses_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Temporary states for text sizes and locks
  String _selectedTextSize = 'Medium';
  String _selectedAutoLock = '1 minute';
  bool _budgetAlerts = true;
  bool _weeklySummaries = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Text(
                  'Settings',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your preferences and app settings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Profile Card (Interactive)
                GestureDetector(
                  onTap: () => _showNameEditSheet(context, settings),
                  child: _buildProfileCard(settings, theme, isDark),
                ),
                const SizedBox(height: 24),

                // 3. Preferences Group
                _buildGroupHeader('Preferences', theme, isDark),
                _buildGroupContainer(
                  isDark: isDark,
                  children: [
                    _buildSettingRow(
                      icon: Icons.monetization_on_outlined,
                      iconBgColor: const Color(0xFFF1F6EE),
                      iconColor: const Color(0xFF7A9E5A),
                      title: 'Currency',
                      description: 'Select your preferred currency',
                      value: settings.currency,
                      onTap: () => _showCurrencySheet(context, settings),
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBgColor: const Color(0xFFF1F6EE),
                      iconColor: const Color(0xFF7A9E5A),
                      title: 'Monthly Budget (Overall)',
                      description: 'Set your overall monthly spending limit',
                      value: CurrencyFormatter.format(settings.overallMonthlyLimit ?? 5000.0, settings.currency, decimalDigits: 0),
                      onTap: () => _showBudgetLimitSheet(context, settings),
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),

                    _buildSettingRow(
                      icon: Icons.track_changes_outlined,
                      iconBgColor: const Color(0xFFFEF5EE),
                      iconColor: const Color(0xFFE47C38),
                      title: 'Budget by Category',
                      description: 'Set monthly limits for each category',
                      onTap: () => _showCategoryBudgetsSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.access_time_outlined,
                      iconBgColor: const Color(0xFFFFFBEA),
                      iconColor: const Color(0xFFECAE35),
                      title: 'Recurring Expenses',
                      description: 'Manage fixed expenses and reminders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecurringExpensesScreen(),
                          ),
                        );
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.local_offer_outlined,
                      iconBgColor: const Color(0xFFEEF6F8),
                      iconColor: const Color(0xFF3F8B9C),
                      title: 'Categories',
                      description: 'Manage your categories, icons and colors',
                      onTap: () => _showCategoriesManagementSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Security Group
                _buildGroupHeader('Security', theme, isDark),
                _buildGroupContainer(
                  isDark: isDark,
                  children: [
                    _buildSettingRow(
                      icon: Icons.fingerprint_outlined,
                      iconBgColor: const Color(0xFFF2EEF6),
                      iconColor: const Color(0xFF8F63AC),
                      title: 'App Lock',
                      description: 'Protect your data with fingerprint',
                      control: Switch(
                        value: settings.appLockEnabled,
                        activeTrackColor: AppColors.primary,
                        activeColor: Colors.white,
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).updateSettings(
                            settings.copyWith(appLockEnabled: val),
                          );
                        },
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.shield_outlined,
                      iconBgColor: const Color(0xFFF1F6EE),
                      iconColor: const Color(0xFF7A9E5A),
                      title: 'Auto Lock',
                      description: 'Lock app after 1 minute of inactivity',
                      value: _selectedAutoLock,
                      onTap: () => _showAutoLockSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Appearance Group
                _buildGroupHeader('Appearance', theme, isDark),
                _buildGroupContainer(
                  isDark: isDark,
                  children: [
                    _buildSettingRow(
                      icon: Icons.dark_mode_outlined,
                      iconBgColor: const Color(0xFFEEF1F6),
                      iconColor: const Color(0xFF5A78A6),
                      title: 'Dark Mode',
                      description: 'Switch between light and dark theme',
                      control: Switch(
                        value: settings.darkMode,
                        activeTrackColor: AppColors.primary,
                        activeColor: Colors.white,
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).updateSettings(
                            settings.copyWith(darkMode: val),
                          );
                        },
                      ),
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.text_fields_outlined,
                      iconBgColor: const Color(0xFFF1F6EE),
                      iconColor: const Color(0xFF7A9E5A),
                      title: 'Text Size',
                      description: 'Adjust text size for better readability',
                      value: _selectedTextSize,
                      onTap: () => _showTextSizeSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. Notifications & Insights Group
                _buildGroupHeader('Notifications & Insights', theme, isDark),
                _buildGroupContainer(
                  isDark: isDark,
                  children: [
                    _buildSettingRow(
                      icon: Icons.notifications_none_outlined,
                      iconBgColor: const Color(0xFFFEF5EE),
                      iconColor: const Color(0xFFE47C38),
                      title: 'Notifications',
                      description: 'Manage budget alerts and reminders',
                      onTap: () => _showNotificationsSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. Data & More Group
                _buildGroupHeader('Data & More', theme, isDark),
                _buildGroupContainer(
                  isDark: isDark,
                  children: [
                    _buildSettingRow(
                      icon: Icons.article_outlined,
                      iconBgColor: const Color(0xFFF1F6EE),
                      iconColor: const Color(0xFF7A9E5A),
                      title: 'Export Monthly Report',
                      description: 'Download your monthly report as PDF',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please navigate to the Reports tab to generate PDFs.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      theme: theme,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.cloud_sync_outlined,
                      iconBgColor: const Color(0xFFEEF1F6),
                      iconColor: const Color(0xFF5A78A6),
                      title: 'JSON Backup & Restore',
                      description: 'Export data to JSON file or restore past backups',
                      value: 'Available',
                      onTap: () => _showBackupRestoreSheet(context),
                      theme: theme,
                      isDark: isDark,
                    ),

                    _buildDivider(isDark),
                    _buildSettingRow(
                      icon: Icons.info_outline,
                      iconBgColor: const Color(0xFFFFFBEA),
                      iconColor: const Color(0xFFECAE35),
                      title: 'About Kharcha',
                      description: 'App version, terms and privacy policy',
                      onTap: () => _showAboutDialog(context),
                      theme: theme,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 110),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppSettings settings, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Custom Drawn Vector Profile Avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE1ECE3),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Shirt
                Positioned(
                  bottom: -10,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4C6E53),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                ),
                // Head
                Align(
                  alignment: const Alignment(0, -0.3),
                  child: Container(
                    width: 30,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9D1B9),
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),
                // Hair
                Positioned(
                  top: 8,
                  left: 14,
                  right: 14,
                  child: Container(
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2520),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Neck
                Align(
                  alignment: const Alignment(0, 0.4),
                  child: Container(
                    width: 8,
                    height: 10,
                    color: const Color(0xFFE5BCA7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Personal Account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // Shield Local Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E281F) : const Color(0xFFF1F6EE),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E4D33) : const Color(0xFFC7DAC1),
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 11,
                        color: isDark ? const Color(0xFF7A9E5A) : const Color(0xFF4C6E53),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Local Data Only',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF7A9E5A) : const Color(0xFF4C6E53),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_outlined,
            size: 18,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF9EBF85) : const Color(0xFF4C6E53),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String description,
    String? value,
    Widget? badge,
    Widget? control,
    VoidCallback? onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? iconColor.withOpacity(0.08) : iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 11,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: control ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            badge,
            const SizedBox(width: 8),
          ],
          if (value != null) ...[
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right,
            size: 16,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ],
      ),
      onTap: control == null ? onTap : null,
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1. EDIT PROFILE NAME
  void _showNameEditSheet(BuildContext context, AppSettings settings) {
    final controller = TextEditingController(text: settings.userName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Update Profile Name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This name is stored locally and will be shown on the home dashboard greeting.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      ref.read(appSettingsProvider.notifier).updateSettings(
                        settings.copyWith(userName: newName),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile name updated to $newName'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Update Name'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. CURRENCY SHEET
  void _showCurrencySheet(BuildContext context, AppSettings settings) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Display Currency',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Base Currency is QAR. Switching to PKR applies 1 QAR = 74.03 PKR exchange rate.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: settings.currency == 'QAR'
                    ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFE8F3EE))
                    : null,
                leading: const Text('🇶🇦', style: TextStyle(fontSize: 28)),
                title: const Text('Qatari Riyal (QAR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Default Base Currency'),
                trailing: settings.currency == 'QAR' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                    settings.copyWith(currency: 'QAR'),
                  );
                  ref.read(historyLogProvider.notifier).addLog(
                    title: 'Currency Changed',
                    description: 'Switched active display currency to QAR (Qatari Riyal).',
                    actionType: 'settings_changed',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Display currency set to QAR'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: settings.currency == 'PKR'
                    ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFE8F3EE))
                    : null,
                leading: const Text('🇵🇰', style: TextStyle(fontSize: 28)),
                title: const Text('Pakistani Rupee (PKR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Converted at 1 QAR = 74.03 PKR'),
                trailing: settings.currency == 'PKR' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                    settings.copyWith(currency: 'PKR'),
                  );
                  ref.read(historyLogProvider.notifier).addLog(
                    title: 'Currency Changed',
                    description: 'Switched active display currency to PKR (Pakistani Rupee).',
                    actionType: 'settings_changed',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Display currency set to PKR (1 QAR = 74.03 PKR)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }


  // 3. OVERALL BUDGET LIMIT SHEET
  void _showBudgetLimitSheet(BuildContext context, AppSettings settings) {
    final double currentQARLimit = settings.overallMonthlyLimit ?? 5000.0;
    final double displayLimit = CurrencyFormatter.convert(currentQARLimit, settings.currency);

    final controller = TextEditingController(
      text: displayLimit.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Set Overall Monthly Budget',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Define your total monthly spending target limit in ${settings.currency}.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  decoration: InputDecoration(
                    labelText: 'Monthly Limit (${settings.currency})',
                    border: const OutlineInputBorder(),
                    prefixText: '${settings.currency} ',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final double? enteredVal = double.tryParse(controller.text);
                    if (enteredVal != null && enteredVal > 0) {
                      final double limitInQAR = settings.currency == 'PKR' ? (enteredVal / 74.03) : enteredVal;
                      ref.read(appSettingsProvider.notifier).updateSettings(
                        settings.copyWith(overallMonthlyLimit: limitInQAR),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Overall monthly budget set to ${CurrencyFormatter.format(limitInQAR, settings.currency, decimalDigits: 0)}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Budget Limit'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. BUDGET BY CATEGORY SHEET
  void _showCategoryBudgetsSheet(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(appSettingsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Budget Limits by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Customize individual monthly limits in ${settings.currency}. Set to 0 to disable.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);

                      final double currentQAR = cat.monthlyLimit ?? 0.0;
                      final double displayLimit = currentQAR > 0 ? CurrencyFormatter.convert(currentQAR, settings.currency) : 0.0;
                      final limitController = TextEditingController(
                        text: displayLimit.toStringAsFixed(0),
                      );

                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.asset(
                            cat.iconAsset,
                            colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                          ),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: SizedBox(
                          width: 130,
                          child: TextField(
                            controller: limitController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              prefixText: '${settings.currency} ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              final double? enteredVal = double.tryParse(value);
                              if (enteredVal != null) {
                                final double newLimitInQAR = (settings.currency == 'PKR' && enteredVal > 0)
                                    ? (enteredVal / 74.03)
                                    : enteredVal;
                                ref.read(categoriesProvider.notifier).updateCategory(
                                  cat.copyWith(monthlyLimit: newLimitInQAR),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${cat.name} budget set to ${CurrencyFormatter.format(newLimitInQAR, settings.currency, decimalDigits: 0)}'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // 6. CATEGORIES MANAGEMENT SHEET
  void _showCategoriesManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final categories = ref.watch(categoriesProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Text(
                          'Category Manager',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: () => _showAddCategorySheet(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);

                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.asset(
                                cat.iconAsset,
                                colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                              ),
                            ),
                            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(cat.isDefault ? 'Default Category' : 'Custom Category'),
                            trailing: cat.isDefault
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    onPressed: () {
                                      ref.read(categoriesProvider.notifier).deleteCategory(cat.id);
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    final nameController = TextEditingController();
    String selectedIcon = 'assets/icons/tag.svg';
    String selectedColorHex = '#7A9E5A';

    final availableIcons = [
      'assets/icons/food.svg',
      'assets/icons/petrol.svg',
      'assets/icons/rent.svg',
      'assets/icons/sim.svg',
      'assets/icons/bike.svg',
      'assets/icons/tag.svg',
    ];

    final availableColors = [
      '#6B8E5A', // Greenish
      '#C9822E', // Amber
      '#5A7A9E', // Blueish
      '#9E7A5A', // Muted Brown
      '#8E5A7A', // Plum
      '#E47C38', // Orange
      '#3F8B9C', // Teal
      '#8F63AC', // Lavender
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom Category',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick Tags & Presets',

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        {'name': 'Bike', 'icon': 'assets/icons/bike.svg', 'color': '#5A7A9E'},
                        {'name': 'SIM', 'icon': 'assets/icons/sim.svg', 'color': '#8E5A7A'},
                        {'name': 'Fuel', 'icon': 'assets/icons/petrol.svg', 'color': '#C9822E'},
                        {'name': 'Rent', 'icon': 'assets/icons/rent.svg', 'color': '#2D5F4C'},
                        {'name': 'Food', 'icon': 'assets/icons/food.svg', 'color': '#B33A3A'},
                        {'name': 'Other', 'icon': 'assets/icons/tag.svg', 'color': '#7A9E5A'},
                      ].map((tag) {
                        final isSel = nameController.text == tag['name'];
                        return ActionChip(
                          avatar: SvgPicture.asset(
                            tag['icon']!,
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(
                              isSel ? Colors.white : AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: Text(
                            tag['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                            ),
                          ),
                          backgroundColor: isSel
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceCardDark : const Color(0xFFF0F4F1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSel ? AppColors.primary : (isDark ? AppColors.borderDark : const Color(0xFFE0E0E0)),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              nameController.text = tag['name']!;
                              selectedIcon = tag['icon']!;
                              selectedColorHex = tag['color']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Icon Asset', style: TextStyle(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableIcons.length,
                        itemBuilder: (context, idx) {
                          final iconPath = availableIcons[idx];
                          final isSel = selectedIcon == iconPath;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = iconPath),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                                border: Border.all(color: isSel ? AppColors.primary : Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.asset(
                                iconPath,
                                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                                width: 24,
                                height: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableColors.length,
                        itemBuilder: (context, idx) {
                          final colHex = availableColors[idx];
                          final color = Color(int.parse(colHex.replaceFirst('#', 'FF'), radix: 16));
                          final isSel = selectedColorHex == colHex;

                          return GestureDetector(
                            onTap: () => setState(() => selectedColorHex = colHex),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? Colors.black : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          final newCat = Category(
                            id: 'custom_${name.toLowerCase().replaceAll(' ', '_')}',
                            name: name,
                            iconAsset: selectedIcon,
                            colorHex: selectedColorHex,
                            monthlyLimit: 5000.0,
                            isDefault: false,
                          );
                          ref.read(categoriesProvider.notifier).addCategory(newCat);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add Category'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 7. AUTO LOCK DURATION PICKER
  void _showAutoLockSheet(BuildContext context) {
    final options = ['Immediately', '1 minute', '5 minutes', 'Never'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Lock Delay',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = _selectedAutoLock == opt;
                return ListTile(
                  title: Text(opt),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedAutoLock = opt;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 8. TEXT SIZE SHEET
  void _showTextSizeSheet(BuildContext context) {
    final sizes = ['Small', 'Medium', 'Large'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adjust Text Scale',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...sizes.map((sz) {
                final isSelected = _selectedTextSize == sz;
                return ListTile(
                  title: Text(sz, style: TextStyle(fontSize: sz == 'Small' ? 13 : sz == 'Medium' ? 16 : 19)),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedTextSize = sz;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 9. NOTIFICATIONS SHEET
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Alert Setup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Limit Warnings (80%)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Warn me when category reaches 80% spent'),
                    value: _budgetAlerts,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setSheetState(() => _budgetAlerts = val);
                      setState(() => _budgetAlerts = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Weekly Summaries', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Receive local summary alerts every Sunday'),
                    value: _weeklySummaries,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setSheetState(() => _weeklySummaries = val);
                      setState(() => _weeklySummaries = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBackupRestoreSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'JSON Backup & Restore',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your local expense history as a JSON backup or restore previously saved data.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Export Card Button
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download, color: AppColors.primary),
                    ),
                    title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Generate & copy JSON backup string'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _performJsonExport(context);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Restore Card Button
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A78A6).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload, color: Color(0xFF5A78A6)),
                    ),
                    title: const Text('Restore from JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Paste JSON backup data to restore'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _performJsonRestoreDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performJsonExport(BuildContext context) {
    final expenses = HiveService.expensesBox.values.toList();
    final categories = HiveService.categoriesBox.values.toList();
    final recurring = HiveService.recurringBox.values.toList();
    final settings = HiveService.settingsBox.get('app_settings');

    final data = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => {
        'id': e.id,
        'categoryId': e.categoryId,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'note': e.note,
        'isFromRecurring': e.isFromRecurring,
      }).toList(),
      'categories': categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'iconAsset': c.iconAsset,
        'colorHex': c.colorHex,
        'monthlyLimit': c.monthlyLimit,
        'isDefault': c.isDefault,
      }).toList(),
      'recurring': recurring.map((r) => {
        'id': r.id,
        'label': r.label,
        'categoryId': r.categoryId,
        'amount': r.amount,
        'dueDay': r.dueDay,
      }).toList(),
      'settings': settings != null ? {
        'userName': settings.userName,
        'currency': settings.currency,
        'darkMode': settings.darkMode,
        'appLockEnabled': settings.appLockEnabled,
        'overallMonthlyLimit': settings.overallMonthlyLimit,
      } : null,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Log the backup action
    ref.read(historyLogProvider.notifier).addLog(
      title: 'JSON Backup Created',
      description: 'Exported ${expenses.length} expenses and app configuration',
      actionType: 'settings_backup',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('JSON Backup Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copy the JSON data below to keep a safe offline backup:'),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to Clipboard'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON Backup copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _performJsonRestoreDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore from JSON Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your exported JSON backup data string below:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  hintText: 'Paste {"version": "1.0", ...}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Restore Data'),
              onPressed: () async {
                final jsonStr = controller.text.trim();
                if (jsonStr.isEmpty) return;

                try {
                  final Map<String, dynamic> data = jsonDecode(jsonStr);

                  // 1. Restore Expenses
                  if (data['expenses'] is List) {
                    final expList = (data['expenses'] as List).map((item) {
                      return Expense(
                        id: item['id'],
                        categoryId: item['categoryId'],
                        amount: (item['amount'] as num).toDouble(),
                        date: DateTime.parse(item['date']),
                        note: item['note'],
                        isFromRecurring: item['isFromRecurring'] ?? false,
                      );
                    }).toList();

                    await HiveService.expensesBox.clear();
                    for (var e in expList) {
                      await HiveService.expensesBox.put(e.id, e);
                    }
                  }

                  // 2. Restore Categories
                  if (data['categories'] is List) {
                    final catList = (data['categories'] as List).map((item) {
                      return Category(
                        id: item['id'],
                        name: item['name'],
                        iconAsset: item['iconAsset'],
                        colorHex: item['colorHex'],
                        monthlyLimit: item['monthlyLimit'] != null ? (item['monthlyLimit'] as num).toDouble() : null,
                        isDefault: item['isDefault'] ?? false,
                      );
                    }).toList();

                    await HiveService.categoriesBox.clear();
                    for (var c in catList) {
                      await HiveService.categoriesBox.put(c.id, c);
                    }
                  }

                  // 3. Restore Recurring
                  if (data['recurring'] is List) {
                    final recList = (data['recurring'] as List).map((item) {
                      return RecurringExpense(
                        id: item['id'],
                        label: item['label'] ?? 'Recurring Item',
                        categoryId: item['categoryId'],
                        amount: (item['amount'] as num).toDouble(),
                        dueDay: item['dueDay'] ?? 1,
                      );
                    }).toList();

                    await HiveService.recurringBox.clear();
                    for (var r in recList) {
                      await HiveService.recurringBox.put(r.id, r);
                    }
                  }

                  // 4. Restore Settings
                  if (data['settings'] is Map) {
                    final sMap = data['settings'];
                    final settingsObj = AppSettings(
                      userName: sMap['userName'] ?? 'Abdul Jabbar',
                      currency: sMap['currency'] ?? 'QAR',

                      darkMode: sMap['darkMode'] ?? false,
                      appLockEnabled: sMap['appLockEnabled'] ?? false,
                      overallMonthlyLimit: sMap['overallMonthlyLimit'] != null ? (sMap['overallMonthlyLimit'] as num).toDouble() : 55000.0,
                    );
                    await HiveService.settingsBox.put('app_settings', settingsObj);
                  }

                  // Invalidate riverpod providers
                  ref.invalidate(expensesProvider);
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(recurringExpensesProvider);
                  ref.invalidate(appSettingsProvider);

                  // Log restoration action
                  ref.read(historyLogProvider.notifier).addLog(
                    title: 'Backup Restored',
                    description: 'Successfully restored data from JSON backup',
                    actionType: 'settings_restore',
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup data restored successfully!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (err) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to restore backup: $err'),
                        behavior: SnackBarBehavior.floating,

                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {

    showAboutDialog(
      context: context,
      applicationName: 'Kharcha',
      applicationVersion: 'v1.0.0-Beta',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
      ),
      children: const [
        Text(
          'Kharcha is a beautiful, local-first personal expense manager. '
          'All your data is saved inside your device using Hive Local Storage, '
          'giving you absolute control and privacy over your cash ledger flow.',
        ),
      ],
    );
  }
}
