import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../services/ai_service.dart';
import '../services/groq_service.dart';
import '../services/claude_service.dart';
import '../services/ollama_service.dart';
import 'settings_provider.dart';

const _uuid = Uuid();

class OracleDocument {
  final String id;
  final String name;
  final String content;
  final List<DocumentChunk> chunks;
  final DateTime addedAt;
  final int pageCount;

  OracleDocument({
    required this.id,
    required this.name,
    required this.content,
    required this.chunks,
    required this.pageCount,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();
}

class DocumentChunk {
  final String id;
  final String text;
  final int index;

  DocumentChunk({required this.id, required this.text, required this.index});
}

class OracleMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  OracleMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DocumentOracleProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  OracleDocument? _document;
  List<OracleMessage> _messages = [];
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _error;
  String _currentResponse = '';

  OracleDocument? get document => _document;
  List<OracleMessage> get messages => _messages;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentResponse => _currentResponse;

  DocumentOracleProvider(this._settingsProvider);

  Future<void> pickDocument() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'json', 'xml', 'html', 'yaml', 'yml', 'log', 'pdf'],
      );

      if (result == null || result.files.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final file = result.files.first;
      final name = file.name;
      final ext = name.split('.').last.toLowerCase();
      String text;
      int pageCount = 0;

      if (ext == 'pdf') {
        final bytes = file.bytes;
        if (bytes == null) {
          final path = file.path;
          if (path == null) throw Exception('Could not read file');
          final pdfBytes = await File(path).readAsBytes();
          text = _extractPdfText(pdfBytes);
          pageCount = _getPdfPageCount(pdfBytes);
        } else {
          text = _extractPdfText(bytes);
          pageCount = _getPdfPageCount(bytes);
        }
      } else {
        if (file.path != null) {
          text = await File(file.path!).readAsString();
        } else if (file.bytes != null) {
          text = String.fromCharCodes(file.bytes!);
        } else {
          throw Exception('Could not read file content');
        }
        pageCount = 1;
      }

      if (text.trim().isEmpty) {
        throw Exception('No text content found in the document');
      }

      final chunks = _chunkText(text);
      _document = OracleDocument(
        id: _uuid.v4(),
        name: name,
        content: text,
        chunks: chunks,
        pageCount: pageCount,
      );
      _messages = [];
      _currentResponse = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  String _extractPdfText(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        buffer.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
      }
      return buffer.toString();
    } finally {
      document.dispose();
    }
  }

  int _getPdfPageCount(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return document.pages.count;
    } finally {
      document.dispose();
    }
  }

  List<DocumentChunk> _chunkText(String text, {int chunkSize = 1500, int overlap = 200}) {
    final chunks = <DocumentChunk>[];
    if (text.length <= chunkSize) {
      chunks.add(DocumentChunk(id: _uuid.v4(), text: text, index: 0));
      return chunks;
    }

    int start = 0;
    int index = 0;
    while (start < text.length) {
      int end = start + chunkSize;
      if (end >= text.length) {
        end = text.length;
      } else {
        final nextPeriod = text.indexOf('. ', end);
        final nextNewline = text.indexOf('\n', end);
        int breakAt = end;
        if (nextPeriod != -1 && nextPeriod - end < 100) {
          breakAt = nextPeriod + 1;
        } else if (nextNewline != -1 && nextNewline - end < 50) {
          breakAt = nextNewline;
        }
        end = breakAt;
      }

      final chunkText = text.substring(start, end).trim();
      if (chunkText.isNotEmpty) {
        chunks.add(DocumentChunk(id: _uuid.v4(), text: chunkText, index: index));
        index++;
      }
      start = end - overlap;
      if (start >= text.length) break;
    }
    return chunks;
  }

  List<DocumentChunk> _retrieveRelevantChunks(String query, {int topK = 5}) {
    if (_document == null) return [];
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (queryWords.isEmpty) return _document!.chunks.take(topK).toList();

    final scored = <_ChunkScore>[];
    for (final chunk in _document!.chunks) {
      final lower = chunk.text.toLowerCase();
      int score = 0;
      for (final word in queryWords) {
        if (lower.contains(word)) score++;
      }
      if (score > 0) {
        scored.add(_ChunkScore(chunk: chunk, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).map((s) => s.chunk).toList();
  }

  Future<void> askQuestion(String question) async {
    if (question.trim().isEmpty || _document == null || _isProcessing) return;

    _messages.add(OracleMessage(id: _uuid.v4(), role: 'user', content: question));
    _isProcessing = true;
    _currentResponse = '';
    _error = null;
    notifyListeners();

    try {
      final relevantChunks = _retrieveRelevantChunks(question);
      final context = relevantChunks.map((c) => '[Chunk ${c.index + 1}]\n${c.text}').join('\n\n---\n\n');

      final systemPrompt = 'You are a document analysis assistant. Answer the user\'s question based ONLY on the provided document context below. '
          'If the context does not contain enough information to answer, say so clearly. '
          'Cite relevant sections when possible.\n\n'
          'Document: ${_document!.name}\n'
          '--- Document Context ---\n$context';

      final service = _createAIService();
      final buffer = StringBuffer();

      await for (final chunk in service.streamResponse(
        message: question,
        history: _messages
            .where((m) => m.role == 'user')
            .map((m) => {'role': 'user', 'content': m.content})
            .toList(),
        systemPrompt: systemPrompt,
      )) {
        buffer.write(chunk);
        _currentResponse = buffer.toString();
        notifyListeners();
      }

      final response = buffer.toString();
      if (response.isNotEmpty) {
        _messages.add(OracleMessage(id: _uuid.v4(), role: 'assistant', content: response));
      }

      _isProcessing = false;
      _currentResponse = '';
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  AIService _createAIService() {
    final temp = _settingsProvider.temperature;
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

  void clearDocument() {
    _document = null;
    _messages = [];
    _currentResponse = '';
    _error = null;
    _isProcessing = false;
    notifyListeners();
  }
}

class _ChunkScore {
  final DocumentChunk chunk;
  final int score;
  _ChunkScore({required this.chunk, required this.score});
}
