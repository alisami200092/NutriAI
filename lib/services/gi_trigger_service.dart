import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

/// Service for detecting clinical gastrointestinal (GI) triggers
/// and deterministically filtering candidate meals for the Gut Shield pipeline.
class GiTriggerService {
  static const List<String> allTriggerTypes = [
    "spicy",
    "acidic",
    "dairy",
    "high_fodmap",
    "deep_fried",
    "caffeine",
    "carbonated",
    "artificial_sweeteners",
    "gluten",
    "heavy_oil",
    "heavy_fat",
    "dry_refined",
    "insoluble_roughage",
  ];

  static final Map<String, List<String>> _triggerKeywords = {
    "spicy": [
      'spicy',
      'chili',
      'chilli',
      'mirch',
      'jalapeno',
      'curry',
      'masala',
      'karahi',
      'nihari',
      'tikka',
      'jalfrezi',
      'achar',
      'pickled',
      'pepper',
      'hot sauce',
      'tabasco',
      'wasabi',
      'cayenne',
      'paprika',
      'kebab',
      'kabab',
      'salan',
      'spiced',
      'chaat',
    ],
    "acidic": [
      'citrus',
      'lemon',
      'lime',
      'orange',
      'grapefruit',
      'tomato',
      'vinegar',
      'ketchup',
      'pineapple',
      'marinara',
      'salsa',
      'tamatar',
      'rasam',
      'sambar',
      'sambhar',
      'tamarind',
      'imli',
    ],
    "dairy": [
      'milk',
      'cheese',
      'yogurt',
      'curd',
      'dahi',
      'raita',
      'paneer',
      'butter',
      'makhan',
      'ghee',
      'cream',
      'malai',
      'lassi',
      'kheer',
      'custard',
      'ice cream',
      'whey',
      'parmesan',
      'mozzarella',
      'cheddar',
      'doodh',
    ],
    "high_fodmap": [
      'garlic',
      'onion',
      'leek',
      'shallot',
      'daal',
      'dal',
      'lentil',
      'chana',
      'chickpea',
      'beans',
      'rajma',
      'cabbage',
      'cauliflower',
      'broccoli',
      'mushroom',
      'apple',
      'pear',
      'watermelon',
      'lahsun',
      'piyaz',
    ],
    "deep_fried": [
      'fried',
      'deep fried',
      'deep-fried',
      'samosa',
      'pakora',
      'poori',
      'puri',
      'roll',
      'tempura',
      'fries',
      'chips',
      'crispy',
      'battered',
      'halwa puri',
      'tala hua',
    ],
    "caffeine": [
      'coffee',
      'espresso',
      'cappuccino',
      'latte',
      'caffeine',
      'energy drink',
      'red bull',
      'monster',
      'dark chocolate',
      'cocoa',
      'green tea',
      'black tea',
      'chai',
      'matcha',
      'pre-workout',
    ],
    "carbonated": [
      'soda',
      'cola',
      'pepsi',
      'coke',
      'sprite',
      'fanta',
      '7up',
      'carbonated',
      'sparkling water',
      'seltzer',
      'fizzy',
      'tonic',
      'beer',
      'club soda',
    ],
    "artificial_sweeteners": [
      'diet',
      'zero sugar',
      'sugar-free',
      'sugar free',
      'aspartame',
      'sucralose',
      'stevia',
      'erythritol',
      'sorbitol',
      'xylitol',
      'sweetner',
      'sweetener',
      'saccharin',
      'monk fruit',
    ],
    "gluten": [
      'wheat',
      'maida',
      'atta',
      'roti',
      'naan',
      'bread',
      'bun',
      'toast',
      'pasta',
      'noodle',
      'spaghetti',
      'macaroni',
      'pizza',
      'paratha',
      'pastry',
      'cake',
      'biscuit',
      'barley',
      'rye',
      'semolina',
      'sooji',
    ],
    "heavy_oil": [
      'heavy oil',
      'extra oil',
      'oily',
      'greasy',
      'tala hua',
      'fried',
      'deep fried',
      'deep-fried',
      'pakora',
      'samosa',
      'poori',
      'puri',
      'halwa puri',
      'bhature',
      'bhatura',
      'crispy skin',
    ],
    "heavy_fat": [
      'heavy fat',
      'high fat',
      'fatty',
      'butter',
      'makhan',
      'ghee',
      'cream',
      'malai',
      'mayo',
      'mayonnaise',
      'nihari',
      'paye',
      'mutton fat',
      'beef fat',
      'lard',
      'creamy',
    ],
    "dry_refined": [
      'dry refined',
      'refined flour',
      'maida',
      'white bread',
      'bakery',
      'biscuit',
      'cookies',
      'rusk',
      'dry toast',
      'cracker',
      'pastry',
      'cake',
      'croissant',
    ],
    "insoluble_roughage": [
      'roughage',
      'raw salad',
      'salad',
      'kachumber',
      'raw cabbage',
      'cabbage',
      'raw cauliflower',
      'corn',
      'popcorn',
      'seeds',
      'raw kale',
      'bran',
      'coarse',
    ],
  };

