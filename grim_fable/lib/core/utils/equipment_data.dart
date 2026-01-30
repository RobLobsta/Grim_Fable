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
    if (lowerItem.contains('sword') || lowerItem.contains('scimitar') || lowerItem.contains('cutlass') || lowerItem.contains('rapier')) return FontAwesomeIcons.khanda;
    if (lowerItem.contains('dagger') || lowerItem.contains('knife') || lowerItem.contains('blade') || lowerItem.contains('dirk')) return null; // Fallback to emoji
    if (lowerItem.contains('axe') || lowerItem.contains('hatchet')) return null; // Fallback to emoji
    if (lowerItem.contains('hammer') || lowerItem.contains('mace') || lowerItem.contains('warhammer') || lowerItem.contains('club') || lowerItem.contains('morning star')) return FontAwesomeIcons.hammer;
    if (lowerItem.contains('bow')) return FontAwesomeIcons.bullseye;
    if (lowerItem.contains('arrow') || lowerItem.contains('quiver') || lowerItem.contains('bolt')) return FontAwesomeIcons.locationArrow;
    if (lowerItem.contains('spear') || lowerItem.contains('javelin') || lowerItem.contains('halberd')) return FontAwesomeIcons.locationArrow;
    if (lowerItem.contains('staff') || lowerItem.contains('wand') || lowerItem.contains('rod')) return FontAwesomeIcons.wandMagicSparkles;
    if (lowerItem.contains('shield')) return FontAwesomeIcons.shieldHalved;

    // Armor & Clothing
    if (lowerItem.contains('armor') || lowerItem.contains('chainmail') || lowerItem.contains('plate') || lowerItem.contains('gambeson')) return FontAwesomeIcons.vest;
    if (lowerItem.contains('cloak') || lowerItem.contains('robe') || lowerItem.contains('hood') || lowerItem.contains('tunic') || lowerItem.contains('shroud') || lowerItem.contains('clothes') || lowerItem.contains('wraps') || lowerItem.contains('apron') || lowerItem.contains('cape') || lowerItem.contains('tabard')) return FontAwesomeIcons.shirt;
    if (lowerItem.contains('helmet') || lowerItem.contains('hat') || lowerItem.contains('cap') || lowerItem.contains('cowl')) return FontAwesomeIcons.helmetSafety;
    if (lowerItem.contains('boots') || lowerItem.contains('shoes') || lowerItem.contains('sandals')) return FontAwesomeIcons.shoePrints;
    if (lowerItem.contains('gloves') || lowerItem.contains('bracers') || lowerItem.contains('gauntlets')) return FontAwesomeIcons.mitten;

    // Tools & Utilities
    if (lowerItem.contains('potion') || lowerItem.contains('flask') || lowerItem.contains('vial') || lowerItem.contains('elixir') || lowerItem.contains('tonic')) return FontAwesomeIcons.flask;
    if (lowerItem.contains('herb') || lowerItem.contains('seed') || lowerItem.contains('powder') || lowerItem.contains('flower') || lowerItem.contains('moss') || lowerItem.contains('leaf') || lowerItem.contains('sickle')) return FontAwesomeIcons.leaf;
    if (lowerItem.contains('scroll') || lowerItem.contains('grimoire') || lowerItem.contains('book') || lowerItem.contains('ledger') || lowerItem.contains('journal') || lowerItem.contains('tome') || lowerItem.contains('parchment')) return FontAwesomeIcons.book;
    if (lowerItem.contains('map') || lowerItem.contains('chart')) return FontAwesomeIcons.map;
    if (lowerItem.contains('key') || lowerItem.contains('lockpick') || lowerItem.contains('pick')) return FontAwesomeIcons.key;
    if (lowerItem.contains('torch') || lowerItem.contains('lantern') || lowerItem.contains('candle') || lowerItem.contains('lamp')) return FontAwesomeIcons.fire;
    if (lowerItem.contains('rope') || lowerItem.contains('chain')) return FontAwesomeIcons.bezierCurve;
    if (lowerItem.contains('bag') || lowerItem.contains('pouch') || lowerItem.contains('sack') || lowerItem.contains('satchel') || lowerItem.contains('backpack') || lowerItem.contains('pack')) return FontAwesomeIcons.bagShopping;
    if (lowerItem.contains('mortar') || lowerItem.contains('pestle')) return FontAwesomeIcons.mortarPestle;
    if (lowerItem.contains('bandage') || lowerItem.contains('dressing') || lowerItem.contains('suture') || lowerItem.contains('salve')) return FontAwesomeIcons.bandAid;
    if (lowerItem.contains('trap')) return FontAwesomeIcons.toolbox;
    if (lowerItem.contains('censer') || lowerItem.contains('incense') || lowerItem.contains('relic') || lowerItem.contains('holy symbol') || lowerItem.contains('totem') || lowerItem.contains('idol')) return FontAwesomeIcons.cross;

    // Food & Drink
    if (lowerItem.contains('bread') || lowerItem.contains('apple') || lowerItem.contains('rations') || lowerItem.contains('meat') || lowerItem.contains('pot') || lowerItem.contains('food') || lowerItem.contains('berry') || lowerItem.contains('jerky')) return FontAwesomeIcons.utensils;
    if (lowerItem.contains('wine') || lowerItem.contains('ale') || lowerItem.contains('water') || lowerItem.contains('cup') || lowerItem.contains('mug') || lowerItem.contains('skin')) return FontAwesomeIcons.glassWater;

    // Miscellaneous
    if (lowerItem.contains('gold') || lowerItem.contains('coin') || lowerItem.contains('silver') || lowerItem.contains('copper')) return FontAwesomeIcons.coins;
    if (lowerItem.contains('gem') || lowerItem.contains('jewel') || lowerItem.contains('ring') || lowerItem.contains('amulet') || lowerItem.contains('necklace') || lowerItem.contains('crystal') || lowerItem.contains('pendant')) return FontAwesomeIcons.gem;
    if (lowerItem.contains('skull') || lowerItem.contains('bone')) return FontAwesomeIcons.skull;
    if (lowerItem.contains('compass')) return FontAwesomeIcons.compass;
    if (lowerItem.contains('ink') || lowerItem.contains('quill') || lowerItem.contains('pen')) return FontAwesomeIcons.penNib;
    if (lowerItem.contains('token') || lowerItem.contains('charm') || lowerItem.contains('sigil')) return FontAwesomeIcons.certificate;
    if (lowerItem.contains('instrument') || lowerItem.contains('lute') || lowerItem.contains('flute') || lowerItem.contains('harp') || lowerItem.contains('drum')) return FontAwesomeIcons.music;

    return null;
  }

  static String? getEmojiForItem(String itemName) {
    final lowerItem = itemName.toLowerCase();

    if (lowerItem.contains('sword') || lowerItem.contains('scimitar') || lowerItem.contains('cutlass')) return '🗡️';
    if (lowerItem.contains('dagger') || lowerItem.contains('knife') || lowerItem.contains('blade')) return '🔪';
    if (lowerItem.contains('axe') || lowerItem.contains('hatchet')) return '🪓';
    if (lowerItem.contains('hammer') || lowerItem.contains('mace') || lowerItem.contains('warhammer') || lowerItem.contains('club')) return '🔨';
    if (lowerItem.contains('bow')) return '🏹';
    if (lowerItem.contains('staff') || lowerItem.contains('wand')) return '🪄';
    if (lowerItem.contains('shield')) return '🛡️';
    if (lowerItem.contains('armor') || lowerItem.contains('plate') || lowerItem.contains('chainmail')) return '🛡️';
    if (lowerItem.contains('helmet') || lowerItem.contains('hat')) return '🪖';
    if (lowerItem.contains('potion') || lowerItem.contains('flask') || lowerItem.contains('vial')) return '🧪';
    if (lowerItem.contains('herb') || lowerItem.contains('flower') || lowerItem.contains('leaf') || lowerItem.contains('moss')) return '🌿';
    if (lowerItem.contains('scroll') || lowerItem.contains('book') || lowerItem.contains('journal') || lowerItem.contains('ledger') || lowerItem.contains('tome')) return '📜';
    if (lowerItem.contains('map') || lowerItem.contains('chart')) return '🗺️';
    if (lowerItem.contains('key') || lowerItem.contains('lockpick')) return '🔑';
    if (lowerItem.contains('torch') || lowerItem.contains('lantern') || lowerItem.contains('candle')) return '🕯️';
    if (lowerItem.contains('bag') || lowerItem.contains('pouch') || lowerItem.contains('satchel') || lowerItem.contains('backpack')) return '🎒';
    if (lowerItem.contains('bread') || lowerItem.contains('rations') || lowerItem.contains('meat') || lowerItem.contains('food')) return '🍞';
    if (lowerItem.contains('gold') || lowerItem.contains('coin') || lowerItem.contains('silver')) return '🪙';
    if (lowerItem.contains('gem') || lowerItem.contains('ring') || lowerItem.contains('crystal') || lowerItem.contains('amulet')) return '💎';
    if (lowerItem.contains('skull') || lowerItem.contains('bone')) return '💀';
    if (lowerItem.contains('bandage') || lowerItem.contains('dressing') || lowerItem.contains('suture')) return '🩹';
    if (lowerItem.contains('instrument') || lowerItem.contains('lute') || lowerItem.contains('flute') || lowerItem.contains('harp')) return '🪕';
    if (lowerItem.contains('holy') || lowerItem.contains('ritual') || lowerItem.contains('censer')) return '✨';
    if (lowerItem.contains('trap')) return '🪤';
    if (lowerItem.contains('sickle')) return '🌙';

    return null;
  }
}
