import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static const _keywords = {
    'dart': {
      'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
      'class', 'const', 'continue', 'covariant', 'default', 'deferred',
      'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
      'external', 'factory', 'false', 'final', 'finally', 'for', 'Function',
      'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is',
      'late', 'library', 'mixin', 'new', 'null', 'on', 'operator', 'part',
      'required', 'rethrow', 'return', 'set', 'show', 'static', 'super',
      'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var',
      'void', 'while', 'with', 'yield',
    },
    'python': {
      'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
      'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for',
      'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'None',
      'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'self', 'True',
      'try', 'while', 'with', 'yield',
    },
    'javascript': {
      'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
      'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends',
      'false', 'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof',
      'let', 'new', 'null', 'of', 'return', 'static', 'super', 'switch',
      'this', 'throw', 'true', 'try', 'typeof', 'var', 'void', 'while', 'with',
      'yield',
    },
    'typescript': {
      'abstract', 'any', 'async', 'await', 'break', 'case', 'catch', 'class',
      'const', 'continue', 'debugger', 'declare', 'default', 'delete', 'do',
      'else', 'enum', 'export', 'extends', 'false', 'finally', 'for', 'function',
      'if', 'implements', 'import', 'in', 'instanceof', 'interface', 'let',
      'new', 'null', 'of', 'override', 'private', 'protected', 'public',
      'readonly', 'return', 'static', 'super', 'switch', 'this', 'throw',
      'true', 'try', 'type', 'typeof', 'var', 'void', 'while', 'with', 'yield',
    },
    'java': {
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch',
      'char', 'class', 'const', 'continue', 'default', 'do', 'double', 'else',
      'enum', 'extends', 'false', 'final', 'finally', 'float', 'for', 'goto',
      'if', 'implements', 'import', 'instanceof', 'int', 'interface', 'long',
      'native', 'new', 'null', 'package', 'private', 'protected', 'public',
      'return', 'short', 'static', 'strictfp', 'super', 'switch', 'synchronized',
      'this', 'throw', 'throws', 'transient', 'true', 'try', 'void', 'volatile',
      'while',
    },
    'cpp': {
      'auto', 'bool', 'break', 'case', 'catch', 'char', 'class', 'const',
      'constexpr', 'continue', 'default', 'delete', 'do', 'double', 'else',
      'enum', 'explicit', 'export', 'extern', 'false', 'float', 'for', 'friend',
      'goto', 'if', 'inline', 'int', 'long', 'mutable', 'namespace', 'new',
      'noexcept', 'nullptr', 'operator', 'override', 'private', 'protected',
      'public', 'return', 'short', 'signed', 'sizeof', 'static', 'struct',
      'switch', 'template', 'this', 'throw', 'true', 'try', 'typedef', 'typename',
      'union', 'unsigned', 'using', 'virtual', 'void', 'volatile', 'while',
    },
    'go': {
      'break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else',
      'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import', 'interface',
      'map', 'package', 'range', 'return', 'select', 'struct', 'switch',
      'type', 'var',
    },
    'rust': {
      'as', 'async', 'await', 'break', 'const', 'continue', 'crate', 'dyn',
      'else', 'enum', 'extern', 'false', 'fn', 'for', 'if', 'impl', 'in',
      'let', 'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref', 'return',
      'self', 'static', 'struct', 'super', 'trait', 'true', 'type', 'unsafe',
      'use', 'where', 'while', 'yield',
    },
    'swift': {
      'as', 'async', 'await', 'break', 'case', 'catch', 'class', 'continue',
      'default', 'defer', 'do', 'else', 'enum', 'extension', 'false', 'fileprivate',
      'for', 'func', 'guard', 'if', 'import', 'in', 'init', 'inout', 'internal',
      'is', 'let', 'nil', 'open', 'operator', 'override', 'private', 'protocol',
      'public', 'repeat', 'return', 'self', 'static', 'struct', 'subscript',
      'super', 'switch', 'throw', 'true', 'try', 'typealias', 'var', 'where',
      'while',
    },
    'kotlin': {
      'abstract', 'annotation', 'as', 'break', 'by', 'catch', 'class', 'companion',
      'const', 'constructor', 'continue', 'crossinline', 'data', 'delegate', 'do',
      'else', 'enum', 'false', 'final', 'finally', 'for', 'fun', 'if', 'import',
      'in', 'init', 'inline', 'interface', 'internal', 'is', 'lateinit', 'noinline',
      'null', 'object', 'open', 'operator', 'out', 'override', 'private', 'protected',
      'public', 'reified', 'return', 'sealed', 'super', 'suspend', 'tailrec',
      'this', 'throw', 'true', 'try', 'typealias', 'val', 'var', 'vararg', 'when',
      'while',
    },
    'ruby': {
      'alias', 'and', 'begin', 'break', 'case', 'class', 'def', 'defined?', 'do',
      'else', 'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in', 'module',
      'next', 'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return', 'self',
      'super', 'then', 'true', 'undef', 'unless', 'until', 'when', 'while', 'yield',
    },
    'php': {
      'abstract', 'and', 'array', 'as', 'break', 'callable', 'case', 'catch',
      'class', 'clone', 'const', 'continue', 'declare', 'default', 'die', 'do',
      'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor', 'endforeach',
      'endif', 'endswitch', 'endwhile', 'eval', 'exit', 'extends', 'false',
      'final', 'finally', 'fn', 'for', 'foreach', 'function', 'global', 'goto',
      'if', 'implements', 'include', 'instanceof', 'interface', 'isset', 'list',
      'match', 'mixed', 'namespace', 'new', 'null', 'object', 'or', 'print',
      'private', 'protected', 'public', 'readonly', 'require', 'return', 'static',
      'switch', 'throw', 'trait', 'true', 'try', 'unset', 'use', 'var', 'void',
      'while', 'xor', 'yield',
    },
    'csharp': {
      'abstract', 'as', 'async', 'await', 'base', 'bool', 'break', 'byte', 'case',
      'catch', 'char', 'checked', 'class', 'const', 'continue', 'decimal', 'default',
      'delegate', 'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern',
      'false', 'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if',
      'implicit', 'in', 'int', 'interface', 'internal', 'is', 'lock', 'long',
      'namespace', 'new', 'null', 'object', 'operator', 'out', 'override', 'params',
      'private', 'protected', 'public', 'readonly', 'ref', 'return', 'sbyte',
      'sealed', 'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct',
      'switch', 'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong',
      'unchecked', 'unsafe', 'ushort', 'using', 'value', 'var', 'virtual', 'void',
      'volatile', 'while',
    },
  };

  static const _builtinTypes = {
    'dart': {
      'int', 'double', 'num', 'String', 'bool', 'List', 'Set', 'Map', 'Record',
      'Object', 'Never', 'Null', 'Symbol',
    },
    'python': {
      'int', 'float', 'str', 'bool', 'list', 'dict', 'tuple', 'set', 'frozenset',
      'bytes', 'bytearray', 'NoneType', 'type', 'object',
    },
    'typescript': {
      'string', 'number', 'boolean', 'symbol', 'bigint', 'undefined', 'null',
      'void', 'never', 'any', 'unknown', 'object', 'array',
    },
    'java': {
      'String', 'Integer', 'Boolean', 'Double', 'Float', 'Long', 'Short', 'Byte',
      'Character', 'Void', 'Object', 'Class', 'Enum',
    },
  };

  static const _stringColors = <String, Color>{
    'string': Color(0xFFCE9178),
    'keyword': Color(0xFF569CD6),
    'type': Color(0xFF4EC9B0),
    'comment': Color(0xFF6A9955),
    'number': Color(0xFFB5CEA8),
    'punctuation': Color(0xFFD4D4D4),
    'plain': Color(0xFFE0E0FF),
    'annotation': Color(0xFFDCDCAA),
  };

  static List<TextSpan> highlight(String code, String language) {
    if (code.isEmpty) return [const TextSpan(text: '')];
    final spans = <TextSpan>[];
    final keywords = _keywords[language] ?? {};
    final builtins = _builtinTypes[language] ?? <String>{};

    final combined = RegExp(
      r'(#.*$)|'           // Python/shebang comments
      r'(\/\/[^\n]*(?:\n|$))|'  // single-line comments
      r'(\/\*[\s\S]*?\*\/)|'    // multi-line comments
      r'("(?:[^"\\]|\\.)*")|'   // double-quoted strings
      r"('(?:[^'\\]|\\.)*')|"   // single-quoted strings
      r'(`(?:[^`\\]|\\.)*`)|'   // backtick strings
      r'(\b(?:0x[0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b)|'  // numbers
      r'(@\w+)'                  // annotations/attributes
      r'',
      multiLine: true,
    );

    int lastEnd = 0;
    for (final match in combined.allMatches(code)) {
      if (match.start > lastEnd) {
        final text = code.substring(lastEnd, match.start);
        spans.addAll(_highlightWords(text, keywords, builtins));
      }

      if (match.group(1) != null || match.group(2) != null || match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(0)!,
          style: TextStyle(color: _stringColors['comment']),
        ));
      } else if (match.group(4) != null || match.group(5) != null || match.group(6) != null) {
        spans.add(TextSpan(
          text: match.group(0)!,
          style: TextStyle(color: _stringColors['string']),
        ));
      } else if (match.group(7) != null) {
        spans.add(TextSpan(
          text: match.group(0)!,
          style: TextStyle(color: _stringColors['number']),
        ));
      } else if (match.group(8) != null) {
        spans.add(TextSpan(
          text: match.group(0)!,
          style: TextStyle(color: _stringColors['annotation']),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < code.length) {
      spans.addAll(_highlightWords(
        code.substring(lastEnd),
        keywords,
        builtins,
      ));
    }

    return spans;
  }

  static List<TextSpan> _highlightWords(
    String text,
    Set<String> keywords,
    Set<String> builtins,
  ) {
    final spans = <TextSpan>[];
    final wordRegExp = RegExp(r'([a-zA-Z_$]\w*)');
    int lastEnd = 0;

    for (final match in wordRegExp.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: _stringColors['punctuation']),
        ));
      }

      final word = match.group(1)!;
      Color color;
      if (keywords.contains(word)) {
        color = _stringColors['keyword']!;
      } else if (builtins.contains(word)) {
        color = _stringColors['type']!;
      } else {
        color = _stringColors['plain']!;
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(color: color),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: _stringColors['punctuation']),
      ));
    }

    return spans;
  }
}
