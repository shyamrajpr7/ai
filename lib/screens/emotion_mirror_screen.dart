import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_mirror_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

EmotionType _parseEmotion(String name) {
  return EmotionType.values.firstWhere(
    (e) => e.name == name,
    orElse: () => EmotionType.neutral,
  );
}

Color _emotionColor(EmotionType type) {
  switch (type) {
    case EmotionType.joy: return const Color(0xFFFFD700);
    case EmotionType.sadness: return const Color(0xFF448AFF);
    case EmotionType.anger: return const Color(0xFFFF4444);
    case EmotionType.fear: return const Color(0xFFAA66CC);
    case EmotionType.surprise: return const Color(0xFFFF8800);
    case EmotionType.disgust: return const Color(0xFF66BB6A);
    case EmotionType.neutral: return const Color(0xFF9E9E9E);
  }
}

IconData _emotionIcon(EmotionType type) {
  switch (type) {
    case EmotionType.joy: return Icons.emoji_emotions;
    case EmotionType.sadness: return Icons.sentiment_very_dissatisfied;
    case EmotionType.anger: return Icons.mood_bad;
    case EmotionType.fear: return Icons.psychology;
    case EmotionType.surprise: return Icons.favorite_border;
    case EmotionType.disgust: return Icons.sick;
    case EmotionType.neutral: return Icons.sentiment_neutral;
  }
}

String _emotionLabel(EmotionType type) {
  switch (type) {
    case EmotionType.joy: return 'Joy';
    case EmotionType.sadness: return 'Sadness';
    case EmotionType.anger: return 'Anger';
    case EmotionType.fear: return 'Fear';
    case EmotionType.surprise: return 'Surprise';
    case EmotionType.disgust: return 'Disgust';
    case EmotionType.neutral: return 'Neutral';
  }
}

class EmotionMirrorScreen extends StatefulWidget {
  const EmotionMirrorScreen({super.key});

  @override
  State<EmotionMirrorScreen> createState() => _EmotionMirrorScreenState();
}

class _EmotionMirrorScreenState extends State<EmotionMirrorScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<EmotionMirrorProvider>();

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
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.white70,
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
                  gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                ),
                child: const Center(
                  child: Icon(Icons.mood, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Emotion Mirror',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            if (provider.timeline.isNotEmpty)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.white.withOpacity(0.6)),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.clear();
                },
                tooltip: 'Clear',
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (provider.currentEmotion != null)
                    _buildEmotionCard(provider, accent),
                  if (provider.currentEmotion != null) ...[
                    const SizedBox(height: 16),
                    _buildScoreBars(provider),
                  ],
                  if (provider.timeline.length >= 2) ...[
                    const SizedBox(height: 20),
                    _buildTimeline(provider),
                  ],
                  if (provider.timeline.isEmpty && !provider.isAnalyzing)
                    _buildEmptyState(accent),
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.redAccent, fontFamily: 'Inter', fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            _buildInputBar(accent, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mood, size: 72, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 16),
            Text(
              'Mirror your emotions',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type or speak a phrase to analyze its emotional tone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'Inter',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionCard(EmotionMirrorProvider provider, Color accent) {
    final emotion = provider.currentEmotion!;
    final color = _emotionColor(emotion.primaryEmotion);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Center(
                  child: Icon(_emotionIcon(emotion.primaryEmotion), size: 36, color: color),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _emotionLabel(emotion.primaryEmotion),
                    style: TextStyle(
                      color: color,
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Intensity: ${(emotion.intensity * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Inter',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: emotion.intensity,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          if (emotion.explanation != null && emotion.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              emotion.explanation!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBars(EmotionMirrorProvider provider) {
    final emotion = provider.currentEmotion!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotion Spectrum',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...emotion.scores.map((score) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(_emotionIcon(score.type), size: 14, color: _emotionColor(score.type)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    _emotionLabel(score.type),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Inter',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score.score,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation(_emotionColor(score.type)),
                      minHeight: 6,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${(score.score * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Inter',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTimeline(EmotionMirrorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sentiment Timeline',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (provider.dominantEmotionOverTime.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _emotionColor(_parseEmotion(provider.dominantEmotionOverTime)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Dominant: ${_emotionLabel(_parseEmotion(provider.dominantEmotionOverTime))}',
                    style: TextStyle(
                      color: _emotionColor(_parseEmotion(provider.dominantEmotionOverTime)),
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.timeline.length,
              separatorBuilder: (_, __) => Container(
                width: 24,
                alignment: Alignment.center,
                child: Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              itemBuilder: (context, index) {
                final snapshot = provider.timeline[index];
                final color = _emotionColor(snapshot.result.primaryEmotion);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.analyzeText(snapshot.sourceText);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color.withOpacity(0.5), width: 2),
                        ),
                        child: Center(
                          child: Icon(_emotionIcon(snapshot.result.primaryEmotion), size: 16, color: color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(snapshot.result.intensity * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Inter',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.timeline.length} analys${provider.timeline.length == 1 ? 'is' : 'es'} · Tap to revisit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontFamily: 'Inter',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color accent, EmotionMirrorProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1A1A2E).withOpacity(0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type something to analyze...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontFamily: 'Inter'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = _textController.text.trim();
              if (text.isNotEmpty && !provider.isAnalyzing) {
                HapticFeedback.lightImpact();
                _textController.clear();
                _focusNode.unfocus();
                provider.analyzeText(text);
              }
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
              ),
              child: Center(
                child: provider.isAnalyzing
                    ? SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withOpacity(0.7)),
                      )
                    : const Icon(Icons.psychology, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
