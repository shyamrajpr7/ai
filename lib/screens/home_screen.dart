import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/glass_input_bar.dart';
import '../widgets/chat_history_drawer.dart';
import '../models/chat_message.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          drawer: ChatHistoryDrawer(provider: provider),
          body: GradientMeshBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(accent, provider),
                  Expanded(child: _buildMessages(provider, accent)),
                  GlassInputBar(
                    isProcessing: provider.isProcessing,
                    onSend: _handleSend,
                    controller: _textController,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color accent, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Nexus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              provider.createConversation();
            },
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ChatProvider provider, Color accent) {
    final conv = provider.currentConversation;

    if (conv == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.08),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 18,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a new chat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    final messages = conv.messages.toList();

    if (messages.isEmpty && !provider.isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.15),
                    accent.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 36,
                color: accent.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask me anything',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length + (provider.isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          final isError = msg.status == MessageStatus.error;
          return ChatBubble(
            key: ValueKey(msg.id),
            message: msg,
            isError: isError,
            onRetry: isError ? () => provider.retryMessage() : null,
          );
        } else {
          return ChatBubble(
            key: const ValueKey('streaming'),
            message: ChatMessage(
              id: 'streaming',
              content: provider.currentResponse,
              role: 'assistant',
              timestamp: DateTime.now(),
            ),
            isStreaming: true,
          );
        }
      },
    );
  }
}
