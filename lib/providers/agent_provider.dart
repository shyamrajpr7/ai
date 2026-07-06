import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/agent_task.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import '../services/web_search_service.dart';
import '../services/web_fetch_service.dart';
import '../services/image_gen_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class AgentProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  AgentTask? _currentTask;
  bool _isRunning = false;

  AgentTask? get currentTask => _currentTask;
  bool get isRunning => _isRunning;

  AgentProvider(this._settingsProvider);

  AIService _createAIService({double temperature = 0.3}) {
    final temp = temperature;
    if (_settingsProvider.backend == BackendType.groq) {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      return GroqService(apiKey: apiKey, model: _settingsProvider.groqModel, temperature: temp);
    } else if (_settingsProvider.backend == BackendType.claude) {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      return ClaudeService(apiKey: apiKey, model: _settingsProvider.claudeModel, temperature: temp);
    } else {
      return OllamaService(
        endpoint: _settingsProvider.ollamaEndpoint,
        model: _settingsProvider.ollamaModel,
        temperature: temp,
      );
    }
  }

  Future<String> _callAI(String systemPrompt, String message,
      {double temperature = 0.3}) async {
    final service = _createAIService(temperature: temperature);
    final buffer = StringBuffer();
    await for (final chunk in service.streamResponse(
      message: message,
      history: [],
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString().trim();
  }

  void _addLog(AgentStep step, String message, String level) {
    step.logs.add(AgentLogEntry(message: message, level: level));
    notifyListeners();
  }

  Future<void> runTask(String objective) async {
    if (_isRunning) return;
    _isRunning = true;

    _currentTask = AgentTask(
      id: _uuid.v4(),
      objective: objective,
      title: objective.length > 50
          ? '${objective.substring(0, 50)}...'
          : objective,
      status: AgentStepStatus.running,
    );
    notifyListeners();

    try {
      await _planTask();
      await _executeSteps();

      _currentTask!.status = AgentStepStatus.completed;
      _currentTask!.completedAt = DateTime.now();
    } catch (e) {
      _currentTask!.status = AgentStepStatus.failed;
      _currentTask!.error = e.toString();
      final lastStep = _currentTask!.steps.isNotEmpty
          ? _currentTask!.steps.last
          : null;
      if (lastStep != null && lastStep.status == AgentStepStatus.running) {
        lastStep.status = AgentStepStatus.failed;
        lastStep.error = e.toString();
        _addLog(lastStep, 'Step failed: $e', 'error');
      }
    }

    _isRunning = false;
    notifyListeners();
  }

  Future<void> _planTask() async {
    final task = _currentTask!;
    final planStep = AgentStep(
      id: _uuid.v4(),
      title: 'Planning',
      description: 'Breaking down the objective into executable steps',
      status: AgentStepStatus.running,
      startedAt: DateTime.now(),
    );
    task.steps.add(planStep);
    notifyListeners();

    _addLog(planStep, 'Analyzing objective: "${task.objective}"', 'thought');

    final planPrompt = 'You are a task planner. Break this objective into 3-6 sequential steps.\n\n'
        'Objective: ${task.objective}\n\n'
        'Available tools:\n'
        '- web_search: search the web for information\n'
        '- web_fetch: fetch content from a URL\n'
        '- think: reason about information gathered\n'
        '- generate_image: create an image from a description\n'
        '- finalize: produce the final output\n\n'
        'Return ONLY a JSON array of step objects:\n'
        '[{"title":"Short step name","description":"What to do in this step","tool":"web_search|web_fetch|think|generate_image|finalize","query":"the search query or URL or prompt if applicable"}]\n\n'
        'For the final step, always use tool "finalize" with a description of the output format.\n'
        'Do not include markdown or explanation. Return only valid JSON.';

    String planRaw;
    try {
      planRaw = await _callAI('You are a precise task planner. Return only valid JSON.',
          planPrompt);
    } catch (e) {
      _addLog(planStep, 'Planning failed: $e', 'error');
      rethrow;
    }

    final jsonStart = planRaw.indexOf('[');
    final jsonEnd = planRaw.lastIndexOf(']');
    if (jsonStart == -1 || jsonEnd == -1) {
      _addLog(planStep, 'Could not parse plan from AI response', 'error');
      throw Exception('Failed to parse plan');
    }

    final jsonStr = planRaw.substring(jsonStart, jsonEnd + 1);
    List<dynamic> planSteps;
    try {
      planSteps = jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      _addLog(planStep, 'JSON decode failed: $e', 'error');
      rethrow;
    }

    _addLog(planStep, 'Plan created with ${planSteps.length} steps', 'result');

    for (int i = 0; i < planSteps.length; i++) {
      final s = planSteps[i] as Map<String, dynamic>;
      final step = AgentStep(
        id: _uuid.v4(),
        title: '#${i + 1}: ${s['title'] as String? ?? 'Step ${i + 1}'}',
        description: s['description'] as String? ?? '',
        status: AgentStepStatus.pending,
      );
      task.steps.add(step);
    }

    planStep.status = AgentStepStatus.completed;
    planStep.completedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> _executeSteps() async {
    final task = _currentTask!;
    final planSteps = task.steps.where((s) => s.id != task.steps.first.id).toList();

    for (final step in planSteps) {
      if (task.status == AgentStepStatus.failed) break;

      step.status = AgentStepStatus.running;
      step.startedAt = DateTime.now();
      _addLog(step, 'Starting: ${step.title}', 'info');
      notifyListeners();

      try {
        await _executeStep(task, step);
        step.status = AgentStepStatus.completed;
        step.completedAt = DateTime.now();
      } catch (e) {
        step.status = AgentStepStatus.failed;
        step.error = e.toString();
        _addLog(step, 'Failed: $e', 'error');
        notifyListeners();
        rethrow;
      }
    }

    if (task.steps.any((s) => s.status == AgentStepStatus.failed)) {
      task.status = AgentStepStatus.failed;
    }
  }

  Future<void> _executeStep(AgentTask task, AgentStep step) async {
    final desc = step.description.toLowerCase();
    final tool = _extractTool(desc);

    switch (tool) {
      case 'web_search':
        await _executeWebSearch(step);
        break;
      case 'web_fetch':
        await _executeWebFetch(step);
        break;
      case 'think':
        await _executeThink(task, step);
        break;
      case 'generate_image':
        await _executeGenerateImage(step);
        break;
      case 'finalize':
        await _executeFinalize(task, step);
        break;
      default:
        await _executeThink(task, step);
    }
  }

  String _extractTool(String description) {
    final tools = ['web_search', 'web_fetch', 'think', 'generate_image', 'finalize'];
    for (final t in tools) {
      if (description.contains(t)) return t;
    }
    return 'think';
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  Future<void> _executeWebSearch(AgentStep step) async {
    final query = _extractQuery(step.description, step.title);
    _addLog(step, '🔍 Searching: "$query"', 'tool');

    final apiKey = dotenv.env['TAVILY_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_tavily_api_key_here') {
      _addLog(step, 'Tavily API key not set. Returning mock results.', 'error');
      step.result = 'Web search unavailable: Tavily API key not configured. '
          'Please set TAVILY_API_KEY in .env file.';
      return;
    }

    final searchService = WebSearchService(apiKey: apiKey);
    final result = await searchService.search(query);
    step.result = result;
    step.tokensUsed += result.length ~/ 4;

    _addLog(step, 'Search complete — ${result.length} chars', 'result');
  }

  Future<void> _executeWebFetch(AgentStep step) async {
    final url = _extractQuery(step.description, step.title);
    _addLog(step, '🌐 Fetching: $url', 'tool');

    final fetchService = WebFetchService();
    final result = await fetchService.fetch(url);
    step.result = result;
    step.tokensUsed += result.length ~/ 4;

    _addLog(step, 'Fetch complete — ${result.length} chars', 'result');
  }

  Future<void> _executeThink(AgentTask task, AgentStep step) async {
    final context = _buildContext(task, step);
    _addLog(step, '💭 Reasoning about gathered information...', 'thought');

    final prompt = 'Based on the context below, perform the requested analysis.\n\n'
        'Objective: ${task.objective}\n'
        'Current step: ${step.title} — ${step.description}\n\n'
        'Context so far:\n$context\n\n'
        'Provide a clear, detailed analysis or reasoning.';

    final result = await _callAI(
      'You are a reasoning agent. Think step by step.',
      prompt,
      temperature: 0.5,
    );
    step.result = result;
    step.tokensUsed += result.length ~/ 4;

    _addLog(step, 'Analysis complete', 'result');
  }

  Future<void> _executeGenerateImage(AgentStep step) async {
    final prompt = _extractQuery(step.description, step.title);
    _addLog(step, '🎨 Generating image: "$prompt"', 'tool');

    final imageService = ImageGenService();
    final url = await imageService.generateImage(prompt);
    step.result = url;
    _addLog(step, 'Image generated: $url', 'result');
  }

  Future<void> _executeFinalize(AgentTask task, AgentStep step) async {
    final context = _buildContext(task, step);
    _addLog(step, '📝 Drafting final output...', 'tool');

    final prompt = 'You are a report writer. Based on all the information gathered, '
        'produce the final output for this objective.\n\n'
        'Objective: ${task.objective}\n'
        'Output format: ${step.description}\n\n'
        'Context (all prior steps):\n$context\n\n'
        'Produce a comprehensive, well-formatted final result.';

    final result = await _callAI(
      'You are a professional report writer. Format the output clearly.',
      prompt,
      temperature: 0.4,
    );
    step.result = result;
    task.finalResult = result;
    step.tokensUsed += result.length ~/ 4;
    task.totalTokens =
        task.steps.fold(0, (sum, s) => sum + s.tokensUsed);

    _addLog(step, 'Final output ready', 'result');
  }

  String _buildContext(AgentTask task, AgentStep currentStep) {
    final buffer = StringBuffer();
    final currentIdx = task.steps.indexOf(currentStep);
    final priorSteps = task.steps.sublist(0, currentIdx > 0 ? currentIdx : 0);

    for (final s in priorSteps) {
      if (s.result != null && s.result!.isNotEmpty) {
        buffer.writeln('--- ${s.title} ---');
        buffer.writeln(s.result);
        buffer.writeln();
      }
    }

    return buffer.toString().isEmpty ? 'No prior context available.' : buffer.toString();
  }

  String _extractQuery(String description, String title) {
    final combined = '$description $title';
    final patterns = [
      RegExp(r'query[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'query[:\s]+([^\n,.]+)', caseSensitive: false),
      RegExp(r'search[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'search[:\s]+([^\n,.]+)', caseSensitive: false),
      RegExp(r'url[:\s]+(\S+)', caseSensitive: false),
      RegExp(r'"([^"]+)"'),
    ];

    for (final p in patterns) {
      final match = p.firstMatch(combined);
      if (match != null) {
        final q = match.group(1)?.trim();
        if (q != null && q.isNotEmpty && q.length < 200) return q;
      }
    }

    return title.replaceAll(RegExp(r'^#\d+:\s*'), '').trim();
  }

  void reset() {
    _currentTask = null;
    _isRunning = false;
    notifyListeners();
  }
}
