// lib/presentation/screens/main/profile/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/managers/permission_manager.dart';
import '../../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/input_field.dart';
import '../../../widgets/common/loading_indicator.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();

  String _selectedSector = 'Teknoloji';
  int? _foundedYear;
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _sectors = [
    'Teknoloji',
    'Sağlık',
    'Eğitim',
    'Finans',
    'E-ticaret',
    'Oyun',
    'Gıda',
    'Turizm',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _loadCurrentUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';

      if (user.company != null) {
        _companyNameController.text = user.company!.name;
        _websiteController.text = user.company!.website ?? '';
        _selectedSector = user.company!.sector;
        _foundedYear = user.company!.foundedYear;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profili Düzenle',
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _handleSave,
              child: Text(
                'Kaydet',
                style: AppTypography.bodyMediumText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: AppTypography.fontMedium,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Consumer2<AuthProvider, ProfileProvider>(
            builder: (context, authProvider, profileProvider, child) {
              final user = authProvider.currentUser;

              if (user == null) {
                return const Center(child: LoadingIndicator());
              }

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile picture
                      _buildProfilePictureSection(user),

                      const SizedBox(height: 32),

                      // Name
                      InputField(
                        controller: _nameController,
                        label: 'Ad Soyad',
                        validator: Validators.name,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Bio
                      InputField(
                        controller: _bioController,
                        label: 'Biyografi',
                        hint: 'Kendinizden bahsedin...',
                        maxLines: 3,
                        validator: Validators.bio,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Company section (for entrepreneurs)
                      if (user.role == UserRole.entrepreneur) ...[
                        Text(
                          'Şirket Bilgileri',
                          style: AppTypography.h4,
                        ),

                        const SizedBox(height: 16),

                        InputField(
                          controller: _companyNameController,
                          label: 'Şirket Adı',
                          validator: Validators.companyName,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 16),

                        // Sector dropdown
                        Text(
                          'Sektör',
                          style: AppTypography.bodyMediumText.copyWith(
                            fontWeight: AppTypography.fontMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSector,
                              isExpanded: true,
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedSector = value!;
                                      });
                                    },
                              items: _sectors.map((sector) {
                                return DropdownMenuItem(
                                  value: sector,
                                  child: Text(
                                    sector,
                                    style: AppTypography.bodyLargeText,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        InputField(
                          controller: _websiteController,
                          label: 'Website (Opsiyonel)',
                          hint: 'https://example.com',
                          validator: Validators.website,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 16),

                        // Founded year
                        Text(
                          'Kuruluş Yılı (Opsiyonel)',
                          style: AppTypography.bodyMediumText.copyWith(
                            fontWeight: AppTypography.fontMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.dividerColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _foundedYear,
                              isExpanded: true,
                              hint: Text(
                                'Seçiniz',
                                style: AppTypography.bodyLargeText.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _foundedYear = value;
                                      });
                                    },
                              items: List.generate(
                                DateTime.now().year - 1950 + 1,
                                (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(
                                      year.toString(),
                                      style: AppTypography.bodyLargeText,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Save button
                      PrimaryButton(
                        text: 'Değişiklikleri Kaydet',
                        onPressed: _isLoading ? null : _handleSave,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dividerColor,
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : user.profilePicture != null
                        ? Image.network(
                            user.profilePicture!,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textTertiary,
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundColor,
                    width: 3,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _selectProfilePicture,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Profil fotoğrafını değiştir',
          style: AppTypography.bodySmallText.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _selectProfilePicture() async {
    final hasPermission = await PermissionManager.requestPhotosPermission();
    if (!hasPermission) {
      context.showSnackBar(
        'Galeri erişimi için izin gerekiyor',
        isError: true,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update profile picture if changed
      if (_selectedImage != null) {
        await profileProvider.updateProfilePicture(user.id, _selectedImage!);
      }

      // Update company info if entrepreneur
      CompanyInfo? companyInfo;
      if (user.role == UserRole.entrepreneur &&
          _companyNameController.text.isNotEmpty) {
        companyInfo = CompanyInfo(
          name: _companyNameController.text.trim(),
          sector: _selectedSector,
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          foundedYear: _foundedYear,
        );
      }

      // Update profile
      final success = await profileProvider.updateProfile(
        userId: user.id,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        company: companyInfo,
      );

      if (success && mounted) {
        // Update auth provider with new user data
        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          company: companyInfo,
        );
        authProvider.updateUser(updatedUser);

        context.showSnackBar('Profil güncellendi');
        Navigator.pop(context);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}