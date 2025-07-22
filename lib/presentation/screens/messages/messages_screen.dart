// lib/presentation/screens/messages/messages_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/message_model.dart';
import '../../widgets/common/input_field.dart';

class MessagesScreen extends StatefulWidget {
  final String offerId;

  const MessagesScreen({
    Key? key,
    required this.offerId,
  }) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Mock data - in real app this would come from provider
  final List<MessageModel> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mesajlar',
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('Engelle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 8),
                    Text('Şikayet Et'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final isMe =
                          true; // This would be determined by current user

                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXLarge),
                        border: Border.all(color: AppColors.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: AppTypography.bodyMediumText,
                              decoration: InputDecoration(
                                hintText: 'Mesajınızı yazın...',
                                hintStyle:
                                    AppTypography.bodyMediumText.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Mesaj Yok',
            style: AppTypography.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk mesajı göndererek konuşmayı başlatın',
            style: AppTypography.bodyMediumText.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryColor : AppColors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppDimensions.radiusLarge),
                  topRight: const Radius.circular(AppDimensions.radiusLarge),
                  bottomLeft: Radius.circular(
                    isMe
                        ? AppDimensions.radiusLarge
                        : AppDimensions.radiusSmall,
                  ),
                  bottomRight: Radius.circular(
                    isMe
                        ? AppDimensions.radiusSmall
                        : AppDimensions.radiusLarge,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTypography.bodyMediumText.copyWith(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.timeAgo(message.createdAt),
                  style: AppTypography.captionText.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead
                        ? AppColors.primaryColor
                        : AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // TODO: Send message to Firebase
      setState(() {
        _messages.add(
          MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            offerId: widget.offerId,
            senderId: 'current_user_id',
            receiverId: 'other_user_id',
            text: _messageController.text.trim(),
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      });

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }
}