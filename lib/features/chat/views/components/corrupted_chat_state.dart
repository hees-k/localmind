import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:localmind/features/conversations/data/models/conversation.dart';

class CorruptedChatState extends ConsumerWidget {
  const CorruptedChatState({
    required this.conversation,
    this.errorMessage,
    required this.onStartNewChat,
  });

  final Conversation conversation;
  final String? errorMessage;
  final VoidCallback onStartNewChat;

  void _showDebugInfo(BuildContext context, WidgetRef ref) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Technical Details'),
        description: const Text(
          'Diagnostic information to help identify synchronization issues.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () {
              final data =
                  '''
ID: ${conversation.id}
Title: ${conversation.title}
Expected: ${conversation.messageCount}
Error: $errorMessage
''';
              Clipboard.setData(ClipboardData(text: data));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy Info'),
          ),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DebugRow(label: 'Conversation ID', value: conversation.id),
              _DebugRow(
                label: 'Created At',
                value: conversation.createdAt.toIso8601String(),
              ),
              _DebugRow(
                label: 'Expected Messages',
                value: '${conversation.messageCount}',
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Error:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'History Missing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Either the messages in this chat were deleted or the history record is corrupted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShadButton(
                  onPressed: onStartNewChat,
                  leading: const Icon(Icons.add_rounded, size: 20),
                  child: const Text('Start New Chat'),
                ),
                const SizedBox(width: 12),
                ShadButton.outline(
                  onPressed: () => _showDebugInfo(context, ref),
                  child: const Text('Technical Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
