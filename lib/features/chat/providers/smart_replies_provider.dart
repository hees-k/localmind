import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import 'chat_providers.dart';

final smartRepliesProvider = Provider<List<String>>((ref) {
  final chatState = ref.watch(chatProvider);
  final isStreaming = ref.watch(isStreamingProvider);

  if (chatState.messages.length < 2 || isStreaming) return [];

  final lastAssistant = chatState.messages.reversed.firstWhere(
    (m) =>
        m.role == MessageRole.assistant && m.status == MessageStatus.complete,
    orElse: () => chatState.messages.last,
  );
  if (lastAssistant.role != MessageRole.assistant) return [];

  final content = lastAssistant.content.toLowerCase();
  final suggestions = <String>[];

  if (content.contains('```') ||
      content.contains('function') ||
      content.contains('class ') ||
      content.contains('import ')) {
    suggestions.addAll([
      'Explain this code',
      'How can I improve this?',
      'Add error handling',
      'Write tests for this',
    ]);
  } else if (content.contains('step') ||
      content.contains('first') ||
      content.contains('then')) {
    suggestions.addAll([
      'Can you elaborate on step 1?',
      'What if I get stuck?',
      'Give me a summary',
    ]);
  } else if (content.contains('error') ||
      content.contains('problem') ||
      content.contains('issue')) {
    suggestions.addAll([
      'Show me a fix',
      'What else could cause this?',
      'How to prevent this?',
    ]);
  } else {
    suggestions.addAll([
      'Tell me more',
      'Give me an example',
      'Summarize this',
      'What are the alternatives?',
    ]);
  }

  return suggestions;
});
