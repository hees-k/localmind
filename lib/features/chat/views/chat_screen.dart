import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localmind/features/conversations/providers/conversation_providers.dart'
    as conv;
import 'package:localmind/features/models/screens/model_picker_sheet.dart';
import 'package:localmind/features/personas/providers/personas_providers.dart';
import 'package:localmind/features/servers/providers/server_providers.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../servers/data/models/server.dart';
import '../../servers/views/components/server_icon_picker.dart';
import '../providers/chat_mcp_providers.dart';
import '../providers/smart_replies_provider.dart' show smartRepliesProvider;
import '../providers/chat_providers.dart';
import 'components/chat_input_bar.dart';
import 'components/chat_settings_sheet.dart';
import 'components/connection_banner.dart' show ConnectionBanner;
import 'components/corrupted_chat_state.dart' show CorruptedChatState;
import 'components/empty_state.dart' show EmptyState;
import 'components/message_list.dart' show MessageList;
import 'components/model_top_bar.dart' show ModelTopBar;
import 'components/notification_permission_banner.dart';
import 'components/persona_indicator.dart' show PersonaIndicator;
import 'components/smart_reply_chips.dart' show SmartReplyChips;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickPrompts = [
    'Help me write a function',
    'Explain this code',
    'Debug this for me',
    'How do I use async/await?',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSelectFirstLoadedModelProvider);

    final chatState = ref.watch(chatProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final activeServer = ref.watch(activeServerProvider);
    final activeConversation = ref.watch(conv.activeConversationProvider);
    final personaId = activeConversation?.personaId;
    final persona = personaId != null
        ? ref.watch(personaByIdProvider(personaId))
        : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Autoscroll disabled as per user request
    // ref.listen(chatProvider, (previous, next) { ... });

    return Column(
      children: [
        ModelTopBar(
          selectedModel: selectedModel,
          onTap: () => _showModelPicker(context),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              ShadResponsiveBuilder(
                builder: (context, breakpoint) {
                  final isDesktop =
                      breakpoint >= ShadTheme.of(context).breakpoints.md;
                  if (isDesktop) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    if (activeServer != null) ...[
                      _buildServerIcon(context, activeServer),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      activeServer?.name ?? 'LocalMind',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connectionStatus == ConnectionStatus.connected
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final settings = ref.watch(settingsProvider);
                  final mcpConfig = ref.watch(chatMcpConfigProvider);
                  final isMcpEnabled = settings.mcpEnabled && mcpConfig.enabled;

                  return Stack(
                    children: [
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedFilterHorizontal,
                          size: 24,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => showChatSettingsSheet(
                          context,
                          initialTab: 'parameters',
                        ),
                        tooltip: 'Chat Parameters',
                      ),
                      Positioned(
                        top: 4,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isMcpEnabled ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedTools,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(value, context),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'new_chat',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('New Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'persona',
                    child: ListTile(
                      leading: Icon(
                        persona != null
                            ? Icons.swap_horiz
                            : Icons.smart_toy_outlined,
                      ),
                      title: Text(
                        persona != null ? 'Change Persona' : 'Set Persona',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (persona != null)
                    const PopupMenuItem(
                      value: 'remove_persona',
                      child: ListTile(
                        leading: Icon(Icons.person_remove_outlined),
                        title: Text('Remove Persona'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Clear Conversation'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const NotificationPermissionBanner(),
        if (connectionStatus == ConnectionStatus.disconnected ||
            connectionStatus == ConnectionStatus.error)
          ConnectionBanner(status: connectionStatus),
        if (persona != null)
          PersonaIndicator(
            persona: persona,
            onTap: () => _showPersonaPicker(context),
            onRemove: () {
              final activeConv = ref.read(conv.activeConversationProvider);
              if (activeConv != null) {
                ref
                    .read(conv.conversationsProvider.notifier)
                    .updatePersona(activeConv.id, null, null);
              }
            },
          ),
        Expanded(
          child: SafeArea(
            bottom: true,
            child: Stack(
              children: [
                if (chatState.isLoading)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                else if (chatState.messages.isEmpty && activeConversation != null)
                  CorruptedChatState(
                    conversation: activeConversation,
                    errorMessage: chatState.errorMessage,
                    onStartNewChat: () =>
                        ref.read(chatProvider.notifier).startNewConversation(),
                  )
                else if (chatState.messages.isEmpty)
                  EmptyState(
                    onQuickPrompt: (prompt) =>
                        ref.read(chatProvider.notifier).sendMessage(prompt),
                    quickPrompts: _quickPrompts,
                    recentConversations: ref.watch(
                      conv.recentConversationsProvider,
                    ),
                    onSeeAll: () => context.push(AppRoutes.chatHistory),
                    selectedModel: selectedModel,
                    onModelTap: () => _showModelPicker(context),
                    selectedPersona: ref.watch(selectedPersonaProvider),
                    onPersonaTap: () =>
                        _showPersonaPickerForPreselection(context),
                  )
                else
                  MessageList(
                    scrollController: _scrollController,
                    messages: chatState.messages,
                    streamingMessage: chatState.streamingMessage,
                    isStreaming: chatState.isStreaming,
                    onRetry: (messageId) {
                      ref.read(chatProvider.notifier).retryMessage(messageId);
                    },
                    onDelete: (messageId) {
                      ref.read(chatProvider.notifier).deleteMessage(messageId);
                    },
                    hasSmartReplies:
                        !chatState.isStreaming &&
                        ref.read(smartRepliesProvider).isNotEmpty,
                  ),
                if (!chatState.isStreaming)
                  Positioned(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmartReplyChips(
                          onSend: (message) {
                            ref.read(chatProvider.notifier).sendMessage(message);
                          },
                        ),
                        const SizedBox(height: 2),
                        ChatInputBar(
                          isStreaming: chatState.isStreaming,
                          onSend: (message, {attachments}) {
                            ref
                                .read(chatProvider.notifier)
                                .sendMessage(message, attachments: attachments);
                          },
                          onStop: () {
                            ref.read(chatProvider.notifier).cancelStream();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ModelPickerSheet(),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'new_chat':
        ref.read(chatProvider.notifier).startNewConversation();
        break;
      case 'persona':
        _showPersonaPicker(context);
        break;
      case 'remove_persona':
        final activeConv = ref.read(conv.activeConversationProvider);
        if (activeConv != null) {
          ref
              .read(conv.conversationsProvider.notifier)
              .updatePersona(activeConv.id, null, null);
        }
        break;
      case 'clear':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear conversation?'),
            content: const Text(
              'This will delete all messages in this conversation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(chatProvider.notifier).clearConversation();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showPersonaPicker(BuildContext context) {
    final personasAsync = ref.read(personasNotifierProvider);
    final personas = personasAsync.value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeConv = ref.read(conv.activeConversationProvider);
    final currentPersonaId = activeConv?.personaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Persona',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: personas.length,
                    itemBuilder: (context, index) {
                      final p = personas[index];
                      final isSelected = p.id == currentPersonaId;
                      final accent = isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF2563EB);
                      return ListTile(
                        leading: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: p.description != null
                            ? Text(
                                p.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF999999),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accent)
                            : null,
                        onTap: () {
                          if (activeConv != null) {
                            ref
                                .read(conv.conversationsProvider.notifier)
                                .updatePersona(
                                  activeConv.id,
                                  p.id,
                                  p.systemPrompt,
                                );
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPersonaPickerForPreselection(BuildContext context) {
    final personasAsync = ref.read(personasNotifierProvider);
    final personas = personasAsync.value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPersona = ref.watch(selectedPersonaProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Persona',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: personas.length,
                    itemBuilder: (context, index) {
                      final p = personas[index];
                      final isSelected = p.id == currentPersona?.id;
                      final accent = isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF2563EB);
                      return ListTile(
                        leading: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: p.description != null
                            ? Text(
                                p.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF999999),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accent)
                            : null,
                        onTap: () {
                          ref.read(selectedPersonaProvider.notifier).select(p);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerIcon(BuildContext context, Server server) {
    final iconData = server.iconName != null
        ? getHugeIconByName(server.iconName)
        : getDefaultServerIcon(server.type.name);

    if (iconData == null) {
      return const Icon(Icons.dns, size: 18);
    }

    return HugeIcon(
      icon: iconData.icon,
      size: 18,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
