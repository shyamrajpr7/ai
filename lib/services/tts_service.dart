import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  String? _currentMessageId;
  bool _isSpeaking = false;

  TtsService._() {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentMessageId = null;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      _currentMessageId = null;
      notifyListeners();
    });
  }

  bool isSpeaking(String? messageId) =>
      _isSpeaking && _currentMessageId == messageId;

  Future<void> toggle(String messageId, String text) async {
    if (_isSpeaking && _currentMessageId == messageId) {
      await _tts.stop();
      _isSpeaking = false;
      _currentMessageId = null;
      notifyListeners();
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
    }

    _currentMessageId = messageId;
    await _tts.speak(text);
    _isSpeaking = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _currentMessageId = null;
    notifyListeners();
  }
}
