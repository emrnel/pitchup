// lib/presentation/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'Rol Seçimi',
                        style: AppTypography.h2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Cards
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRoleCard(
                          role: UserRole.entrepreneur,
                          title: 'Girişimci',
                          description: 'Projenizi yatırımcılara sunun',
                          icon: Icons.lightbulb_outline,
                          isSelected: _selectedRole == UserRole.entrepreneur,
                          onTap: () => _selectRole(UserRole.entrepreneur),
                        ),
                        const SizedBox(height: 24),
                        _buildRoleCard(
                          role: UserRole.investor,
                          title: 'Yatırımcı',
                          description: 'Projeleri keşfedin ve yatırım yapın',
                          icon: Icons.trending_up,
                          isSelected: _selectedRole == UserRole.investor,
                          onTap: () => _selectRole(UserRole.investor),
                        ),
                      ],
                    ),
                  ),
                  // Continue button
                  AnimatedOpacity(
                    opacity: _selectedRole != null ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: PrimaryButton(
                      text: 'Devam',
                      onPressed: _selectedRole != null
                          ? () => _handleContinue(authProvider)
                          : null,
                      isLoading: authProvider.isLoading,
                    ),
                  ),
                  if (_selectedRole == UserRole.investor) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.infoColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yatırımcı hesabınız manuel onay sonrası aktif olacaktır.',
                              style: AppTypography.bodySmallText.copyWith(
                                color: AppColors.infoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: AppTypography.h4.copyWith(
                color:
                    isSelected ? AppColors.primaryColor : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              description,
              style: AppTypography.bodyMediumText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _handleContinue(AuthProvider authProvider) async {
    if (_selectedRole == null) return;

    authProvider.clearError();

    final success = await authProvider.updateUserRole(_selectedRole!);

    if (!success && mounted) {
      context.showSnackBar(
        'Rol güncellenirken bir hata oluştu',
        isError: true,
      );
    }
  }
}