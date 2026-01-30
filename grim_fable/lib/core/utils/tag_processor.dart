import '../models/character.dart';
import '../services/ai_service.dart';
import '../../features/character/character_provider.dart';
import 'item_parser.dart';

class TagProcessor {
  static Future<String> processInventoryTags({
    required String response,
    required Character character,
    required CharacterNotifier characterNotifier,
    required AIService aiService,
  }) async {
    final gainedItems = ItemParser.parseGainedItems(response);
    final removedItems = ItemParser.parseRemovedItems(response);
    int goldDelta = GoldParser.parseGoldDelta(response);

    // Check for ambiguous gold
    if (goldDelta == 0 && GoldParser.isAmbiguous(response)) {
      goldDelta = await aiService.clarifyGoldAmount(response);
    }

    if (gainedItems.isEmpty && removedItems.isEmpty && goldDelta == 0) {
      return ItemParser.cleanText(response);
    }

    List<String> newInventory = List<String>.from(character.inventory);

    for (final item in gainedItems) {
      if (!newInventory.any((i) => i.toLowerCase() == item.toLowerCase())) {
        newInventory.add(item);
      }
    }

    for (final item in removedItems) {
      newInventory.removeWhere((i) => i.toLowerCase() == item.toLowerCase());
    }

    final updatedCharacter = character.copyWith(
      inventory: newInventory,
      gold: character.gold + goldDelta,
    );

    await characterNotifier.updateCharacter(updatedCharacter);

    return ItemParser.cleanText(response);
  }
}
