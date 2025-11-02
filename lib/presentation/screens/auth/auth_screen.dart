// lib/presentation/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/input_field.dart';
import '../../widgets/common/loading_indicator.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // SEPARATE FORM KEYS
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // State
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Stack(
              children: [
                // Scrollable content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo section
                        Container(
                          height: 80,
                          child: Center(
                            child: Text(
                              'PitchUp',
                              style: AppTypography.h1.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tab Bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXLarge),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            // HATA DÜZELTME: Yuvarlak gösterge (BoxDecoration) yerine
                            // alt çizgi (UnderlineTabIndicator) kullanıldı.
                            indicator: const UnderlineTabIndicator(
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 3.0, // Çizgi kalınlığı
                              ),
                              // insets: EdgeInsets.symmetric(horizontal: 16.0), // Gerekirse çizgi uzunluğunu ayarlar
                            ),
                            labelColor:
                                AppColors.primaryColor, // Seçili metin rengi
                            unselectedLabelColor: AppColors
                                .textSecondary, // Seçili olmayan metin rengi
                            labelStyle: AppTypography.bodyLargeText.copyWith(
                              fontWeight: AppTypography.fontMedium,
                            ),
                            tabs: const [
                              Tab(text: 'Giriş Yap'),
                              Tab(text: 'Kayıt Ol'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Content
                        SizedBox(
                          height: 500, // Fixed height to prevent overflow
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(authProvider),
                              _buildRegisterForm(authProvider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (authProvider.isLoading) const LoadingIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            // Email field
            InputField(
              controller: _emailController,
              label: 'E-posta',
              hint: 'ornek@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),

            // Password field
            InputField(
              controller: _passwordController,
              label: 'Şifre',
              hint: '••••••••',
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre gerekli';
                }
                return null;
              },
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Şifremi Unuttum',
                  style: AppTypography.bodyMediumText.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error message
            if (authProvider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.error!,
                        style: AppTypography.bodyMediumText.copyWith(
                          color: AppColors.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Login button
            PrimaryButton(
              text: 'Giriş Yap',
              onPressed: () => _handleLogin(authProvider),
              isLoading: authProvider.isLoading,
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'veya',
                    style: AppTypography.bodyMediumText.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 24),

            // Social login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  Icons.g_mobiledata,
                  () => _handleSocialLogin(authProvider, 'google'),
                ),
                const SizedBox(width: 24),
                if (Platform.isIOS)
                  _buildSocialButton(
                    Icons.apple,
                    () => _handleSocialLogin(authProvider, 'apple'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            // Name field
            InputField(
              controller: _nameController,
              label: 'Ad Soyad',
              hint: 'John Doe',
              prefixIcon: Icons.person_outline,
              validator: Validators.name,
            ),
            const SizedBox(height: 16),

            // Email field
            InputField(
              controller: _emailController,
              label: 'E-posta',
              hint: 'ornek@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),

            // Password field
            InputField(
              controller: _passwordController,
              label: 'Şifre',
              hint: 'En az 6 karakter',
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              helperText: 'En az 6 karakter, bir büyük harf ve rakam içermeli',
              validator: Validators.password,
            ),

            const SizedBox(height: 16),

            // Terms checkbox
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmallText,
                      children: [
                        const TextSpan(text: 'Kayıt olarak '),
                        TextSpan(
                          text: 'Kullanım Şartları',
                          style: const TextStyle(color: AppColors.primaryColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Helpers.launchURL('https://pitchup.app/terms');
                            },
                        ),
                        const TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Gizlilik Politikası',
                          style: const TextStyle(color: AppColors.primaryColor),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Helpers.launchURL('https://pitchup.app/privacy');
                            },
                        ),
                        const TextSpan(text: '\'nı kabul ediyorum'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Error message
            if (authProvider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.error!,
                        style: AppTypography.bodyMediumText.copyWith(
                          color: AppColors.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Register button
            PrimaryButton(
              text: 'Kayıt Ol',
              onPressed:
                  _acceptedTerms ? () => _handleRegister(authProvider) : null,
              isLoading: authProvider.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (_loginFormKey.currentState!.validate()) {
      authProvider.clearError();
      context.hideKeyboard();

      final success = await authProvider.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!success && mounted && authProvider.error != null) {
        // Error is already shown in the UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarısız: ${authProvider.error}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (_registerFormKey.currentState!.validate()) {
      authProvider.clearError();
      context.hideKeyboard();

      final success = await authProvider.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!success && mounted && authProvider.error != null) {
        // Error is already shown in the UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarısız: ${authProvider.error}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleSocialLogin(
      AuthProvider authProvider, String provider) async {
    authProvider.clearError();
    context.hideKeyboard();

    bool success = false;

    try {
      if (provider == 'google') {
        success = await authProvider.signInWithGoogle();
      } else if (provider == 'apple') {
        success = await authProvider.signInWithApple();
      }

      if (!success && mounted) {
        final errorMessage =
            authProvider.error ?? 'Sosyal medya ile giriş başarısız';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş yapılırken bir hata oluştu'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Şifremi Unuttum', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'E-posta adresinizi girin, şifre sıfırlama bağlantısı gönderelim.',
              style: AppTypography.bodyMediumText,
            ),
            const SizedBox(height: 16),
            InputField(
              controller: emailController,
              label: 'E-posta',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isValidEmail) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider
                    .sendPasswordResetEmail(emailController.text);

                Navigator.pop(context);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Şifre sıfırlama e-postası gönderildi'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
