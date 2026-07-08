import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/meeting_scribe_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class MeetingScribeScreen extends StatefulWidget {
  const MeetingScribeScreen({super.key});

  @override
  State<MeetingScribeScreen> createState() => _MeetingScribeScreenState();
}

class _MeetingScribeScreenState extends State<MeetingScribeScreen>
    with WidgetsBindingObserver {
  stt.SpeechToText? _speech;
  bool _speechAvailable = false;
  Timer? _recordingTimer;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech?.stop();
    _recordingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final provider = context.read<MeetingScribeProvider>();
      if (provider.isRecording) {
        _stopRecording();
      }
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech!.initialize(onError: (_) {});
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _startRecording() {
    if (_speech == null || !_speechAvailable) return;
    final provider = context.read<MeetingScribeProvider>();
    provider.startRecording();

    _speech!.listen(
      onResult: (result) {
        provider.updateTranscript(result.recognizedWords);
        _scrollToBottom();
      },
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopRecording() {
    _speech?.stop();
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final provider = context.read<MeetingScribeProvider>();
    provider.stopRecording();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${d.inHours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;
    final provider = context.watch<MeetingScribeProvider>();

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
            onPressed: () {
              if (provider.currentMeeting != null && !provider.isRecording) {
                provider.startNewMeeting();
              } else {
                Navigator.pop(context);
              }
            },
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
                  child: Icon(Icons.record_voice_over, size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                provider.isRecording
                    ? 'Recording'
                    : provider.currentMeeting != null && provider.currentMeeting!.transcript.isNotEmpty
                        ? provider.currentMeeting!.title
                        : 'Meeting Scribe',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            if (provider.currentMeeting != null && !provider.isRecording && provider.currentMeeting!.transcript.isNotEmpty && provider.currentMeeting!.summary.isEmpty)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                  ),
                  child: provider.isProcessing
                      ? SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                ),
                onPressed: provider.isProcessing ? null : () => provider.processMeeting(),
                tooltip: 'Summarize',
              ),
          ],
        ),
        body: _buildBody(accent, provider),
      ),
    );
  }

  Widget _buildBody(Color accent, MeetingScribeProvider provider) {
    if (provider.isRecording) {
      return _buildRecordingView(accent, provider);
    }
    if (provider.currentMeeting != null && provider.currentMeeting!.transcript.isNotEmpty) {
      if (provider.isProcessing) {
        return _buildProcessingView(accent, provider);
      }
      return _buildMeetingDetail(accent, provider);
    }
    return _buildMeetingList(accent, provider);
  }

  Widget _buildMeetingList(Color accent, MeetingScribeProvider provider) {
    if (provider.meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.record_voice_over, size: 72, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 16),
            Text(
              'No recordings yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a meeting to get AI-powered notes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'Inter',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildRecordButton(accent, large: true),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: provider.meetings.length,
            itemBuilder: (context, index) {
              final meeting = provider.meetings.reversed.toList()[index];
              final actionCount = meeting.actionItems.where((a) => !a.done).length;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  provider.selectMeeting(meeting);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
                        ),
                        child: const Center(
                          child: Icon(Icons.description, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meeting.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _formatDuration(meeting.duration),
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Inter', fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${meeting.transcript.split(' ').length} words',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Inter', fontSize: 12),
                                ),
                                if (actionCount > 0) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.checklist, size: 12, color: Colors.orangeAccent),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$actionCount',
                                    style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Inter', fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildRecordBar(accent),
      ],
    );
  }

  Widget _buildRecordBar(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      child: _buildRecordButton(accent),
    );
  }

  Widget _buildRecordButton(Color accent, {bool large = false}) {
    return GestureDetector(
      onTap: _speechAvailable ? _startRecording : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 32 : 20,
          vertical: large ? 16 : 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]),
          borderRadius: BorderRadius.circular(large ? 20 : 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: large ? 24 : 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _speechAvailable ? 'Start Recording' : 'Initializing...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
                fontSize: large ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingView(Color accent, MeetingScribeProvider provider) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(0.12), Colors.red.withOpacity(0.04)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _pulsingDot(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(provider.recordingDuration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Inter',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Stop',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.liveTranscript.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.record_voice_over, size: 48, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text(
                        'Speak now...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildTranscriptCard(provider.liveTranscript, accent),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _pulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withOpacity(value),
          ),
        );
      },
    );
  }

  Widget _buildTranscriptCard(String text, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontFamily: 'Inter',
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildProcessingView(Color accent, MeetingScribeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: accent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analyzing meeting...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Extracting summary, key points, and action items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontFamily: 'Inter',
                fontSize: 14,
              ),
            ),
            if (provider.currentResponse.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  provider.currentResponse,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingDetail(Color accent, MeetingScribeProvider provider) {
    final meeting = provider.currentMeeting!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        _buildInfoRow(accent, meeting),
        const SizedBox(height: 16),
        if (meeting.summary.isNotEmpty) ...[
          _buildSection('Summary', Icons.article, meeting.summary, accent: accent),
          const SizedBox(height: 12),
        ],
        if (meeting.keyPoints.isNotEmpty) ...[
          _buildSection('Key Points', Icons.lightbulb, null, accent: accent,
              points: meeting.keyPoints),
          const SizedBox(height: 12),
        ],
        if (meeting.actionItems.isNotEmpty) ...[
          _buildSection('Action Items', Icons.checklist, null, accent: accent,
              actionItems: meeting.actionItems),
          const SizedBox(height: 12),
        ],
        if (meeting.transcript.isNotEmpty)
          _buildSection('Full Transcript', Icons.subject, null, accent: accent,
              transcript: meeting.transcript),
      ],
    );
  }

  Widget _buildInfoRow(Color accent, Meeting meeting) {
    final month = meeting.date.month.toString().padLeft(2, '0');
    final day = meeting.date.day.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent, const Color(0xFF448AFF)]),
            ),
            child: const Center(
              child: Icon(Icons.description, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$month/$day/${meeting.date.year}  ·  ${_formatDuration(meeting.duration)}  ·  ${meeting.transcript.split(' ').length} words',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontFamily: 'Inter',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    String? body, {
    List<String>? points,
    List<ActionItem>? actionItems,
    String? transcript,
    Color accent = const Color(0xFF448AFF),
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (body != null)
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          if (points != null)
            ...points.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          if (actionItems != null)
            ...actionItems.map((item) => GestureDetector(
              onTap: () => context.read<MeetingScribeProvider>().toggleActionItem(item),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.done
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: item.done ? Colors.green : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: item.done
                          ? const Icon(Icons.check, size: 12, color: Colors.green)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: TextStyle(
                              color: item.done
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.85),
                              fontFamily: 'Inter',
                              fontSize: 14,
                              decoration: item.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (item.assignee != null && item.assignee!.isNotEmpty)
                            Text(
                              'Assigned to: ${item.assignee}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          if (transcript != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transcript,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
