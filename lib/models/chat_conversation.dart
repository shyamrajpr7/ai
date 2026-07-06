import 'chat_message.dart';
import 'conversation_branch.dart';

class ChatConversation {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ConversationBranch> branches;
  String activeBranchId;
  Map<String, List<ChatMessage>> branchMessages;

  ChatConversation({
    required this.id,
    this.title = 'New Chat',
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationBranch>? branches,
    String? activeBranchId,
    Map<String, List<ChatMessage>>? branchMessages,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        branches = branches ?? [],
        activeBranchId = activeBranchId ?? 'main',
        branchMessages = branchMessages ?? {};

  Map<String, dynamic> toJson() {
    final activeMsgs = branchMessages[activeBranchId] ?? messages;
    return {
      'id': id,
      'title': title,
      'messages': activeMsgs.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'branches': branches.map((b) => b.toJson()).toList(),
      'activeBranchId': activeBranchId,
      'branchMessages': branchMessages.map((k, v) =>
        MapEntry(k, v.map((m) => m.toJson()).toList())),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final branchesRaw = json['branches'] as List<dynamic>?;
    final activeId = json['activeBranchId'] as String? ?? 'main';
    final branchMsgsRaw = json['branchMessages'] as Map<String, dynamic>?;

    Map<String, List<ChatMessage>> branchMessages = {};
    if (branchMsgsRaw != null) {
      branchMessages = branchMsgsRaw.map((k, v) =>
        MapEntry(k, (v as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList()));
    }

    final legacyMessages = (json['messages'] as List<dynamic>?)
        ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList() ?? [];

    List<ConversationBranch> branches = [];
    if (branchesRaw != null) {
      branches = branchesRaw
          .map((b) => ConversationBranch.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    if (branches.isEmpty) {
      branches = [ConversationBranch(id: 'main', name: 'Original')];
      if (legacyMessages.isNotEmpty) {
        branchMessages['main'] = legacyMessages;
      }
    }

    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'New Chat',
      messages: branchMessages[activeId] ?? legacyMessages,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      branches: branches,
      activeBranchId: activeId,
      branchMessages: branchMessages,
    );
  }
}
