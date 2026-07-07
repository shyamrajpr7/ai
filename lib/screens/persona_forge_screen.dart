import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/persona.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/gradient_mesh_background.dart';

const _uuid = Uuid();

class PersonaForgeScreen extends StatefulWidget {
  final Persona? existing;

  const PersonaForgeScreen({super.key, this.existing});

  @override
  State<PersonaForgeScreen> createState() => _PersonaForgeScreenState();
}

class _PersonaForgeScreenState extends State<PersonaForgeScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _promptCtrl;

  String _emoji = '🤖';
  Color _color = const Color(0xFF7C4DFF);
  double _creativity = 0.5;
  double _tone = 0.5;
  double _style = 0.5;
  double _expertise = 0.5;
  double _empathy = 0.5;

  String _previewInput = '';
  String _previewResponse = '';
  bool _previewLoading = false;

  static const _emojis = [
    '🤖', '💻', '✍️', '📚', '🧠', '🎨', '🔬', '📐', '🎭', '🧙',
    '🦉', '🐉', '🌟', '💡', '🎯', '⚡', '🌊', '🔥', '❄️', '🌿',
    '⚔️', '🛡️', '🔮', '📡', '🎵', '🎮', '🚀', '💎', '🌈', '🍀',
  ];

  static const _colorOptions = [
    Color(0xFF7C4DFF), Color(0xFF448AFF), Color(0xFFFF4081),
    Color(0xFF00E676), Color(0xFFFFAB00), Color(0xFF00BCD4),
    Color(0xFFE040FB), Color(0xFFFF6D00), Color(0xFF536DFE),
    Color(0xFF69F0AE), Color(0xFFFF5252), Color(0xFF40C4FF),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _promptCtrl = TextEditingController(text: p?.systemPrompt ?? '');
    if (p != null) {
      _emoji = p.emoji;
      _color = p.color;
      _parsePrompt(p.systemPrompt);
    }
    _updatePromptPreview();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  void _parsePrompt(String prompt) {
    if (prompt.contains('creativity')) _creativity = 0.7;
    if (prompt.contains('conversational') || prompt.contains('casual')) _tone = 0.3;
    if (prompt.contains('formal')) _tone = 0.8;
    if (prompt.contains('elaborate') || prompt.contains('detailed')) _style = 0.8;
    if (prompt.contains('concise') || prompt.contains('minimal')) _style = 0.2;
    if (prompt.contains('expert') || prompt.contains('specialist')) _expertise = 0.8;
    if (prompt.contains('empathetic') || prompt.contains('warm')) _empathy = 0.8;
    if (prompt.contains('logical') || prompt.contains('neutral')) _empathy = 0.2;
  }

  String _generatePrompt() {
    final buf = StringBuffer();

    final creativityLabel = _creativity < 0.3
        ? 'precise and factual'
        : _creativity < 0.6
            ? 'balanced'
            : 'creative and imaginative';
    final toneLabel = _tone < 0.3
        ? 'warm and conversational'
        : _tone < 0.6
            ? 'neutral and professional'
            : 'formal and authoritative';
    final styleLabel = _style < 0.3
        ? 'concise and minimal'
        : _style < 0.6
            ? 'moderately detailed'
            : 'elaborate and thorough';
    final expertiseLabel = _expertise < 0.3
        ? 'accessible to beginners'
        : _expertise < 0.6
            ? 'balanced depth'
            : 'deep expert-level analysis';
    final empathyLabel = _empathy < 0.3
        ? 'objective and logical'
        : _empathy < 0.6
            ? 'balanced emotional awareness'
            : 'warm and empathetic';

    buf.writeln('You are $_emoji $expertiseLabel persona named ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Assistant"}.');
    buf.writeln('Communication style: $toneLabel.');
    buf.writeln('Response style: $styleLabel.');
    buf.writeln('Approach: $creativityLabel.');
    buf.writeln('Depth: $expertiseLabel.');
    buf.writeln('Emotional tone: $empathyLabel.');
    buf.writeln('Adapt to the user needs while maintaining this consistent personality.');

    return buf.toString().trim();
  }

  void _updatePromptPreview() {
    _promptCtrl.text = _generatePrompt();
  }

  void _save() async {
    final name = _nameCtrl.text.trim();
    final prompt = _promptCtrl.text.trim();
    if (name.isEmpty || prompt.isEmpty) return;

    final settings = context.read<SettingsProvider>();
    final existing = widget.existing;

    if (existing != null) {
      settings.updatePersona(existing.copyWith(
        name: name,
        systemPrompt: prompt,
        emoji: _emoji,
        color: _color,
      ));
    } else {
      final persona = Persona(
        id: _uuid.v4(),
        name: name,
        systemPrompt: prompt,
        emoji: _emoji,
        color: _color,
      );
      settings.addPersona(persona);
      settings.setActivePersona(persona.id);
    }

    if (mounted) Navigator.pop(context);
  }

  void _delete() {
    final existing = widget.existing;
    if (existing == null || existing.id.startsWith('default-')) return;
    context.read<SettingsProvider>().deletePersona(existing.id);
    if (mounted) Navigator.pop(context);
  }

  void _export() {
    final name = _nameCtrl.text.trim();
    final prompt = _promptCtrl.text.trim();
    if (name.isEmpty || prompt.isEmpty) return;

    final data = jsonEncode({
      'name': name,
      'systemPrompt': prompt,
      'emoji': _emoji,
      'color': _color.value,
      'forge': {
        'creativity': _creativity,
        'tone': _tone,
        'style': _style,
        'expertise': _expertise,
        'empathy': _empathy,
      },
    });

    Clipboard.setData(ClipboardData(text: data));
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Persona exported to clipboard!'),
          duration: const Duration(seconds: 2),
          backgroundColor: context.read<SettingsProvider>().accentColor.withOpacity(0.8),
        ),
      );
    }
  }

  void _import() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    try {
      final json = jsonDecode(data!.text!) as Map<String, dynamic>;
      final forge = json['forge'] as Map<String, dynamic>?;
      setState(() {
        _nameCtrl.text = json['name'] as String? ?? '';
        _promptCtrl.text = json['systemPrompt'] as String? ?? '';
        _emoji = json['emoji'] as String? ?? '🤖';
        _color = Color(json['color'] as int? ?? 0xFF7C4DFF);
        if (forge != null) {
          _creativity = (forge['creativity'] as num?)?.toDouble() ?? _creativity;
          _tone = (forge['tone'] as num?)?.toDouble() ?? _tone;
          _style = (forge['style'] as num?)?.toDouble() ?? _style;
          _expertise = (forge['expertise'] as num?)?.toDouble() ?? _expertise;
          _empathy = (forge['empathy'] as num?)?.toDouble() ?? _empathy;
        }
      });
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported: ${json['name'] ?? 'Unknown'}'),
            duration: const Duration(seconds: 2),
            backgroundColor: context.read<SettingsProvider>().accentColor.withOpacity(0.8),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid persona data in clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendPreview() async {
    if (_previewInput.trim().isEmpty || _previewLoading) return;
    setState(() {
      _previewLoading = true;
      _previewResponse = '';
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      final service = chatProvider.createAIService();
      final response = StringBuffer();
      await for (final chunk in service.streamResponse(
        message: _previewInput,
        history: [],
        systemPrompt: _promptCtrl.text.trim(),
      )) {
        response.write(chunk);
        setState(() => _previewResponse = response.toString());
      }
    } catch (e) {
      setState(() {
        _previewResponse = 'Error: ${e.toString().replaceAll("Exception: ", "")}';
      });
    }

    setState(() => _previewLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      body: GradientMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIdentitySection(accent),
                      _buildSliderSection(accent),
                      _buildPromptPreview(accent),
                      _buildPreviewChat(accent),
                      _buildActions(accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    final isEditing = widget.existing != null;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: Colors.white.withOpacity(0.6)),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.7)],
                  ),
                ),
                child: Center(
                  child: Text(_emoji, style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Forge: ${widget.existing!.name}' : 'Persona Forge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _export,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.file_upload_outlined,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _import,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.file_download_outlined,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySection(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IDENTITY',
            style: TextStyle(
              color: accent.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _updatePromptPreview(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Persona name...',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2), fontSize: 15),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final e = _emojis[index];
                      final selected = e == _emoji;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? accent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.04),
                            border: Border.all(
                              color: selected
                                  ? accent.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(e, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final c = _colorOptions[index];
                      final selected = c == _color;
                      return GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.transparent,
                              width: selected ? 2 : 0,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(
                                    color: c.withOpacity(0.5), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(Color accent) {
    final sliders = [
      ('Creativity', 'Casual, playful', 'Precise, factual', _creativity,
          (double v) => setState(() { _creativity = v; _updatePromptPreview(); })),
      ('Tone', 'Warm, casual', 'Formal, authoritative', _tone,
          (double v) => setState(() { _tone = v; _updatePromptPreview(); })),
      ('Style', 'Concise, brief', 'Elaborate, thorough', _style,
          (double v) => setState(() { _style = v; _updatePromptPreview(); })),
      ('Expertise', 'Beginner-friendly', 'Deep expert', _expertise,
          (double v) => setState(() { _expertise = v; _updatePromptPreview(); })),
      ('Empathy', 'Logical, neutral', 'Warm, caring', _empathy,
          (double v) => setState(() { _empathy = v; _updatePromptPreview(); })),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSONALITY',
            style: TextStyle(
              color: accent.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: sliders.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.$1,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                          const Spacer(),
                          Text(
                            s.$4 < 0.3
                                ? s.$2
                                : s.$4 < 0.6
                                    ? 'Balanced'
                                    : s.$3,
                            style: TextStyle(
                              color: accent.withOpacity(0.7),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          activeTrackColor: accent,
                          inactiveTrackColor: Colors.white.withOpacity(0.08),
                          thumbColor: accent,
                          overlayColor: accent.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: s.$4,
                          onChanged: s.$5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptPreview(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM PROMPT',
            style: TextStyle(
              color: accent.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: _promptCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: 8,
              style: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChat(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PREVIEW CHAT',
                style: TextStyle(
                  color: accent.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              const Spacer(),
              if (_previewResponse.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _previewInput = '';
                    _previewResponse = '';
                  }),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                if (_previewResponse.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _previewResponse,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          onChanged: (v) =>
                              setState(() => _previewInput = v),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Test the persona...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onSubmitted: (_) => _sendPreview(),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _previewLoading ? null : _sendPreview,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _previewInput.trim().isEmpty
                              ? Colors.white.withOpacity(0.04)
                              : accent,
                        ),
                        child: _previewLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accent.withOpacity(0.5),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 16,
                                color: _previewInput.trim().isEmpty
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Color accent) {
    final isEditing = widget.existing != null;
    final canDelete = isEditing && !widget.existing!.id.startsWith('default-');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          if (canDelete)
            Expanded(
              child: GestureDetector(
                onTap: _delete,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (canDelete) const SizedBox(width: 8),
          Expanded(
            flex: canDelete ? 2 : 1,
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isEditing ? 'Update Persona' : 'Create Persona',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
