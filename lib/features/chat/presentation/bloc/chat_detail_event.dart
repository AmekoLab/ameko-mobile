import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchMessages extends ChatDetailEvent {
  final String conversationId;
  const FetchMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class LoadMoreMessages extends ChatDetailEvent {}

/// Mirrors FE sendMessageThunk — carries all data needed for optimistic insert.
class SendMessage extends ChatDetailEvent {
  final String conversationId;
  final String content;
  final String tempId;
  final String senderId;
  final int messageType;

  const SendMessage({
    required this.conversationId,
    required this.content,
    required this.tempId,
    required this.senderId,
    this.messageType = 0,
  });

  @override
  List<Object?> get props => [conversationId, content, tempId];
}

/// Fired when a real-time message arrives (e.g. SignalR).
/// Mirrors FE receiveMessage reducer.
class ReceiveMessage extends ChatDetailEvent {
  final MessageEntity message;
  const ReceiveMessage(this.message);
  @override
  List<Object?> get props => [message];
}

/// Mirrors FE markMessagesReadThunk.
class MarkMessagesRead extends ChatDetailEvent {
  final String conversationId;
  final int upToMessageId;
  const MarkMessagesRead({required this.conversationId, required this.upToMessageId});
  @override
  List<Object?> get props => [conversationId, upToMessageId];
}

/// Mirrors FE reactToMessageThunk.
class ReactToMessage extends ChatDetailEvent {
  final String conversationId;
  final String messageId;
  final int? reaction;
  const ReactToMessage({required this.conversationId, required this.messageId, this.reaction});
  @override
  List<Object?> get props => [conversationId, messageId, reaction];
}
