import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

class FetchConversations extends ChatListEvent {}

class LoadMoreConversations extends ChatListEvent {}

class ListReceiveMessage extends ChatListEvent {
  final String conversationId;
  final MessageEntity message;
  final bool isActiveConversation;
  
  const ListReceiveMessage({
    required this.conversationId,
    required this.message, 
    this.isActiveConversation = false,
  });
  
  @override
  List<Object?> get props => [conversationId, message, isActiveConversation];
}

class OptimisticMarkAsReadList extends ChatListEvent {
  final String conversationId;
  const OptimisticMarkAsReadList({required this.conversationId});
  
  @override
  List<Object?> get props => [conversationId];
}
