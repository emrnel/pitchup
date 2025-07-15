import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<AuthProvider, AppStateProvider>(
        builder: (context, authProvider, appStateProvider, child) {
          final user = authProvider.currentUser;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Account section
              _buildSectionHeader('Hesap'),
              _buildSettingsItem(
                icon: Icons.person_outline,
                title: 'Profili Düzenle',
                subtitle: 'Profil bilgilerinizi güncelleyin',
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
              ),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: 'Şifreyi Değiştir',
                subtitle: 'Hesap güvenliğinizi artırın',
                onTap: () => _showChangePasswordDialog(context),
              ),

              const SizedBox(height: 24),

              // App preferences
              _buildSectionHeader('Uygulama'),
              _buildThemeSelector(appStateProvider),
              _buildSettingsItem(
                icon: Icons.language,
                title: 'Dil',
                subtitle: 'Türkçe',
                onTap: () => _showLanguageDialog(context, appStateProvider),
              ),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirim Ayarları',
                subtitle: 'Bildirim tercihlerinizi yönetin',
                onTap: () => _showNotificationSettings(context),
              ),

              const SizedBox(height: 24),

              // Support section
              _buildSectionHeader('Destek'),
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Yardım Merkezi',
                subtitle: 'SSS ve destek',
                onTap: () => _openHelpCenter(),
              ),
              _buildSettingsItem(
                icon: Icons.feedback_outlined,
                title: 'Geri Bildirim Gönder',
                subtitle: 'Önerilerinizi paylaşın',
                onTap: () => _sendFeedback(),
              ),
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () => _openPrivacyPolicy(),
              ),
              _buildSettingsItem(
                icon: Icons.description_outlined,
                title: 'Kullanım Şartları',
                onTap: () => _openTermsOfService(),
              ),

              const SizedBox(height: 24),

              // About section
              _buildSectionHeader('Hakkında'),
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Uygulama Sürümü',
                subtitle: '1.0.0',
                showArrow: false,
              ),

              const SizedBox(height: 32),

              // Logout button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXLarge),
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  child: Text(
                    'Çıkış Yap',
                    style: AppTypography.buttonText,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.bodyMediumText.copyWith(
          fontWeight: AppTypography.fontMedium,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: AppTypography.bodyLargeText,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTypography.bodySmallText.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing ??
            (showArrow
                ? Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textTertiary,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector(AppStateProvider appStateProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(
          Icons.palette_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
        title: Text(
          'Tema',
          style: AppTypography.bodyLargeText,
        ),
        subtitle: Text(
          _getThemeName(appStateProvider.themeMode),
          style: AppTypography.bodySmallText.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: DropdownButton<ThemeMode>(
          value: appStateProvider.themeMode,
          underline: Container(),
          onChanged: (ThemeMode? value) {
            if (value != null) {
              appStateProvider.setThemeMode(value);
            }
          },
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('Sistem'),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text('Açık'),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text('Koyu'),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'Sistem';
      case ThemeMode.light:
        return 'Açık';
      case ThemeMode.dark:
        return 'Koyu';
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Şifreyi Değiştir', style: AppTypography.h3),
        content: Text(
          'Şifre değiştirme özelliği yakında eklenecektir.',
          style: AppTypography.bodyMediumText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, AppStateProvider appStateProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dil Seçin', style: AppTypography.h3),
        content: Text(
          'Çoklu dil desteği yakında eklenecektir.',
          style: AppTypography.bodyMediumText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bildirim Ayarları', style: AppTypography.h3),
        content: Text(
          'Detaylı bildirim ayarları yakında eklenecektir.',
          style: AppTypography.bodyMediumText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    Helpers.launchURL('https://pitchup.app/help');
  }

  void _sendFeedback() {
    Helpers.launchEmail(
      'support@pitchup.app',
      subject: 'PitchUp Geri Bildirim',
      body: 'Merhaba,\n\nGeri bildirimim:\n\n',
    );
  }

  void _openPrivacyPolicy() {
    Helpers.launchURL('https://pitchup.app/privacy');
  }

  void _openTermsOfService() {
    Helpers.launchURL('https://pitchup.app/terms');
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap', style: AppTypography.h3),
        content: Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: AppTypography.bodyMediumText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
