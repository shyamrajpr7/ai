import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  double _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';
  int _strength = 0;
  final _history = <String>[];

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    final chars = StringBuffer();
    if (_includeLowercase) chars.write('abcdefghijklmnopqrstuvwxyz');
    if (_includeUppercase) chars.write('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    if (_includeNumbers) chars.write('0123456789');
    if (_includeSymbols) chars.write('!@#\$%^&*()_+-=[]{}|;:,.<>?');

    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = '';
        _strength = 0;
      });
      return;
    }

    final random = Random.secure();
    final password = List.generate(_length.toInt(), (_) {
      return chars.toString()[random.nextInt(chars.length)];
    }).join();

    setState(() {
      _generatedPassword = password;
      _strength = _calculateStrength(password);
      if (_history.isEmpty || _history.first != password) {
        _history.insert(0, password);
        if (_history.length > 10) _history.removeLast();
      }
    });
  }

  int _calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) score++;
    if (password.length >= 20) score++;
    return score.clamp(0, 5);
  }

  String _strengthLabel() {
    switch (_strength) {
      case 0: return 'None';
      case 1: return 'Very Weak';
      case 2: return 'Weak';
      case 3: return 'Fair';
      case 4: return 'Strong';
      case 5: return 'Very Strong';
      default: return '';
    }
  }

  Color _strengthColor() {
    switch (_strength) {
      case 1: return const Color(0xFFFF5252);
      case 2: return const Color(0xFFFF6D00);
      case 3: return const Color(0xFFFFD740);
      case 4: return const Color(0xFF00E676);
      case 5: return const Color(0xFF00BCD4);
      default: return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Password Generator',
          style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: GradientMeshBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
          children: [
            _buildPasswordDisplay(accent),
            const SizedBox(height: 20),
            _buildStrengthBar(accent),
            const SizedBox(height: 20),
            _buildOptions(accent),
            const SizedBox(height: 20),
            _buildGenerateButton(accent),
            const SizedBox(height: 20),
            _buildHistorySection(accent),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordDisplay(Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          SelectableText(
            _generatedPassword,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _copyButton(accent),
              const SizedBox(width: 16),
              _regenerateButton(accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _copyButton(Color accent) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: _generatedPassword));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password copied!', style: GoogleFonts.inter(fontSize: 13)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy, size: 16, color: accent),
            const SizedBox(width: 8),
            Text('Copy', style: GoogleFonts.inter(fontSize: 14, color: accent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _regenerateButton(Color accent) {
    return GestureDetector(
      onTap: _generatePassword,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: Colors.white60),
            const SizedBox(width: 8),
            Text('Regenerate', style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthBar(Color accent) {
    final color = _strengthColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'Strength: ${_strengthLabel()}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
              const Spacer(),
              Text(
                '${_strength * 20}%',
                style: GoogleFonts.inter(fontSize: 13, color: color.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strength / 5,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStrengthAdvice(),
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  String _getStrengthAdvice() {
    if (_strength <= 2) return 'Use a longer password with mixed character types.';
    if (_strength == 3) return 'Good. Add symbols or increase length for better security.';
    return 'Excellent! This password is very secure.';
  }

  Widget _buildOptions(Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Options', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildSlider(accent),
          const SizedBox(height: 12),
          _buildToggle('Uppercase (A-Z)', _includeUppercase, (v) => setState(() => _includeUppercase = v)),
          _buildToggle('Lowercase (a-z)', _includeLowercase, (v) => setState(() => _includeLowercase = v)),
          _buildToggle('Numbers (0-9)', _includeNumbers, (v) => setState(() => _includeNumbers = v)),
          _buildToggle('Symbols (!@#\$...)', _includeSymbols, (v) => setState(() => _includeSymbols = v)),
        ],
      ),
    );
  }

  Widget _buildSlider(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Length', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            Text(
              '${_length.toInt()}',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: accent),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            activeTrackColor: accent,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.1),
          ),
          child: Slider(
            value: _length,
            min: 6,
            max: 64,
            divisions: 58,
            onChanged: (v) => setState(() => _length = v),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value ? context.read<SettingsProvider>().accentColor.withOpacity(0.25) : Colors.white.withOpacity(0.08),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? context.read<SettingsProvider>().accentColor : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatePassword,
        icon: Icon(Icons.auto_awesome, size: 20, color: accent),
        label: Text('Generate New Password', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: accent)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent.withOpacity(0.1),
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: accent.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildHistorySection(Color accent) {
    if (_history.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Passwords', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._history.skip(1).take(5).map((pwd) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pwd,
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: pwd));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied!', style: GoogleFonts.inter(fontSize: 13)),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Icon(Icons.copy, size: 16, color: accent.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
