import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/managers/connection_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onConnectionLost;
  final VoidCallback? onConnectionRestored;

  const ConnectionAwareWidget({
    Key? key,
    required this.child,
    this.offlineWidget,
    this.onConnectionLost,
    this.onConnectionRestored,
  }) : super(key: key);

  @override
  _ConnectionAwareWidgetState createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> {
  bool _wasConnected = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionManager>(
      builder: (context, connectionManager, _) {
        final isConnected = connectionManager.isConnected;

        // Handle connection state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_wasConnected && !isConnected) {
            widget.onConnectionLost?.call();
          } else if (!_wasConnected && isConnected) {
            widget.onConnectionRestored?.call();
          }
          _wasConnected = isConnected;
        });

        if (!isConnected) {
          return widget.offlineWidget ?? _buildDefaultOfflineWidget();
        }

        return widget.child;
      },
    );
  }

  Widget _buildDefaultOfflineWidget() {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'İnternet Bağlantısı Yok',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen internet bağlantınızı kontrol edin',
              style: AppTypography.bodyMediumText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
