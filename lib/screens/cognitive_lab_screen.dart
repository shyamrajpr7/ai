import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/code_block.dart';

class _Preset {
  final String name;
  final String systemPrompt;
  final String userPrompt;
  const _Preset(this.name, this.systemPrompt, this.userPrompt);
}

const _presets = [
  _Preset(
    'Creative',
    'You are a visionary creative writer with a lyrical, evocative style. '
        'Write with rich imagery, emotional depth, and vivid detail.',
    'Write a short story about a robot that learns to dream.',
  ),
  _Preset(
    'Code Expert',
    'You are a senior software engineer with deep expertise in code quality, '
        'security, performance, and best practices. Provide clean, well-structured code.',
    'Review this Python function:\n\ndef binary_search(arr, target):\n    left, right = 0, len(arr) - 1\n    while left <= right:\n        mid = (left + right) // 2\n        if arr[mid] == target:\n            return mid\n        elif arr[mid] < target:\n            left = mid + 1\n        else:\n            right = mid - 1\n    return -1',
  ),
  _Preset(
    'Socratic',
    'You are a Socratic teacher. Never give direct answers; instead, guide '
        'the user through probing questions to help them discover insights themselves.',
    'Help me understand how neural networks learn.',
  ),
  _Preset(
    'Summarizer',
    'You are an expert analyst. Extract key insights, action items, and '
        'critical details. Be concise and structured.',
    'Explain the key differences between REST and GraphQL APIs.',
  ),
];

class CognitiveLabScreen extends StatefulWidget {
  const CognitiveLabScreen({super.key});

  @override
  State<CognitiveLabScreen> createState() => _CognitiveLabScreenState();
}

class _CognitiveLabScreenState extends State<CognitiveLabScreen> {
  final _promptController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  double _temperature = 0.7;
  bool _paramsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initLab();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _systemPromptController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _loadPreset(_Preset preset) {
    setState(() {
      _systemPromptController.text = preset.systemPrompt;
      _promptController.text = preset.userPrompt;
    });
    HapticFeedback.lightImpact();
  }