  /// Explicit clinical GI triggers mapped from the 5 companion CSV catalogs
  static final Map<String, List<String>> _explicitDishTriggers = {};
  static bool _tagsLoaded = false;

  /// Loads all 5 companion dish GI tag CSVs from assets into memory
  static Future<void> loadDishTags() async {
    if (_tagsLoaded) return;
    const tagFiles = [
      'assets/pakistani_dish_gi_tags.csv',
      'assets/indian_dish_gi_tags.csv',
      'assets/keto_dish_gi_tags.csv',
      'assets/mediterranean_dish_gi_tags.csv',
      'assets/dash_dish_gi_tags.csv',
    ];

    for (final path in tagFiles) {
      try {
        final raw = await rootBundle.loadString(path);
        final rows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(raw.replaceAll('\r\n', '\n'));

        if (rows.length > 1) {
          final header = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
          final nameIdx = header.indexOf('meal_name');
          final tagIdx = header.indexOf('gi_triggers');

          if (nameIdx != -1 && tagIdx != -1) {
            for (int i = 1; i < rows.length; i++) {
              final row = rows[i];
              if (row.length > nameIdx && row.length > tagIdx) {
                final name = row[nameIdx].toString().trim().toLowerCase();
                final tagStr = row[tagIdx].toString().trim().toLowerCase();
                if (tagStr.isNotEmpty && tagStr != 'safe') {
                  final splitTags = tagStr
                      .split(';')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  _explicitDishTriggers[name] = splitTags;
                } else {
                  _explicitDishTriggers[name] = [];
                }
              }
            }
          }
        }
      } catch (_) {}
    }
    _tagsLoaded = true;
  }

  /// Returns active GI triggers detected in a dish's title or description.
  static List<String> classifyFood(
    String foodName, {
    List<String>? ingredients,
  }) {
    final lowerName = foodName.toLowerCase().trim();

    // Fast-path: Check explicit clinical tags catalog if no custom ingredients given
    if (ingredients == null && _explicitDishTriggers.containsKey(lowerName)) {
      return List<String>.from(_explicitDishTriggers[lowerName]!);
    }

    final Set<String> triggersFound = {};

    bool isExcluded(String text, String kw) {
      if (kw == 'makhan' && text.contains('makhana')) return true;
      if (kw == 'roll' && (text.contains('rolled oats') || text.contains('oat'))) return true;
      if ((kw == 'seeds' || kw == 'seed') && (text.contains('chia') || text.contains('flax'))) return true;
      if (kw == 'pepper' && (text.contains('bell pepper') || text.contains('sweet pepper'))) return true;
      return false;
    }

    _triggerKeywords.forEach((trigger, keywords) {
      for (final kw in keywords) {
        if (isExcluded(lowerName, kw)) continue;
        if (lowerName.contains(kw)) {
          triggersFound.add(trigger);
          break;
        }
      }
    });

    if (ingredients != null) {
      for (final ing in ingredients) {
        final lowerIng = ing.toLowerCase();
        _triggerKeywords.forEach((trigger, keywords) {
          for (final kw in keywords) {
            if (isExcluded(lowerIng, kw)) continue;
            if (lowerIng.contains(kw)) {
              triggersFound.add(trigger);
              break;
            }
          }
        });
      }
    }

    return triggersFound.toList();
  }

  /// Deterministic gate: returns true if the food is free of any active GI triggers.
  static bool isFoodSafe(
    String foodName,
    List<String> activeTriggers, {
    List<String>? explicitTriggers,
  }) {
    if (activeTriggers.isEmpty) return true;
    final cleanName = foodName.toLowerCase().trim();
    final triggers = explicitTriggers ??
        (_explicitDishTriggers.containsKey(cleanName)
            ? _explicitDishTriggers[cleanName]!
            : classifyFood(foodName));
    return !activeTriggers.any((t) => triggers.contains(t.toLowerCase().trim()));
  }

