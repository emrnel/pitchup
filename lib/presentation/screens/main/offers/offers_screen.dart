// lib/presentation/screens/main/offers/offers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/offer_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/offer_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/cards/offer_card.dart';
import '../../../../core/services/navigation_service.dart';

class OffersScreen extends StatefulWidget {
  @override
  _OffersScreenState createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer2<OfferProvider, AuthProvider>(
          builder: (context, offerProvider, authProvider, child) {
            final user = authProvider.currentUser;

            if (user == null) {
              return const Center(child: LoadingIndicator());
            }

            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Teklifler',
                        style: AppTypography.h2,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => offerProvider.refreshOffers(
                          user.id,
                          user.role,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab bar for entrepreneurs (received/sent)
                if (user.role == UserRole.entrepreneur) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXLarge),
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
                      indicator: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXLarge),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTypography.bodyMediumText.copyWith(
                        fontWeight: AppTypography.fontMedium,
                      ),
                      tabs: [
                        Tab(
                            text:
                                'Gelen (${offerProvider.receivedOffers.length})'),
                        Tab(text: 'Geçmiş'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Content
                Expanded(
                  child: user.role == UserRole.entrepreneur
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildReceivedOffers(offerProvider, user),
                            _buildOffersHistory(offerProvider, user),
                          ],
                        )
                      : _buildSentOffers(offerProvider, user),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReceivedOffers(OfferProvider offerProvider, UserModel user) {
    if (offerProvider.isLoading && offerProvider.receivedOffers.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (offerProvider.error != null && offerProvider.receivedOffers.isEmpty) {
      return AppErrorWidget(
        title: 'Teklifler Yüklenemedi',
        message: offerProvider.error!,
        buttonText: 'Tekrar Dene',
        onRetry: () => offerProvider.loadReceivedOffers(user.id),
      );
    }

    final pendingOffers = offerProvider.receivedOffers
        .where((offer) => offer.status == OfferStatus.pending)
        .toList();

    if (pendingOffers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.business_center_outlined,
        title: 'Henüz Teklif Yok',
        message: 'Henüz projeniz için teklif gelmedi',
      );
    }

    return RefreshIndicator(
      onRefresh: () => offerProvider.loadReceivedOffers(user.id),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pendingOffers.length,
        itemBuilder: (context, index) {
          final offer = pendingOffers[index];
          return OfferCard(
            offer: offer,
            onTap: () => _navigateToOfferDetail(offer.id),
            onAccept: () => _handleOfferAction(
              offerProvider,
              offer.id,
              OfferStatus.accepted,
            ),
            onReject: () => _handleOfferAction(
              offerProvider,
              offer.id,
              OfferStatus.rejected,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersHistory(OfferProvider offerProvider, UserModel user) {
    final historicalOffers = offerProvider.receivedOffers
        .where((offer) => offer.status != OfferStatus.pending)
        .toList();

    if (historicalOffers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.history,
        title: 'Geçmiş Yok',
        message: 'Henüz cevaplanmış teklif bulunmuyor',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: historicalOffers.length,
      itemBuilder: (context, index) {
        final offer = historicalOffers[index];
        return OfferCard(
          offer: offer,
          onTap: () => _navigateToOfferDetail(offer.id),
          showActions: false,
        );
      },
    );
  }

  Widget _buildSentOffers(OfferProvider offerProvider, UserModel user) {
    if (offerProvider.isLoading && offerProvider.sentOffers.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (offerProvider.error != null && offerProvider.sentOffers.isEmpty) {
      return AppErrorWidget(
        title: 'Teklifler Yüklenemedi',
        message: offerProvider.error!,
        buttonText: 'Tekrar Dene',
        onRetry: () => offerProvider.loadSentOffers(user.id),
      );
    }

    if (offerProvider.sentOffers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.send_outlined,
        title: 'Henüz Teklif Yok',
        message: 'Henüz hiçbir projeye teklif göndermediniz',
        buttonText: 'Projeleri Keşfet',
        onButtonPressed: () {
          // Navigate to discover tab
          DefaultTabController.of(context)?.animateTo(0);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => offerProvider.loadSentOffers(user.id),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: offerProvider.sentOffers.length,
        itemBuilder: (context, index) {
          final offer = offerProvider.sentOffers[index];
          return OfferCard(
            offer: offer,
            onTap: () => _navigateToOfferDetail(offer.id),
            showActions: false,
            isInvestor: true,
          );
        },
      ),
    );
  }

  Future<void> _handleOfferAction(
    OfferProvider offerProvider,
    String offerId,
    OfferStatus status,
  ) async {
    final success = await offerProvider.updateOfferStatus(offerId, status);

    if (!success && mounted) {
      context.showSnackBar(
        'Teklif durumu güncellenirken bir hata oluştu',
        isError: true,
      );
    } else if (mounted) {
      final message = status == OfferStatus.accepted
          ? 'Teklif kabul edildi'
          : 'Teklif reddedildi';
      context.showSnackBar(message);
    }
  }

  void _navigateToOfferDetail(String offerId) {
    NavigationService.toOfferDetail(context, offerId);
  }
}