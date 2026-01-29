class ItemParser {
  static final RegExp _gainedTagRegex = RegExp(r'\[ITEM_GAINED:\s*([^\]]+)\]', caseSensitive: false);
  static final RegExp _removedTagRegex = RegExp(r'\[ITEM_REMOVED:\s*([^\]]+)\]', caseSensitive: false);

  // Common natural language patterns for gaining items
  static final List<RegExp> _gainedPatterns = [
    RegExp(r'(?:find|obtain|receive|get|acquire|pick up|take|pocket|stow|gain)\s+(?:a|an|the|some)?\s+([^.,!?;:]+)', caseSensitive: false),
    RegExp(r'([^.,!?;:]+)\s+(?:is|has been)\s+(?:added to|placed in)\s+your\s+(?:inventory|pack|bag|pockets)', caseSensitive: false),
    RegExp(r'You\s+now\s+have\s+(?:a|an|the|some)?\s+([^.,!?;:]+)', caseSensitive: false),
  ];

  // Common natural language patterns for losing items
  static final List<RegExp> _lostPatterns = [
    RegExp(r'(?:lose|drop|give away|sell|misplace|break|destroy|discard|hand over)\s+(?:a|an|the|some)?\s+([^.,!?;:]+)', caseSensitive: false),
    RegExp(r'([^.,!?;:]+)\s+(?:is|has been)\s+(?:removed from|taken from|lost from)\s+your\s+(?:inventory|pack|bag|pockets)', caseSensitive: false),
  ];

  static List<String> parseGainedItems(String text) {
    Set<String> items = {};

    // Tag matches
    for (final match in _gainedTagRegex.allMatches(text)) {
      items.add(match.group(1)!.trim());
    }

    // Natural language matches
    for (final pattern in _gainedPatterns) {
      for (final match in pattern.allMatches(text)) {
        final item = match.group(1)!.trim();
        if (_isProbablyAnItem(item)) {
          items.add(item);
        }
      }
    }

    return items.toList();
  }

  static List<String> parseRemovedItems(String text) {
     Set<String> items = {};

    // Tag matches
    for (final match in _removedTagRegex.allMatches(text)) {
      items.add(match.group(1)!.trim());
    }

    // Natural language matches
    for (final pattern in _lostPatterns) {
      for (final match in pattern.allMatches(text)) {
        final item = match.group(1)!.trim();
        if (_isProbablyAnItem(item)) {
          items.add(item);
        }
      }
    }

    return items.toList();
  }

  static String cleanText(String text) {
    String cleaned = text.replaceAll(_gainedTagRegex, '').replaceAll(_removedTagRegex, '');
    cleaned = cleaned.replaceAll(GoldParser._goldTagRegex, '');
    cleaned = cleaned.replaceAll(GoldParser._goldGainedTagRegex, '');
    cleaned = cleaned.replaceAll(GoldParser._goldRemovedTagRegex, '');
    return cleaned.trim();
  }

  static bool _isProbablyAnItem(String text) {
    if (text.isEmpty) return false;

    // Simple heuristics to filter out non-items
    final lower = text.toLowerCase();

    // Common abstract nouns or phrases that are NOT items
    final nonItems = {
      'hope', 'way', 'mind', 'courage', 'strength', 'sight', 'consciousness',
      'balance', 'patience', 'time', 'faith', 'will',
      'perspective', 'control', 'footing', 'cool', 'breath', 'sense', 'lead'
    };

    if (nonItems.contains(lower)) return false;

    // Filter out gold/coins that should be currency
    if (lower.contains('gold') || lower.contains('coin')) {
      // If it's just "gold", "coins", or "[number] gold/coins", it's currency
      if (RegExp(r'^(\d+\s+)?(gold|coins?|gold\s+coins?)$').hasMatch(lower)) {
        return false;
      }
    }

    // Avoid verbs or complex phrases starting with common prepositions/conjunctions
    if (lower.startsWith('that ') || lower.startsWith('how ') || lower.startsWith('to ') || lower.startsWith('why ')) return false;

    // Items are usually short
    if (text.length > 40) return false;

    final words = text.split(RegExp(r'\s+'));
    if (words.length > 5) return false;

    // If it contains "that" or "which", it's likely a clause
    if (lower.contains(' that ') || lower.contains(' which ')) return false;

    return true;
  }
}

