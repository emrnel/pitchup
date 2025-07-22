// lib/presentation/widgets/cards/offer_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/offer_model.dart';
import '../common/secondary_button.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;
  final bool isInvestor;

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = true,
    this.isInvestor = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInvestor ? Icons.business : Icons.person,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInvestor
                                ? 'Yatırımcıya Gönderildi'
                                : 'Yeni Teklif',
                            style: AppTypography.bodyLargeText.copyWith(
                              fontWeight: AppTypography.fontMedium,
                            ),
                          ),
                          Text(
                            Formatters.timeAgo(offer.createdAt),
                            style: AppTypography.bodySmallText.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: 16),

                // Offer details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildOfferDetail(
                          'Teklif Tutarı',
                          Formatters.currency(offer.amount),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.dividerColor,
                      ),
                      Expanded(
                        child: _buildOfferDetail(
                          'Hisse Oranı',
                          '${offer.equityPercentage}%',
                        ),
                      ),
                    ],
                  ),
                ),

                // Note
                if (offer.note != null && offer.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Not:',
                    style: AppTypography.bodySmallText.copyWith(
                      fontWeight: AppTypography.fontMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.note!,
                    style: AppTypography.bodySmallText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Actions
                if (showActions &&
                    offer.status == OfferStatus.pending &&
                    !isInvestor) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Reddet',
                          onPressed: onReject,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXLarge),
                            ),
                          ),
                          onPressed: onAccept,
                          child: Text(
                            'Kabul Et',
                            style: AppTypography.buttonText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (offer.status) {
      case OfferStatus.pending:
        backgroundColor = AppColors.pendingColor.withOpacity(0.1);
        textColor = AppColors.pendingColor;
        text = 'Beklemede';
        break;
      case OfferStatus.accepted:
        backgroundColor = AppColors.successColor.withOpacity(0.1);
        textColor = AppColors.successColor;
        text = 'Kabul';
        break;
      case OfferStatus.rejected:
        backgroundColor = AppColors.errorColor.withOpacity(0.1);
        textColor = AppColors.errorColor;
        text = 'Red';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmallText.copyWith(
          color: textColor,
          fontWeight: AppTypography.fontMedium,
        ),
      ),
    );
  }

  Widget _buildOfferDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLargeText.copyWith(
            fontWeight: AppTypography.fontMedium,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}