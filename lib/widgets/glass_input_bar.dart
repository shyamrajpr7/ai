import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/settings_provider.dart';
import 'thinking_indicator.dart';

class GlassInputBar extends StatefulWidget {
  final bool isProcessing;
  final ValueChanged<String> onImagePicked;
  final VoidCallback onSend;
  final TextEditingController controller;

  const GlassInputBar({
    super.key,
    required this.isProcessing,
    required this.onImagePicked,
    required this.onSend,
    required this.controller,
  });

  @override
  State<GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends State<GlassInputBar>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  bool _isListening = false;
  bool _speechAvailable = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
    _pulseController.repeat(reverse: true);
    _speech.listen(
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
          _pulseController.stop();
          widget.controller.text = result.recognizedWords;
          if (result.recognizedWords.trim().isNotEmpty) {
            widget.onSend();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    ).then((_) {
      _pulseController.stop();
      if (mounted) setState(() => _isListening = false);
    });
    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    _pulseController.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final base64 = base64Encode(bytes);
    widget.onImagePicked(base64);
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
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
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
                          : context.watch<SettingsProvider>().webSearchEnabled
                              ? 'Message Nexus (web search on)...'
                              : 'Message Nexus...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
                _buildImageButton(accent),
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

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (_isListening)
              Container(
                width: 44 + pulse * 12,
                height: 44 + pulse * 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.1 * (1 - pulse)),
                ),
              ),
            GestureDetector(
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
                  border: Border.all(
                    color: _isListening
                        ? accent.withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageButton(Color accent) {
    if (widget.isProcessing) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.image_outlined,
          color: Colors.white.withOpacity(0.4),
          size: 22,
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
          onTap: widget.onSend,
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
}