class GoldParser {
  static final RegExp _goldTagRegex = RegExp(r'\[GOLD:\s*(-?\d+)\]', caseSensitive: false);
  static final RegExp _goldGainedTagRegex = RegExp(r'\[GOLD_GAINED:\s*(\d+)\]', caseSensitive: false);
  static final RegExp _goldRemovedTagRegex = RegExp(r'\[GOLD_REMOVED:\s*(\d+)\]', caseSensitive: false);

  // NLP Patterns
  static final RegExp _goldGainedPattern = RegExp(r'(?:find|receive|get|acquire|gain|pocket|collect|pick up)\s+(?:a|an|the|some)?\s*(\d+)\s+(?:gold|coins?|pieces? of gold)', caseSensitive: false);
  static final RegExp _goldLostPattern = RegExp(r'(?:lose|drop|give|pay|spend|discard)\s+(?:a|an|the|some)?\s*(\d+)\s+(?:gold|coins?|pieces? of gold)', caseSensitive: false);

  // Ambiguous patterns (no number)
  static final RegExp _ambiguousGoldPattern = RegExp(r'(?:the|some|those|thy|thy|all the)\s+(?:gold|coins?|pieces? of gold)', caseSensitive: false);
  // Simple mentions like "pick up the gold"
  static final RegExp _simpleGoldMention = RegExp(r'\b(?:gold|coins)\b', caseSensitive: false);

  static int parseGoldDelta(String text) {
    int delta = 0;

    // 1. Check [GOLD: X] - this usually sets the absolute value or is used as a delta in some contexts
    // For our purposes, we'll treat [GOLD: X] as an absolute setter if X is positive and no other delta is found,
    // OR as a delta if it's explicitly gained/removed.
    // Actually, let's treat [GOLD: X] as "total starting gold" in backstory, and [GOLD_GAINED/REMOVED] for delta.

    // In adventure, we mostly care about deltas.
    for (final match in _goldGainedTagRegex.allMatches(text)) {
      delta += int.tryParse(match.group(1)!) ?? 0;
    }
    for (final match in _goldRemovedTagRegex.allMatches(text)) {
      delta -= int.tryParse(match.group(1)!) ?? 0;
    }

    // If no tags, try NLP
    if (delta == 0) {
      for (final match in _goldGainedPattern.allMatches(text)) {
        delta += int.tryParse(match.group(1)!) ?? 0;
      }
      for (final match in _goldLostPattern.allMatches(text)) {
        delta -= int.tryParse(match.group(1)!) ?? 0;
      }
    }

    return delta;
  }

  /// Used specifically for backstory generation where [GOLD: X] sets the initial amount.
  static int parseInitialGold(String text) {
    final match = _goldTagRegex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    // Fallback to NLP if no tag
    for (final match in _goldGainedPattern.allMatches(text)) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  static bool isAmbiguous(String text) {
    // If we already found a specific delta, it's not ambiguous (or at least we have a number)
    if (parseGoldDelta(text) != 0) return false;

    // Check if gold/coins mentioned with ambiguous quantifiers
    if (_ambiguousGoldPattern.hasMatch(text)) return true;

    // Check if gold/coins mentioned at all without a number nearby
    if (_simpleGoldMention.hasMatch(text)) {
      // If there's a number followed by gold/coins, it's NOT ambiguous (should have been caught by parseGoldDelta)
      // Since parseGoldDelta returned 0, any mention of gold/coins here is likely ambiguous
      return true;
    }

    return false;
  }
}