  void _handleRun() {
    final prompt = _promptController.text;
    if (prompt.trim().isEmpty) return;
    final systemPrompt = _systemPromptController.text;
    final temp = _temperature;
    _focusNode.unfocus();
    context.read<ChatProvider>().runLab(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: temp,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<ChatProvider>();

    return GradientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
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
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF00E5FF)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.science_outlined, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cognitive Lab',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildParamsSection(accent, provider),
            Expanded(
              child: provider.labResults.isEmpty && !provider.labProcessing
                  ? _buildIdleState(accent)
                  : _buildResults(accent, provider),
            ),
            _buildInputBar(accent, provider),
          ],
        ),
      ),
    );
  }

  // ── Parameter Controls ─────────────────────────────────

  Widget _buildParamsSection(Color accent, ChatProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _paramsExpanded = !_paramsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.12),
                    ),
                    child: Icon(Icons.tune, size: 14, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Parameters',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _paramsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildParamsContent(accent, provider),
            crossFadeState: _paramsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsContent(Color accent, ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildSectionLabel('System Prompt', accent),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _systemPromptController,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Inter',
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Custom system prompt (optional)',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSectionLabel('Temperature', accent),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: Colors.white.withOpacity(0.08),
                    thumbColor: accent,
                    overlayColor: accent.withOpacity(0.12),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => setState(() => _temperature = v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  _temperature.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSectionLabel('Models', accent),
          const SizedBox(height: 6),
          _buildModelToggles(accent, provider),
          const SizedBox(height: 10),
          _buildSectionLabel('Presets', accent),
          const SizedBox(height: 6),
          _buildPresets(accent),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color accent) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Model Toggles ──────────────────────────────────────

  Widget _buildModelToggles(Color accent, ChatProvider provider) {
    final models = provider.labModels;
    if (models.isEmpty) return const SizedBox.shrink();

    return Row(
      children: models.map((m) {
        final enabled = m.enabled;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => provider.toggleLabModel(m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: enabled
                    ? _modelColor(m.id).withOpacity(0.2)
                    : Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: enabled
                      ? _modelColor(m.id).withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modelIcon(m.id, enabled, accent),
                  const SizedBox(width: 5),
                  Text(
                    m.label,
                    style: TextStyle(
                      color: enabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Presets ────────────────────────────────────────────

  Widget _buildPresets(Color accent) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _presets.map((p) {
        return GestureDetector(
          onTap: () => _loadPreset(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.08),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            child: Text(
              p.name,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Idle State ─────────────────────────────────────────

  Widget _buildIdleState(Color accent) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
                ),
              ),
              child: Icon(
                Icons.science_outlined,
                size: 40,
                color: accent.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prompt Studio',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tune parameters, test prompts, compare telemetry',
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _tipRow(accent, Icons.tune, 'Adjust temperature & system prompt'),
                  const SizedBox(height: 10),
                  _tipRow(accent, Icons.auto_awesome, 'Load preset prompt templates'),
                  const SizedBox(height: 10),
                  _tipRow(accent, Icons.speed, 'Measure TTFT, speed & latency'),
                  const SizedBox(height: 10),
                  _tipRow(accent, Icons.compare_arrows, 'Compare models side-by-side'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(Color accent, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accent.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // ── Results ────────────────────────────────────────────

  Widget _buildResults(Color accent, ChatProvider provider) {
    final results = provider.labResults;
    final allDone = results.isNotEmpty && results.every((r) => r.isComplete);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: results.length + (allDone && results.length > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (allDone && results.length > 1 && index == 0) {
          return _buildComparativeChart(results, accent);
        }
        final resultIdx = allDone && results.length > 1 ? index - 1 : index;
        if (resultIdx < results.length) {
          return _LabResultCard(
            result: results[resultIdx],
            allResults: results,
            accent: accent,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Comparative Chart ──────────────────────────────────

  Widget _buildComparativeChart(List<ArenaResult> results, Color accent) {
    final completed = results.where((r) => r.elapsed != null && r.error == null).toList();
    if (completed.length < 1) return const SizedBox.shrink();

    final maxElapsed = completed
        .map((r) => r.elapsed!.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);
    final maxCps = completed
        .map((r) => r.charsPerSecond ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                ),
                child: Icon(Icons.bar_chart_rounded, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'Comparative Telemetry',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...completed.map((r) {
            final elapsedPct = maxElapsed > 0
                ? r.elapsed!.inMilliseconds / maxElapsed
                : 0.0;
            final cpsPct = maxCps > 0
                ? (r.charsPerSecond ?? 0) / maxCps
                : 0.0;
            final ttft = r.firstTokenLatency;
            final charCount = r.content.length;
            final wordCount = r.content.isEmpty
                ? 0
                : r.content.split(RegExp(r'\s+')).length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _modelIcon(r.modelId, true, accent),
                      const SizedBox(width: 6),
                      Text(
                        r.modelLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${charCount}c / ${wordCount}w',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _chartBar(
                    'Duration',
                    '${_formatDuration(r.elapsed!)}',
                    elapsedPct,
                    _modelColor(r.modelId),
                  ),
                  const SizedBox(height: 4),
                  _chartBar(
                    'Speed',
                    '${r.charsPerSecond?.toStringAsFixed(0) ?? "—"} c/s',
                    cpsPct,
                    _modelColor(r.modelId).withOpacity(0.7),
                  ),
                  const SizedBox(height: 4),
                  _chartBar(
                    'TTFT',
                    ttft != null ? _formatDuration(ttft) : '—',
                    elapsedPct.clamp(0, 1),
                    _modelColor(r.modelId).withOpacity(0.4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chartBar(String label, String value, double pct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 8,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct > 0.03 ? pct : 0.03,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.4),
                        color,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  // ── Input Bar ──────────────────────────────────────────

  Widget _buildInputBar(Color accent, ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: provider.labProcessing
              ? accent.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    focusNode: _focusNode,
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
                      hintText: provider.labProcessing
                          ? 'Running lab...'
                          : 'Type your experimental prompt...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleRun(),
                  ),
                ),
                const SizedBox(width: 4),
                _buildSendButton(accent, provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(Color accent, ChatProvider provider) {
    if (provider.labProcessing) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.15),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, const Color(0xFF00E5FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleRun,
          child: const Center(
            child: Icon(
              Icons.science_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────

  Widget _modelIcon(String id, bool enabled, Color accent) {
    final color = enabled ? _modelColor(id) : Colors.white.withOpacity(0.2);
    switch (id) {
      case 'groq':
        return Icon(Icons.bolt_outlined, size: 14, color: color);
      case 'claude':
        return Icon(Icons.psychology_outlined, size: 14, color: color);
      case 'ollama':
        return Icon(Icons.computer_outlined, size: 14, color: color);
      default:
        return Icon(Icons.smart_toy_outlined, size: 14, color: color);
    }
  }

  Color _modelColor(String id) {
    switch (id) {
      case 'groq': return const Color(0xFF00E676);
      case 'claude': return const Color(0xFFE040FB);
      case 'ollama': return const Color(0xFF448AFF);
      default: return const Color(0xFF7C4DFF);
    }
  }
}

// ── Result Card ──────────────────────────────────────────

class _LabResultCard extends StatelessWidget {
  final ArenaResult result;
  final List<ArenaResult> allResults;
  final Color accent;

  const _LabResultCard({
    required this.result,
    required this.allResults,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isError = result.error != null;
    final isComplete = result.isComplete;
    final hasContent = result.content.isNotEmpty;
    final charCount = result.content.length;
    final wordCount = result.content.isEmpty
        ? 0
        : result.content.split(RegExp(r'\s+')).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.red.withOpacity(0.2)
              : isComplete && result.error == null
                  ? _modelColor(result.modelId).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isError, isComplete, hasContent),
          if (isError)
            _buildError()
          else if (!hasContent && !isComplete)
            _buildLoading()
          else
            _buildContent(),
          if (!isError && isComplete && hasContent)
            _buildTelemetry(charCount, wordCount),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isError, bool isComplete, bool hasContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          _modelIcon(result.modelId, true, accent),
          const SizedBox(width: 8),
          Text(
            result.modelLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const Spacer(),
          if (isError)
            _statusChip('Error', Colors.red.shade300, Colors.red.withOpacity(0.12))
          else if (!isComplete)
            _statusChip('Streaming', _modelColor(result.modelId), _modelColor(result.modelId).withOpacity(0.12))
          else if (result.elapsed != null)
            _statusChip(
              _formatDuration(result.elapsed!),
              _modelColor(result.modelId),
              _modelColor(result.modelId).withOpacity(0.12),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF7C4DFF),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.error!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: MarkdownBody(
        data: result.content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 14,
            height: 1.6,
          ),
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h2: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          h3: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'SpaceGrotesk',
          ),
          strong: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          em: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontStyle: FontStyle.italic,
          ),
          code: const TextStyle(
            color: Color(0xFFE0E0FF),
            fontSize: 12,
            fontFamily: 'monospace',
            backgroundColor: Color(0xFF1A1A2E),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _modelColor(result.modelId).withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 12),
          listBullet: TextStyle(
            color: _modelColor(result.modelId),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
        ),
        builders: {
          'pre': CodeBlockBuilder(),
        },
      ),
    );
  }

  Widget _buildTelemetry(int charCount, int wordCount) {
    final cps = result.charsPerSecond;
    final latency = result.firstTokenLatency;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _statChip(Icons.timer_outlined, _formatDuration(result.elapsed!), 'duration'),
          if (cps != null)
            _statChip(Icons.speed, '${cps.toStringAsFixed(0)} c/s', 'throughput'),
          if (latency != null)
            _statChip(Icons.flash_on_outlined, _formatDuration(latency), 'ttft'),
          _statChip(Icons.text_fields, '$charCount', 'chars'),
          _statChip(Icons.abc_outlined, '$wordCount', 'words'),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    final color = _modelColor(result.modelId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 10,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Color _modelColor(String id) {
    switch (id) {
      case 'groq': return const Color(0xFF00E676);
      case 'claude': return const Color(0xFFE040FB);
      case 'ollama': return const Color(0xFF448AFF);
      default: return const Color(0xFF7C4DFF);
    }
  }

  Widget _modelIcon(String id, bool enabled, Color accent) {
    final color = enabled ? _modelColor(id) : Colors.white.withOpacity(0.2);
    switch (id) {
      case 'groq':
        return Icon(Icons.bolt_outlined, size: 14, color: color);
      case 'claude':
        return Icon(Icons.psychology_outlined, size: 14, color: color);
      case 'ollama':
        return Icon(Icons.computer_outlined, size: 14, color: color);
      default:
        return Icon(Icons.smart_toy_outlined, size: 14, color: color);
    }
  }
}

// ── Helpers ──────────────────────────────────────────────

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '${d.inMilliseconds}ms';
  }
  if (d.inSeconds < 60) {
    final ms = d.inMilliseconds % 1000;
    return '${d.inSeconds}.${(ms ~/ 100)}s';
  }
  final secs = d.inSeconds % 60;
  final mins = d.inMinutes;
  return '${mins}m ${secs}s';
}
