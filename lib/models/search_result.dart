import 'chat_message.dart';

class MatchSpan {
  final int start;
  final int end;
  const MatchSpan(this.start, this.end);
}

class SearchResult {
  final String conversationId;
  final String conversationTitle;
  final ChatMessage message;
  final List<MatchSpan> matches;

  const SearchResult({
    required this.conversationId,
    required this.conversationTitle,
    required this.message,
    required this.matches,
  });

  bool get hasTitleMatch => matches.any((m) => m.start == -1 && m.end == -1);
}

class ConversationSearchGroup {
  final String conversationId;
  final String conversationTitle;
  final List<SearchResult> results;

  const ConversationSearchGroup({
    required this.conversationId,
    required this.conversationTitle,
    required this.results,
  });

  int get matchCount => results.length;
}
