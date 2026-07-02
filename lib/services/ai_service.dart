abstract class AIService {
  Stream<String> streamResponse({
    required String message,
    required List<Map<String, String>> history,
    String webSearchContext = '',
  });
}
