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
  };

  /// Returns active GI triggers detected in a dish's title or description.
  static List<String> classifyFood(
    String foodName, {
    List<String>? ingredients,
  }) {
    final lowerName = foodName.toLowerCase();
    final Set<String> triggersFound = {};

    _triggerKeywords.forEach((trigger, keywords) {
      for (final kw in keywords) {
        if (kw == 'makhan' && lowerName.contains('makhana')) {
          continue; // Makhana is roasted foxnuts (plant seed), not butter!
        }
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
            if (kw == 'makhan' && lowerIng.contains('makhana')) {
              continue;
            }
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
    final triggers =
        explicitTriggers ?? classifyFood(foodName);
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
      default:
        return 'No ${trigger.replaceAll('_', ' ')}';
    }
  }
}
