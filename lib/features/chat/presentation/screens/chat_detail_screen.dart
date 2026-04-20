import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_avatar_circle.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_detail_bloc.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_detail_event.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_detail_state.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_event.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_state.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/injection_container.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late ChatDetailBloc _bloc;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    final user = sl<StorageService>().getUser();
    _currentUserId = user?['id'] ?? '';
    
    _bloc = sl<ChatDetailBloc>()..add(FetchMessages(widget.chatId));
    context.read<ChatListBloc>().add(OptimisticMarkAsReadList(conversationId: widget.chatId));
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isTop) _bloc.add(LoadMoreMessages());
  }

  bool get _isTop {
    if (!_scrollCtrl.hasClients) return false;
    // Since reverse: true, maxScrollExtent is at the top (older messages)
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentScroll = _scrollCtrl.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _bloc.add(SendMessage(
      conversationId: widget.chatId,
      content: text,
      tempId: '',
      senderId: _currentUserId,
    ));
    _inputCtrl.clear();
    // Scroll to bottom (offset 0 in reverse list)
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, listState) {
          final convo = listState.conversations.cast<ConversationEntity?>().firstWhere(
                (c) => c?.conversationId == widget.chatId,
                orElse: () => null,
              );

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: const BackButton(),
              title: Row(
                children: [
                  AppAvatarCircle(name: convo?.otherUserName ?? '?', radius: 18),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(convo?.otherUserName ?? 'Chat', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'Online',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.info_outline, color: AppColors.primary), onPressed: () {}),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
                      builder: (context, state) {
                        if (state.status == ChatDetailStatus.loading && state.messages.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true, // Latest at bottom
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: state.hasMore ? state.messages.length + 1 : state.messages.length,
                          itemBuilder: (_, i) {
                            if (i >= state.messages.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                            final msg = state.messages[i];
                            // Compare with real auth user id
                            final isMine = msg.senderId == _currentUserId;
                            return _MessageBubble(
                              message: msg, 
                              isMine: isMine, 
                              otherUserName: convo?.otherUserName ?? '',
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Grid/Apps button used as reload button
          GestureDetector(
            onTap: () => _bloc.add(FetchMessages(widget.chatId)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amazonBorder),
                color: Colors.white,
              ),
              child: const Icon(Icons.grid_view_rounded, color: AppColors.amazonBtnPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amazonBorder),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button in yellow circle
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amazonBtnPrimary.withValues(alpha: 0.2), // Light yellow background
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.amazonBtnPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message, 
    required this.isMine, 
    required this.otherUserName,
  });
  
  final MessageEntity message;
  final bool isMine;
  final String otherUserName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                AppAvatarCircle(name: otherUserName, radius: 14),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.amazonBtnPrimary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    boxShadow: [
                      if (!isMine)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: isMine ? null : Border.all(color: AppColors.amazonBorder.withValues(alpha: 0.5)),
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    message.content,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.amazonText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Small timestamp under bubble
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMine ? 0 : 40, right: isMine ? 12 : 0),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
