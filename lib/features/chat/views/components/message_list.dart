import 'package:flutter/material.dart';

import '../../data/models/message.dart';
import 'chat_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    required this.scrollController,
    required this.messages,
    required this.streamingMessage,
    required this.isStreaming,
    required this.onRetry,
    required this.onDelete,
    this.hasSmartReplies = false,
  });

  final ScrollController scrollController;
  final List<Message> messages;
  final Message? streamingMessage;
  final bool isStreaming;
  final void Function(String) onRetry;
  final void Function(String) onDelete;
  final bool hasSmartReplies;

  @override
  Widget build(BuildContext context) {
    final allMessages = <Message>[];

    for (final message in messages) {
      if (streamingMessage != null &&
          message.id == streamingMessage!.id &&
          isStreaming) {
        continue;
      }
      allMessages.add(message);
    }

    return ListView.builder(
      controller: scrollController,
      cacheExtent: 1000,
      padding: EdgeInsets.only(
        top: 16,
        bottom: 120 + (hasSmartReplies ? 56 : 0),
      ),
      itemCount:
          allMessages.length +
          (streamingMessage != null && isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (streamingMessage != null &&
            isStreaming &&
            index == allMessages.length) {
          return ChatBubble(message: streamingMessage!, isStreaming: true);
        }

        final message = allMessages[index];
        final isLast = index == allMessages.length - 1;

        return ChatBubble(
          key: ValueKey(message.id),
          message: message,
          isStreaming:
              isLast && isStreaming && message.id == streamingMessage?.id,
          onRetry: () => onRetry(message.id),
          onDelete: () => onDelete(message.id),
        );
      },
    );
  }
}
