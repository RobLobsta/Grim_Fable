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
    return text.replaceAll(_gainedTagRegex, '').replaceAll(_removedTagRegex, '').trim();
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
