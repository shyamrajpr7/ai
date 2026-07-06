import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../services/web_search_service.dart';
import '../widgets/gradient_mesh_background.dart';

enum VoiceHubState { idle, listening, processing, speaking }

class VoiceHubScreen extends StatefulWidget {
  const VoiceHubScreen({super.key});

  @override
  State<VoiceHubScreen> createState() => _VoiceHubScreenState();
}

class _VoiceHubScreenState extends State<VoiceHubScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late AnimationController _waveController;
  late AnimationController _pulseController;
  VoiceHubState _state = VoiceHubState.idle;
  bool _speechAvailable = false;
  String _transcript = '';
  String _lastResponse = '';
  String _lastQuery = '';
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(onError: (_) {});
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {}
  }

  Future<void> _initTts() async {
    final settings = context.read<SettingsProvider>();
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.speechPitch);
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _state = VoiceHubState.idle);
        if (context.read<SettingsProvider>().voiceTriggerEnabled) {
          _startListening();
        }
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _state = VoiceHubState.idle);
    });
  }

  void _startListening() {
    if (!_speechAvailable) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _state = VoiceHubState.listening;
      _transcript = '';
    });
    _speech.listen(
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) {
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            _handleQuery(text);
          } else {
            setState(() => _state = VoiceHubState.idle);
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  void _stopListening() {
    _speech.stop();
    if (_state == VoiceHubState.listening) {
      setState(() => _state = VoiceHubState.idle);
    }
  }

  Future<void> _handleQuery(String text) async {
    setState(() {
      _lastQuery = text;
      _state = VoiceHubState.processing;
    });

    try {
      final provider = context.read<ChatProvider>();
      final settings = context.read<SettingsProvider>();

      String webSearchContext = '';
      if (settings.webSearchEnabled) {
        try {
          final searchService = WebSearchService(
            apiKey: dotenv.env['TAVILY_API_KEY'] ?? '',
          );
          webSearchContext = await searchService.search(text);
        } catch (_) {}
      }

      final aiService = provider.createAIService();
      final systemPrompt = settings.activePersona.systemPrompt;

      final buffer = StringBuffer();
      await for (final chunk in aiService.streamResponse(
        message: text,
        history: [],
        webSearchContext: webSearchContext,
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        setState(() => _lastResponse = buffer.toString());
      }

      final response = buffer.toString();
      if (response.isNotEmpty) {
        setState(() {
          _lastResponse = response;
          _state = VoiceHubState.speaking;
        });

        await _tts.setSpeechRate(settings.speechRate);
        await _tts.setPitch(settings.speechPitch);
        await _tts.speak(response);
      }
    } catch (e) {
      setState(() {
        _lastResponse = 'Sorry, I encountered an error: $e';
        _state = VoiceHubState.idle;
      });
    }
  }

  void _abortSpeaking() {
    _tts.stop();
    setState(() => _state = VoiceHubState.idle);
  }

  void _toggleListening() {
    if (_state == VoiceHubState.listening) {
      _stopListening();
    } else if (_state == VoiceHubState.speaking) {
      _abortSpeaking();
    } else {
      _startListening();
    }
  }

  void _showSettings() {
    final accent = context.read<SettingsProvider>().accentColor;
    var rate = context.read<SettingsProvider>().speechRate;
    var pitch = context.read<SettingsProvider>().speechPitch;
    var trigger = context.read<SettingsProvider>().voiceTriggerEnabled;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voice Settings',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const SizedBox(height: 20),
              _settingsSlider(
                'Speech Rate',
                rate,
                0.0, 1.0,
                accent,
                (v) {
                  rate = v;
                  context.read<SettingsProvider>().setSpeechRate(v);
                  setSheetState(() {});
                },
                '${(rate * 100).toInt()}%',
              ),
              const SizedBox(height: 16),
              _settingsSlider(
                'Pitch',
                pitch,
                0.5, 2.0,
                accent,
                (v) {
                  pitch = v;
                  context.read<SettingsProvider>().setSpeechPitch(v);
                  setSheetState(() {});
                },
                pitch.toStringAsFixed(1),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Auto-trigger (hands-free)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Switch(
                    value: trigger,
                    activeColor: accent,
                    onChanged: (v) {
                      trigger = v;
                      context.read<SettingsProvider>().setVoiceTriggerEnabled(v);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'When enabled, the hub will automatically start listening after each response.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsSlider(
    String label,
    double value,
    double min,
    double max,
    Color accent,
    ValueChanged<double> onChanged,
    String display,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Text(
              display,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 20).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return GradientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(accent),
                  Expanded(child: _buildCenter(accent)),
                  _buildBottomSection(accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Voice Hub',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            onPressed: _showSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildCenter(Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _WavePainter(
                    animationValue: _waveController.value,
                    pulseValue: _pulseController.value,
                    state: _state,
                    accent: accent,
                  ),
                );
              },
            ),
            _buildStateIndicator(accent),
          ],
        );
      },
    );
  }

  Widget _buildStateIndicator(Color accent) {
    final isActive = _state != VoiceHubState.idle;
    final size = 100.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        final glow = isActive ? pulse : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size + glow * 20,
              height: size + glow * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _stateColor(accent).withOpacity(0.2 + glow * 0.2),
                    blurRadius: 20 + glow * 30,
                    spreadRadius: 5 + glow * 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _stateColor(accent).withOpacity(0.3 + glow * 0.3),
                        width: 2,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          _stateColor(accent).withOpacity(0.12 + glow * 0.1),
                          _stateColor(accent).withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                  _stateIcon(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _stateLabel(),
            if (_state == VoiceHubState.listening && _transcript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 32, right: 32),
                child: Text(
                  _transcript,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent.withOpacity(0.8),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  Color _stateColor(Color accent) {
    switch (_state) {
      case VoiceHubState.listening:
        return accent;
      case VoiceHubState.processing:
        return const Color(0xFFFF9100);
      case VoiceHubState.speaking:
        return const Color(0xFF00E676);
      case VoiceHubState.idle:
        return Colors.white.withOpacity(0.3);
    }
  }

  Widget _stateIcon() {
    switch (_state) {
      case VoiceHubState.idle:
        return Icon(Icons.mic_none_rounded, size: 40,
            color: Colors.white.withOpacity(0.3));
      case VoiceHubState.listening:
        return const Icon(Icons.mic, size: 40, color: Colors.white);
      case VoiceHubState.processing:
        return const SizedBox(
          width: 36, height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        );
      case VoiceHubState.speaking:
        return const Icon(Icons.volume_up_rounded, size: 40,
            color: Colors.white);
    }
  }

  Widget _stateLabel() {
    String text;
    switch (_state) {
      case VoiceHubState.idle:
        text = 'Tap to speak';
      case VoiceHubState.listening:
        text = 'Listening...';
      case VoiceHubState.processing:
        text = 'Thinking...';
      case VoiceHubState.speaking:
        text = 'Speaking...';
    }
    return Text(
      text,
      style: TextStyle(
        color: _stateColor(
          context.watch<SettingsProvider>().accentColor,
        ),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'SpaceGrotesk',
      ),
    );
  }

  Widget _buildBottomSection(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_lastQuery.isNotEmpty && _state != VoiceHubState.listening)
            _buildTranscript(accent),
          const SizedBox(height: 16),
          _buildMicButton(accent),
        ],
      ),
    );
  }

  Widget _buildTranscript(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastQuery.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.person_outline, size: 14,
                    color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _lastQuery,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ],
          if (_lastResponse.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, const Color(0xFF448AFF)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, size: 10,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Nexus',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _lastResponse,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicButton(Color accent) {
    final isActive = _state != VoiceHubState.idle;

    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = _pulseController.value;

          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isActive
                    ? [_stateColor(accent), _stateColor(accent).withOpacity(0.6)]
                    : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.04)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_stateColor(accent)).withOpacity(isActive ? 0.3 + pulse * 0.2 : 0),
                  blurRadius: 20 + pulse * 20,
                  spreadRadius: 2 + pulse * 5,
                ),
              ],
            ),
            child: Icon(
              _state == VoiceHubState.speaking
                  ? Icons.stop_rounded
                  : _state == VoiceHubState.listening
                      ? Icons.mic
                      : Icons.mic_none_rounded,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
              size: 32,
            ),
          );
        },
      ),
    );
  }
}

