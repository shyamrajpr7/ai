import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/daily_quote.dart';
import '../providers/quote_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gradient_mesh_background.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  static const _categories = [
    'motivation', 'wisdom', 'creativity', 'life',
    'love', 'courage', 'peace', 'humor',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Daily Quotes',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add_circle_outline, color: accent),
            onSelected: (cat) {
              HapticFeedback.lightImpact();
              context.read<QuoteProvider>().generateQuote(category: cat);
            },
            itemBuilder: (ctx) => _categories.map((cat) {
              return PopupMenuItem(
                value: cat,
                child: Text(cat[0].toUpperCase() + cat.substring(1)),
              );
            }).toList(),
            color: const Color(0xFF1A1A2E),
          ),
        ],
      ),
      body: GradientMeshBackground(
        child: Consumer<QuoteProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                const SizedBox(height: 100),
                _buildTodayQuote(provider, accent),
                const SizedBox(height: 16),
                _buildCategoryFilter(provider, accent),
                Expanded(
                  child: provider.filteredQuotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_quote, size: 64, color: accent.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No quotes yet',
                                style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to generate your first quote',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white30),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: provider.filteredQuotes.length,
                          itemBuilder: (context, index) {
                            return _buildQuoteCard(provider.filteredQuotes[index], accent);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodayQuote(QuoteProvider provider, Color accent) {
    final today = provider.todayQuote;
    if (today == null && !provider.isGenerating) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            provider.generateQuote();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: accent, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Today\'s Quote',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get an AI-generated inspirational quote',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.isGenerating) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
              const SizedBox(width: 16),
              Text(
                'Generating quote...',
                style: GoogleFonts.inter(fontSize: 15, color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.12), accent.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, color: accent.withOpacity(0.5), size: 32),
            const SizedBox(height: 12),
            Text(
              today!.text,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u2014 ${today.author}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: accent.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(QuoteProvider provider, Color accent) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _catChip('All', provider.selectedCategory == 'all', accent, () => provider.setCategory('all')),
          ...provider.allCategories.map((cat) {
            return _catChip(cat, provider.selectedCategory == cat, accent, () => provider.setCategory(cat));
          }),
        ],
      ),
    );
  }

  Widget _catChip(String label, bool selected, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: selected ? accent : Colors.white60,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(DailyQuote quote, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  quote.category,
                  style: GoogleFonts.inter(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<QuoteProvider>().toggleFavorite(quote.id);
                },
                child: Icon(
                  quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: quote.isFavorite ? Colors.redAccent : Colors.white38,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '"${quote.text}" — ${quote.author}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quote copied!', style: GoogleFonts.inter(fontSize: 13)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Icon(Icons.copy, size: 18, color: Colors.white38),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _confirmDelete(context, quote),
                child: Icon(Icons.delete_outline, size: 18, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quote.text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\u2014 ${quote.author}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DailyQuote quote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quote?'),
        content: Text(
          'This will permanently delete this quote.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              context.read<QuoteProvider>().deleteQuote(quote.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
