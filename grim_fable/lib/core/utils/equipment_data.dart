import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EquipmentData {
  static const Map<String, List<String>> _occupationEquipment = {
    'warrior': ['Iron Sword', 'Leather Armor', 'Small Shield'],
    'fighter': ['Iron Sword', 'Leather Armor', 'Small Shield'],
    'soldier': ['Spear', 'Gambeson', 'Round Shield'],
    'mercenary': ['Greatsword', 'Worn Chainmail'],
    'knight': ['Longsword', 'Plate Gauntlets', 'Heater Shield'],
    'barbarian': ['Rusty Axe', 'Fur Wraps', 'Bone Amulet'],
    'berserker': ['Rusty Axe', 'Fur Wraps', 'Bone Amulet'],
    'thief': ['Steel Dagger', 'Dark Cloak', 'Lockpicks'],
    'rogue': ['Steel Dagger', 'Dark Cloak', 'Lockpicks'],
    'assassin': ['Poisoned Dagger', 'Black Hood'],
    'archer': ['Shortbow', 'Quiver of Arrows', 'Leather Bracers'],
    'ranger': ['Shortbow', 'Quiver of Arrows', 'Leather Bracers'],
    'hunter': ['Hunting Bow', 'Skinning Knife'],
    'mage': ['Oak Staff', 'Apprentice Robes', 'Mana Potion'],
    'wizard': ['Oak Staff', 'Apprentice Robes', 'Mana Potion'],
    'sorcerer': ['Crystal Focus', 'Silk Robes'],
    'warlock': ['Ancient Grimoire', 'Obsidian Ring'],
    'necromancer': ['Skull Staff', 'Tattered Shroud'],
    'cleric': ['Mace', 'Holy Symbol', 'Bandages'],
    'priest': ['Mace', 'Holy Symbol', 'Bandages'],
    'paladin': ['Warhammer', 'Silver Censer'],
    'druid': ['Sickle', 'Herbs', 'Wooden Totem'],
    'alchemist': ['Glass Flasks', 'Strange Powders', 'Mortar and Pestle'],
    'blacksmith': ['Iron Hammer', 'Heavy Apron', 'Tongs'],
    'merchant': ['Bag of Coins', 'Ledger', 'Fine Clothes'],
    'bard': ['Lute', 'Colorful Tunic', 'Quill and Ink'],
    'farmer': ['Pitchfork', 'Straw Hat', 'Coarse Bread'],
    'miner': ['Pickaxe', 'Lantern', 'Iron Ore'],
    'herbalist': ['Gathering Sickle', 'Dried Herbs', 'Pouch of Seeds'],
    'scholar': ['Ancient Scroll', 'Magnifying Glass', 'Inkwell'],
    'chef': ['Cleaver', 'Salt Pouch', 'Iron Pot'],
    'cook': ['Cleaver', 'Salt Pouch', 'Iron Pot'],
  };

  static List<String> getStartingEquipment(String occupation) {
    final lowerOccupation = occupation.toLowerCase();

    for (final entry in _occupationEquipment.entries) {
      if (lowerOccupation.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default equipment if no occupation match
    return ['Crude Dagger', 'Worn Clothes', 'Dry Rations'];
  }

  static IconData? getIconForItem(String itemName) {
    final lowerItem = itemName.toLowerCase();

    // Weaponry
    if (lowerItem.contains('sword')) return FontAwesomeIcons.khanda; // Free alternative
    if (lowerItem.contains('dagger') || lowerItem.contains('knife')) return null; // Fallback to emoji
    if (lowerItem.contains('axe')) return null; // Fallback to emoji
    if (lowerItem.contains('hammer') || lowerItem.contains('mace') || lowerItem.contains('warhammer')) return FontAwesomeIcons.hammer;
    if (lowerItem.contains('bow')) return FontAwesomeIcons.bullseye; // Free alternative
    if (lowerItem.contains('spear')) return FontAwesomeIcons.locationArrow; // Fallback
    if (lowerItem.contains('staff') || lowerItem.contains('wand')) return FontAwesomeIcons.wandMagicSparkles; // Check if free
    if (lowerItem.contains('shield')) return FontAwesomeIcons.shieldHalved;

    // Armor & Clothing
    if (lowerItem.contains('armor') || lowerItem.contains('chainmail') || lowerItem.contains('plate')) return FontAwesomeIcons.vest;
    if (lowerItem.contains('cloak') || lowerItem.contains('robe') || lowerItem.contains('hood') || lowerItem.contains('tunic') || lowerItem.contains('shroud') || lowerItem.contains('clothes') || lowerItem.contains('wraps') || lowerItem.contains('apron')) return FontAwesomeIcons.shirt;
    if (lowerItem.contains('helmet') || lowerItem.contains('hat') || lowerItem.contains('cap')) return FontAwesomeIcons.helmetSafety; // Free
    if (lowerItem.contains('boots') || lowerItem.contains('shoes')) return FontAwesomeIcons.shoePrints;
    if (lowerItem.contains('gloves') || lowerItem.contains('bracers') || lowerItem.contains('gauntlets')) return FontAwesomeIcons.mitten;

    // Tools & Utilities
    if (lowerItem.contains('potion') || lowerItem.contains('flask') || lowerItem.contains('vial')) return FontAwesomeIcons.flask;
    if (lowerItem.contains('herb') || lowerItem.contains('seed') || lowerItem.contains('powder')) return FontAwesomeIcons.leaf;
    if (lowerItem.contains('scroll') || lowerItem.contains('grimoire') || lowerItem.contains('book') || lowerItem.contains('ledger')) return FontAwesomeIcons.book;
    if (lowerItem.contains('map')) return FontAwesomeIcons.map;
    if (lowerItem.contains('key') || lowerItem.contains('lockpick')) return FontAwesomeIcons.key;
    if (lowerItem.contains('torch') || lowerItem.contains('lantern') || lowerItem.contains('candle')) return FontAwesomeIcons.fire;
    if (lowerItem.contains('rope')) return FontAwesomeIcons.bezierCurve; // Fallback
    if (lowerItem.contains('bag') || lowerItem.contains('pouch') || lowerItem.contains('sack') || lowerItem.contains('quiver') || lowerItem.contains('satchel')) return FontAwesomeIcons.bagShopping;

    // Food & Drink
    if (lowerItem.contains('bread') || lowerItem.contains('apple') || lowerItem.contains('rations') || lowerItem.contains('meat') || lowerItem.contains('pot')) return FontAwesomeIcons.utensils;
    if (lowerItem.contains('wine') || lowerItem.contains('ale') || lowerItem.contains('water') || lowerItem.contains('cup') || lowerItem.contains('mug')) return FontAwesomeIcons.glassWater;

    // Miscellaneous
    if (lowerItem.contains('gold') || lowerItem.contains('coin')) return FontAwesomeIcons.coins;
    if (lowerItem.contains('gem') || lowerItem.contains('jewel') || lowerItem.contains('ring') || lowerItem.contains('amulet') || lowerItem.contains('necklace')) return FontAwesomeIcons.gem;
    if (lowerItem.contains('skull') || lowerItem.contains('bone')) return FontAwesomeIcons.skull;
    if (lowerItem.contains('compass')) return FontAwesomeIcons.compass;
    if (lowerItem.contains('ink') || lowerItem.contains('quill')) return FontAwesomeIcons.penNib;

    return null;
  }

  static String? getEmojiForItem(String itemName) {
    final lowerItem = itemName.toLowerCase();

    if (lowerItem.contains('sword')) return '🗡️';
    if (lowerItem.contains('dagger') || lowerItem.contains('knife')) return '🔪';
    if (lowerItem.contains('axe')) return '🪓';
    if (lowerItem.contains('hammer') || lowerItem.contains('mace')) return '🔨';
    if (lowerItem.contains('bow')) return '🏹';
    if (lowerItem.contains('staff') || lowerItem.contains('wand')) return '🪄';
    if (lowerItem.contains('shield')) return '🛡️';
    if (lowerItem.contains('armor')) return '🛡️';
    if (lowerItem.contains('helmet')) return '🪖';
    if (lowerItem.contains('potion') || lowerItem.contains('flask')) return '🧪';
    if (lowerItem.contains('herb')) return '🌿';
    if (lowerItem.contains('scroll') || lowerItem.contains('book')) return '📜';
    if (lowerItem.contains('map')) return '🗺️';
    if (lowerItem.contains('key') || lowerItem.contains('lockpick')) return '🔑';
    if (lowerItem.contains('torch') || lowerItem.contains('lantern')) return '🔦';
    if (lowerItem.contains('bag') || lowerItem.contains('pouch') || lowerItem.contains('satchel')) return '💰';
    if (lowerItem.contains('bread') || lowerItem.contains('rations')) return '🍞';
    if (lowerItem.contains('gold') || lowerItem.contains('coin')) return '🪙';
    if (lowerItem.contains('gem') || lowerItem.contains('ring')) return '💎';
    if (lowerItem.contains('skull') || lowerItem.contains('bone')) return '💀';

    return null;
  }
}