// ── Wave Painter ─────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double animationValue;
  final double pulseValue;
  final VoiceHubState state;
  final Color accent;

  _WavePainter({
    required this.animationValue,
    required this.pulseValue,
    required this.state,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isActive = state != VoiceHubState.idle;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final waveCount = 5;
    final baseAmplitude = isActive ? 30.0 + pulseValue * 20 : 10.0;

    for (var i = 0; i < waveCount; i++) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _waveColor(i).withOpacity(isActive ? 0.08 : 0.02),
            _waveColor(i).withOpacity(isActive ? 0.15 : 0.04),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final path = Path();
      final frequency = 0.008 + i * 0.003;
      final amplitude = baseAmplitude * (1 + i * 0.4);
      final phaseOffset = animationValue * 2 * pi + i * 1.2;
      final yOffset = centerY + (i - 2) * 40;

      path.moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y = yOffset +
            sin(x * frequency + phaseOffset) * amplitude * 0.3 +
            sin(x * frequency * 2 + phaseOffset * 1.5) * amplitude * 0.2 +
            sin(x * frequency * 0.5 + phaseOffset * 0.7) * amplitude * 0.15;

        if (x == 0) {
          path.lineTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }

    if (isActive && state == VoiceHubState.listening) {
      final ringPaint = Paint()
        ..color = accent.withOpacity(0.06 * (1 - pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final ringSize = min(size.width, size.height) * 0.6 + pulseValue * 80;
      canvas.drawCircle(
        Offset(centerX, centerY),
        ringSize,
        ringPaint,
      );
    }
  }

  Color _waveColor(int index) {
    switch (index) {
      case 0: return accent;
      case 1: return const Color(0xFF448AFF);
      case 2: return const Color(0xFFE040FB);
      case 3: return const Color(0xFF00E676);
      case 4: return const Color(0xFFFF9100);
      default: return accent;
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