  /// Formats trigger keys into readable human labels without underscores
  static String formatTriggerLabel(String trigger) {
    switch (trigger.toLowerCase().trim()) {
      case 'spicy':
        return 'No Spicy';
      case 'acidic':
        return 'No Acidic';
      case 'dairy':
        return 'No Dairy';
      case 'high_fodmap':
        return 'No High FODMAP';
      case 'deep_fried':
        return 'No Deep Fried';
      case 'caffeine':
        return 'No Caffeine';
      case 'carbonated':
        return 'No Carbonated';
      case 'artificial_sweeteners':
        return 'No Artificial Sweeteners';
      case 'gluten':
        return 'No Gluten';
      case 'heavy_oil':
        return 'No Heavy Oil';
      case 'heavy_fat':
        return 'No Heavy Fats';
      case 'dry_refined':
        return 'No Refined / Dry';
      case 'insoluble_roughage':
        return 'No Roughage';
      default:
        return 'No ${trigger.replaceAll('_', ' ')}';
    }
  }

  /// Determines if a food item is high in fiber (>= 6g) or made of fiber-rich whole foods.
  static bool isHighFiber(
    String foodName, {
    Set<String>? tags,
    Map<String, String>? nutrition,
  }) {
    if (nutrition != null && nutrition.containsKey('Fiber')) {
      final rawFiber = nutrition['Fiber']?.replaceAll(RegExp(r'[^0-9.]'), '');
      if (rawFiber != null && rawFiber.isNotEmpty) {
        final val = double.tryParse(rawFiber);
        if (val != null && val >= 6.0) return true;
      }
    }
    final lower = foodName.toLowerCase();
    const fiberKeywords = [
      'oats',
      'oatmeal',
      'porridge',
      'papaya',
      'moong dal',
      'daal',
      'dal',
      'lentil',
      'lauki',
      'chia',
      'beans',
      'chana',
      'chickpea',
      'rajma',
      'flaxseed',
      'whole wheat',
      'multigrain',
      'apple',
      'pear',
      'spinach',
      'palak',
      'fiber',
      'high fiber',
      'daliya',
      'brown rice',
      'barley',
    ];
    for (final kw in fiberKeywords) {
      if (lower.contains(kw)) return true;
    }
    if (tags != null) {
      for (final t in tags) {
        final tLower = t.toLowerCase();
        if (tLower.contains('fiber') || tLower.contains('high fiber')) return true;
      }
    }
    return false;
  }

  /// Determines if a food item is a gentle, bland, low-fat gastro-sparing option.
  static bool isBland(
    String foodName, {
    Set<String>? tags,
  }) {
    final lower = foodName.toLowerCase();

    // Strict non-bland exclusions (spicy, acidic, or gas-producing dishes)
    if (lower.contains('rasam') ||
        lower.contains('sambar') ||
        lower.contains('sambhar') ||
        lower.contains('cabbage') ||
        lower.contains('chili') ||
        lower.contains('chilli') ||
        lower.contains('mirch') ||
        lower.contains('chole') ||
        lower.contains('bhatura') ||
        lower.contains('bhature') ||
        lower.contains('pakora') ||
        lower.contains('samosa') ||
        lower.contains('fried') ||
        lower.contains('curry') ||
        lower.contains('masala') ||
        lower.contains('spicy') ||
        lower.contains('karahi') ||
        lower.contains('nihari') ||
        lower.contains('tikka')) {
      return false;
    }

    const blandKeywords = [
      'khichdi',
      'idli',
      'steamed rice',
      'white rice',
      'plain rice',
      'boiled rice',
      'plain dahi',
      'curd rice',
      'toast',
      'plain toast',
      'white toast',
      'clear soup',
      'soup',
      'boiled egg',
      'boiled potato',
      'boiled',
      'steamed',
      'banana',
      'applesauce',
      'congee',
      'kanji',
      'suji kheer',
      'light broth',
      'daliya',
      'bland',
      'gentle',
      'porridge',
      'plain oatmeal',
    ];
    for (final kw in blandKeywords) {
      if (lower.contains(kw)) return true;
    }
    if (tags != null) {
      for (final t in tags) {
        final tLower = t.toLowerCase();
        if (tLower.contains('bland') ||
            tLower.contains('gentle') ||
            tLower.contains('low residue') ||
            tLower.contains('sparing')) {
          return true;
        }
      }
    }
    return false;
  }
}

