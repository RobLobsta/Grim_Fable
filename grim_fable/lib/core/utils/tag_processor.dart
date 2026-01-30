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
    Map<String, String> newItemDescriptions = Map<String, String>.from(character.itemDescriptions);
    bool changedDescriptions = false;

    for (String item in gainedItems) {
      String itemName = item;
      if (item.toUpperCase().startsWith('REPLACED:')) {
        final parsed = await aiService.parseReplacedItem(item);
        itemName = parsed.name;
        newItemDescriptions[itemName] = parsed.explanation;
        changedDescriptions = true;
      }

      if (!newInventory.any((i) => i.toLowerCase() == itemName.toLowerCase())) {
        newInventory.add(itemName);
      }
    }

    for (final item in removedItems) {
      newInventory.removeWhere((i) => i.toLowerCase() == item.toLowerCase());
    }

    final updatedCharacter = character.copyWith(
      inventory: newInventory,
      gold: character.gold + goldDelta,
      itemDescriptions: changedDescriptions ? newItemDescriptions : null,
    );

    await characterNotifier.updateCharacter(updatedCharacter);

    return ItemParser.cleanText(response);
  }
}
