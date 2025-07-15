import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/video_model.dart';
import '../../../../data/repositories/video_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/offer_provider.dart';
import '../../../widgets/common/input_field.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/loading_indicator.dart';

class OfferFormScreen extends StatefulWidget {
  final String videoId;

  const OfferFormScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  _OfferFormScreenState createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _equityController = TextEditingController();
  final _noteController = TextEditingController();

  VideoModel? _video;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _equityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final videoRepository = VideoRepository();
      _video = await videoRepository.getVideo(widget.videoId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Video bilgileri yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Yatırım Teklifi',
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: AppTypography.bodyMediumText,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVideo,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _video == null
                  ? const Center(
                      child: Text('Video bulunamadı'),
                    )
                  : Stack(
                      children: [
                        Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Video info card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceColor,
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusMedium),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Proje Bilgileri',
                                        style: AppTypography.h4,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _video!.title,
                                        style: AppTypography.bodyLargeText
                                            .copyWith(
                                          fontWeight: AppTypography.fontMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _video!.description,
                                        style: AppTypography.bodyMediumText
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppDimensions
                                                          .radiusSmall),
                                            ),
                                            child: Text(
                                              _video!.sector,
                                              style: AppTypography.bodySmallText
                                                  .copyWith(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Offer form
                                Text(
                                  'Teklifiniz',
                                  style: AppTypography.h4,
                                ),
                                const SizedBox(height: 16),

                                InputField(
                                  controller: _amountController,
                                  label: 'Yatırım Tutarı (₺)',
                                  hint: '100000',
                                  keyboardType: TextInputType.number,
                                  validator: Validators.amount,
                                  enabled: !_isSubmitting,
                                ),
                                const SizedBox(height: 16),

                                InputField(
                                  controller: _equityController,
                                  label: 'Talep Edilen Hisse Oranı (%)',
                                  hint: '10',
                                  keyboardType: TextInputType.number,
                                  validator: Validators.percentage,
                                  enabled: !_isSubmitting,
                                ),
                                const SizedBox(height: 16),

                                InputField(
                                  controller: _noteController,
                                  label: 'Not (Opsiyonel)',
                                  hint:
                                      'Teklifinizle ilgili eklemek istediğiniz notlar...',
                                  maxLines: 4,
                                  enabled: !_isSubmitting,
                                ),

                                const SizedBox(height: 24),

                                // Expected financial info
                                if (_video!.metadata.requestedAmount != null ||
                                    _video!.metadata.equityOffered != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.infoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMedium),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: AppColors.infoColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Girişimcinin Beklentileri',
                                              style: AppTypography
                                                  .bodyMediumText
                                                  .copyWith(
                                                fontWeight:
                                                    AppTypography.fontMedium,
                                                color: AppColors.infoColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_video!.metadata.requestedAmount !=
                                            null)
                                          Text(
                                            'Talep Edilen Tutar: ${_video!.metadata.requestedAmount!.toStringAsFixed(0)}₺',
                                            style: AppTypography.bodySmallText
                                                .copyWith(
                                              color: AppColors.infoColor,
                                            ),
                                          ),
                                        if (_video!.metadata.equityOffered !=
                                            null)
                                          Text(
                                            'Sunulan Hisse: ${_video!.metadata.equityOffered!}%',
                                            style: AppTypography.bodySmallText
                                                .copyWith(
                                              color: AppColors.infoColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Submit button
                                PrimaryButton(
                                  text: _isSubmitting
                                      ? 'Gönderiliyor...'
                                      : 'Teklif Gönder',
                                  onPressed:
                                      _isSubmitting ? null : _handleSubmit,
                                  isLoading: _isSubmitting,
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        if (_isSubmitting) const LoadingIndicator(),
                      ],
                    ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || _video == null) {
      context.showSnackBar('Kullanıcı bilgisi bulunamadı', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final equity = double.parse(_equityController.text.replaceAll(',', ''));

      final success = await offerProvider.createOffer(
        videoId: widget.videoId,
        entrepreneurId: _video!.userId,
        investorId: user.id,
        amount: amount,
        equityPercentage: equity,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (success && mounted) {
        context.showSnackBar('Teklifiniz başarıyla gönderildi!');
        Navigator.pop(context);
      } else if (mounted) {
        context.showSnackBar(
          offerProvider.error ?? 'Teklif gönderilirken bir hata oluştu',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Geçersiz değer girdiniz. Lütfen kontrol edin.',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
