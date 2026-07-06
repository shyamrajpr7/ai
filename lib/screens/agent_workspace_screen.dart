import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent_task.dart';
import '../providers/agent_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class AgentWorkspaceScreen extends StatefulWidget {
  const AgentWorkspaceScreen({super.key});

  @override
  State<AgentWorkspaceScreen> createState() => _AgentWorkspaceScreenState();
}

class _AgentWorkspaceScreenState extends State<AgentWorkspaceScreen> {
  final _taskController = TextEditingController();
  final _consoleScrollController = ScrollController();
  final _stepsScrollController = ScrollController();
  bool _showDiagnostics = false;

  @override
  void dispose() {
    _taskController.dispose();
    _consoleScrollController.dispose();
    _stepsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Agent Workspace',
          style: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600),
        ),
        actions: [
          Consumer<AgentProvider>(
            builder: (context, agent, _) {
              if (agent.currentTask == null) return const SizedBox();
              return IconButton(
                icon: Icon(_showDiagnostics ? Icons.show_chart : Icons.analytics_outlined,
                    color: accent),
                onPressed: () => setState(() => _showDiagnostics = !_showDiagnostics),
                tooltip: 'Toggle diagnostics',
              );
            },
          ),
          Consumer<AgentProvider>(
            builder: (context, agent, _) {
              if (agent.currentTask == null && !agent.isRunning) return const SizedBox();
              return IconButton(
                icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.7)),
                onPressed: () => context.read<AgentProvider>().reset(),
                tooltip: 'New task',
              );
            },
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
              children: [
                _buildInputCard(accent),
                Expanded(
                  child: Consumer<AgentProvider>(
                    builder: (context, agent, _) {
                      final task = agent.currentTask;
                      if (task == null) {
                        return _buildEmptyState(accent);
                      }
                      return _buildWorkspace(task, agent, accent);
                    },
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildInputCard(Color accent) {
    return Consumer<AgentProvider>(
      builder: (context, agent, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: agent.isRunning
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.psychology, size: 18, color: accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Define a multi-step task',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  controller: _taskController,
                  enabled: !agent.isRunning,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Research solid-state batteries, summarize 3 papers, format as newsletter',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (agent.isRunning)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                    if (agent.isRunning)
                      const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: MaterialButton(
                        onPressed: agent.isRunning
                            ? null
                            : () => _startTask(context),
                        height: 32,
                        minWidth: 80,
                        elevation: 0,
                        color: agent.isRunning
                            ? Colors.white.withOpacity(0.1)
                            : accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          agent.isRunning ? 'Running...' : 'Launch Agent',
                          style: TextStyle(
                            color: agent.isRunning
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startTask(BuildContext context) {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    context.read<AgentProvider>().runTask(text);
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: accent.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Agent Workspace',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 20,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 280,
            child: Text(
              'Define a complex multi-step task above, then watch the agent plan, research, and deliver results in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSamplePrompt(accent, 'Find latest tech news about solid-state batteries, summarize the top 3 papers, format as markdown newsletter'),
          const SizedBox(height: 8),
          _buildSamplePrompt(accent, 'Research AI coding assistants, compare features, create a comparison table'),
          const SizedBox(height: 8),
          _buildSamplePrompt(accent, 'Search for Flutter UI trends 2026, generate a hero image, write a summary'),
        ],
      ),
    );
  }

  Widget _buildSamplePrompt(Color accent, String prompt) {
    return GestureDetector(
      onTap: () {
        _taskController.text = prompt;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, size: 14, color: accent.withOpacity(0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prompt,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspace(AgentTask task, AgentProvider agent, Color accent) {
    return Column(
      children: [
        if (_showDiagnostics) _buildDiagnosticsPanel(task, accent),
        _buildStepTracker(task, accent),
        Expanded(child: _buildConsole(task, accent)),
        if (task.finalResult != null) _buildResultBanner(accent),
      ],
    );
  }

  Widget _buildStepTracker(AgentTask task, Color accent) {
    final steps = task.steps;
    if (steps.isEmpty) return const SizedBox();

    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        controller: _stepsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return _buildStepChip(step, accent, index);
        },
      ),
    );
  }

  Widget _buildStepChip(AgentStep step, Color accent, int index) {
    Color bgColor;
    IconData icon;
    bool isPulsing = false;

    switch (step.status) {
      case AgentStepStatus.running:
        bgColor = accent.withOpacity(0.25);
        icon = Icons.sync;
        isPulsing = true;
      case AgentStepStatus.completed:
        bgColor = const Color(0xFF00E676).withOpacity(0.2);
        icon = Icons.check_circle;
      case AgentStepStatus.failed:
        bgColor = const Color(0xFFFF5252).withOpacity(0.2);
        icon = Icons.error;
      case AgentStepStatus.pending:
      default:
        bgColor = Colors.white.withOpacity(0.06);
        icon = Icons.circle_outlined;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.status == AgentStepStatus.running
              ? accent.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPulsing)
            _PulsingIcon(icon: icon, color: accent, size: 14)
          else
            Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.title.length > 18
                    ? '${step.title.substring(0, 18)}...'
                    : step.title,
                style: TextStyle(
                  color: step.status == AgentStepStatus.pending
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (step.duration != null)
                Text(
                  _formatDuration(step.duration!),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsPanel(AgentTask task, Color accent) {
    final totalTokens = task.steps.fold<int>(0, (sum, s) => sum + s.tokensUsed);
    final completedSteps =
        task.steps.where((s) => s.status == AgentStepStatus.completed).length;
    final totalDuration = task.totalDuration;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'Diagnostics',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _diagnosticTile('Steps', '$completedSteps/${task.steps.length}', Icons.list, accent),
              const SizedBox(width: 12),
              _diagnosticTile('Tokens', _formatNumber(totalTokens), Icons.token, accent),
              const SizedBox(width: 12),
              _diagnosticTile(
                'Time',
                totalDuration != null ? _formatDuration(totalDuration) : '--',
                Icons.timer,
                accent,
              ),
              const SizedBox(width: 12),
              _diagnosticTile(
                'Status',
                task.status == AgentStepStatus.completed
                    ? 'Done'
                    : task.status == AgentStepStatus.failed
                        ? 'Failed'
                        : 'Running',
                task.status == AgentStepStatus.completed
                    ? Icons.check_circle
                    : task.status == AgentStepStatus.failed
                        ? Icons.error
                        : Icons.sync,
                task.status == AgentStepStatus.completed
                    ? const Color(0xFF00E676)
                    : task.status == AgentStepStatus.failed
                        ? const Color(0xFFFF5252)
                        : accent,
              ),
            ],
          ),
          if (task.steps.any((s) => s.tokensUsed > 0)) ...[
            const SizedBox(height: 8),
            _buildTokenChart(task, accent),
          ],
        ],
      ),
    );
  }

  Widget _diagnosticTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.6)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChart(AgentTask task, Color accent) {
    final steps = task.steps.where((s) => s.tokensUsed > 0).toList();
    if (steps.isEmpty) return const SizedBox();
    final maxTokens = steps.fold<int>(0, (m, s) => s.tokensUsed > m ? s.tokensUsed : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Token usage by step',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  s.title.length > 12 ? '${s.title.substring(0, 12)}...' : s.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: maxTokens > 0 ? s.tokensUsed / maxTokens : 0,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation(
                      s.status == AgentStepStatus.completed
                          ? const Color(0xFF00E676)
                          : accent,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  _formatNumber(s.tokensUsed),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildConsole(AgentTask task, Color accent) {
    final allLogs = task.steps.expand((s) => s.logs).toList();

    if (allLogs.isEmpty && task.steps.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for task...',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    if (allLogs.isEmpty && task.steps.isNotEmpty) {
      return const Center(
        child: Text(
          'Initializing...',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 14, color: accent.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  'Thought Console',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${allLogs.length} entries',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.builder(
              controller: _consoleScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: allLogs.length,
              itemBuilder: (context, index) {
                final log = allLogs[index];
                return _buildLogEntry(log, accent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(AgentLogEntry log, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              log.icon,
              size: 13,
              color: log.displayColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              log.message,
              style: TextStyle(
                color: log.displayColor,
                fontSize: 12,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
          ),
          Text(
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.15),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner(Color accent) {
    return Consumer<AgentProvider>(
      builder: (context, agent, _) {
        final result = agent.currentTask?.finalResult;
        if (result == null || result.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: Icon(Icons.check_circle, color: const Color(0xFF00E676), size: 20),
            title: Text(
              'Final Result Ready',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Tap to expand (${result.length} chars)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SelectableText(
                  result,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inSeconds}s';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    this.size = 14,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
