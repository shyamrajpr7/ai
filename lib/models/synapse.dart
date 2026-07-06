enum SynapseStatus { idle, running, paused, completed, error }

class SynapseMessage {
  final String id;
  final String personaId;
  final String personaName;
  final String personaEmoji;
  final int personaColor;
  final String content;
  final int turnNumber;
  final DateTime timestamp;

  SynapseMessage({
    required this.id,
    required this.personaId,
    required this.personaName,
    required this.personaEmoji,
    required this.personaColor,
    required this.content,
    required this.turnNumber,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SynapseSession {
  final String id;
  final String prompt;
  final List<String> participantIds;
  List<SynapseMessage> messages;
  SynapseStatus status;
  int currentTurn;
  final int maxTurns;
  String? userInstruction;
  String? errorMessage;

  SynapseSession({
    required this.id,
    required this.prompt,
    required this.participantIds,
    this.messages = const [],
    this.status = SynapseStatus.idle,
    this.currentTurn = 0,
    this.maxTurns = 6,
    this.userInstruction,
    this.errorMessage,
  });
}
