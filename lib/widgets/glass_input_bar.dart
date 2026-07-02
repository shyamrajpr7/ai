import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'thinking_indicator.dart';

class GlassInputBar extends StatefulWidget {
  final bool isProcessing;
  final VoidCallback? onSend;
  final TextEditingController controller;

  const GlassInputBar({
    super.key,
    required this.isProcessing,
    required this.onSend,
    required this.controller,
  });

  @override
  State<GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends State<GlassInputBar> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(onError: (error) {
        debugPrint('Speech init error: $error');
      });
      if (mounted) setState(() => _speechAvailable = available);
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  void _startListening() {
    if (!_speechAvailable) return;
    HapticFeedback.mediumImpact();
    _speech.listen(
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
          widget.controller.text = result.recognizedWords;
          if (result.recognizedWords.trim().isNotEmpty) {
            _send();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    ).then((_) {
      if (mounted) setState(() => _isListening = false);
    });
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withOpacity(0.03),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMicButton(accent),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.isProcessing
                          ? 'AI is thinking...'
                          : 'Message Nexus...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 4),
                _buildSendButton(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(Color accent) {
    if (widget.isProcessing) return const SizedBox(width: 44);

    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? accent.withOpacity(0.25)
              : Colors.transparent,
        ),
        child: Center(
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none_rounded,
            color: _isListening
                ? accent
                : Colors.white.withOpacity(0.4),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(Color accent) {
    if (widget.isProcessing) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.15),
          border: Border.all(
            color: accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: ThinkingIndicator(),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accent,
            const Color(0xFF448AFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _send,
          child: Center(
            child: Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _send() {
    HapticFeedback.lightImpact();
    widget.onSend?.call();
  }
}
