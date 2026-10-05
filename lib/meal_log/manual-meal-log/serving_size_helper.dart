// Helper for dynamic serving sizes, smart portion shortcuts, and unit conversions.

class ServingOption {
  final String label;
  final double grams;
  final String? unit;

  const ServingOption({
    required this.label,
    required this.grams,
    this.unit,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'grams': grams,
      };
}

class ServingSizeHelper {
  /// Analyzes food name and existing DB serving sizes to generate comprehensive,
  /// user-friendly serving shortcuts (e.g. 1 cup, 1 glass, 1 piece, 1 plate, 1 roti).
  static List<ServingOption> getSmartServingSizes({
    required String foodName,
    required List<Map<String, dynamic>> dbServingSizes,
  }) {
    final lowerName = foodName.toLowerCase().trim();
    final List<ServingOption> options = [];
    final Set<String> seenLabels = {};
    final Set<double> seenGrams = {};

    void addOption(String label, double grams, {String? unit}) {
      if (grams <= 0) return;
      final cleanLabel = label.trim();
      final roundedGrams = (grams * 10).round() / 10;
      if (!seenLabels.contains(cleanLabel.toLowerCase()) &&
          !seenGrams.contains(roundedGrams)) {
        seenLabels.add(cleanLabel.toLowerCase());
        seenGrams.add(roundedGrams);
        options.add(ServingOption(label: cleanLabel, grams: grams, unit: unit));
      }
    }

    // 1. First, include all explicit DB serving sizes saved in Firestore
    for (final s in dbServingSizes) {
      final grams = (s['grams'] ?? 0).toDouble();
      final label = (s['label'] ?? '').toString();
      if (grams > 0 && label.isNotEmpty) {
        addOption(label, grams);
      }
    }

    // 2. Intelligent Category Matching based on food name
    if (_isBeverage(lowerName)) {
      addOption('1 cup (240 ml)', 240, unit: 'cup');
      addOption('1 glass (250 ml)', 250, unit: 'glass');
      addOption('1 small cup (150 ml)', 150, unit: 'cup');
      addOption('1 mug (350 ml)', 350, unit: 'mug');
      addOption('100 ml', 100, unit: 'ml');
    } else if (_isBreadOrRoti(lowerName)) {
      if (lowerName.contains('paratha')) {
        addOption('1 paratha', 90, unit: 'piece');
        addOption('1/2 paratha', 45, unit: 'piece');
      } else if (lowerName.contains('naan')) {
        addOption('1 naan', 120, unit: 'piece');
        addOption('1/2 naan', 60, unit: 'piece');
      } else if (lowerName.contains('bread') || lowerName.contains('toast')) {
        addOption('1 slice', 30, unit: 'slice');
        addOption('2 slices', 60, unit: 'slice');
      } else if (lowerName.contains('puri') || lowerName.contains('poori')) {
        addOption('1 puri', 35, unit: 'piece');
        addOption('2 puris', 70, unit: 'piece');
      } else {
        // Standard Roti / Chapati / Phulka
        addOption('1 roti (medium)', 45, unit: 'piece');
        addOption('2 rotis', 90, unit: 'piece');
        addOption('1/2 roti', 23, unit: 'piece');
      }
    } else if (_isEgg(lowerName)) {
      addOption('1 egg (large)', 50, unit: 'piece');
      addOption('2 eggs', 100, unit: 'piece');
      addOption('1 egg white', 33, unit: 'piece');
    } else if (_isFruit(lowerName)) {
      if (lowerName.contains('banana')) {
        addOption('1 medium banana', 118, unit: 'piece');
        addOption('1 small banana', 90, unit: 'piece');
      } else if (lowerName.contains('apple')) {
        addOption('1 medium apple', 182, unit: 'piece');
        addOption('1 small apple', 150, unit: 'piece');
      } else if (lowerName.contains('mango')) {
        addOption('1 medium mango', 200, unit: 'piece');
        addOption('1 slice (50g)', 50, unit: 'slice');
        addOption('1 cup diced', 165, unit: 'cup');
      } else if (lowerName.contains('date') || lowerName.contains('khajoor')) {
        addOption('1 date', 8, unit: 'piece');
        addOption('3 dates', 24, unit: 'piece');
      } else if (lowerName.contains('orange') || lowerName.contains('kino')) {
        addOption('1 medium orange', 130, unit: 'piece');
      } else {
        addOption('1 medium piece', 150, unit: 'piece');
        addOption('1 small piece', 100, unit: 'piece');
      }
    } else if (_isSnackOrFastFood(lowerName)) {
      if (lowerName.contains('samosa')) {
        addOption('1 samosa', 70, unit: 'piece');
        addOption('2 samosas', 140, unit: 'piece');
      } else if (lowerName.contains('pakora')) {
        addOption('1 pakora', 25, unit: 'piece');
        addOption('4 pakoras (100g)', 100, unit: 'piece');
      } else if (lowerName.contains('kebab') ||
          lowerName.contains('kabab') ||
          lowerName.contains('shami') ||
          lowerName.contains('seekh')) {
        addOption('1 kebab', 55, unit: 'piece');
        addOption('2 kebabs', 110, unit: 'piece');
      } else if (lowerName.contains('roll') || lowerName.contains('shawarma')) {
        addOption('1 roll', 160, unit: 'piece');
        addOption('1/2 roll', 80, unit: 'piece');
      } else if (lowerName.contains('burger')) {
        addOption('1 burger', 160, unit: 'piece');
        addOption('1/2 burger', 80, unit: 'piece');
      } else if (lowerName.contains('sandwich')) {
        addOption('1 sandwich', 170, unit: 'piece');
        addOption('1/2 sandwich', 85, unit: 'piece');
      } else if (lowerName.contains('biscuit') || lowerName.contains('cookie')) {
        addOption('1 biscuit', 15, unit: 'piece');
        addOption('2 biscuits', 30, unit: 'piece');
      } else {
        addOption('1 piece', 60, unit: 'piece');
      }
    } else if (_isRiceOrBiryani(lowerName)) {
      addOption('1 regular plate (250g)', 250, unit: 'plate');
      addOption('1 small bowl (150g)', 150, unit: 'bowl');
      addOption('1 cup (160g)', 160, unit: 'cup');
      addOption('1 large plate (350g)', 350, unit: 'plate');
    } else if (_isCurryOrDal(lowerName)) {
      addOption('1 medium bowl (200g)', 200, unit: 'bowl');
      addOption('1 small katori (120g)', 120, unit: 'bowl');
      addOption('1 cup (240g)', 240, unit: 'cup');
      addOption('1 large bowl (300g)', 300, unit: 'bowl');
    } else if (_isCondimentOrOil(lowerName)) {
      addOption('1 tsp (5g)', 5, unit: 'tsp');
      addOption('1 tbsp (15g)', 15, unit: 'tbsp');
    } else {
      // General food fallback
      addOption('1 serving (150g)', 150, unit: 'serving');
      addOption('1 cup (200g)', 200, unit: 'cup');
    }

    // Always ensure standard 100g is available
    addOption('100g', 100, unit: 'g');
    addOption('1 oz (28.4g)', 28.35, unit: 'oz');

    return options;
  }

  /// Returns unit multipliers for the unit selection dropdown on ServingSizePage
  static Map<String, double> getSmartUnitMultipliers({
    required String foodName,
    required List<ServingOption> options,
  }) {
    final Map<String, double> multipliers = {
      'g': 1.0,
      'oz': 28.35,
    };

    final lowerName = foodName.toLowerCase();

    // Check if any option has 'piece', 'slice', 'cup', 'glass', 'bowl', 'plate'
    for (final opt in options) {
      final l = opt.label.toLowerCase();
      if (l.contains('piece') || l.contains('roti') || l.contains('burger') || l.contains('egg') || l.contains('samosa') || l.contains('kebab') || l.contains('sandwich') || l.contains('banana') || l.contains('apple')) {
        if (!multipliers.containsKey('piece')) {
          multipliers['piece'] = opt.grams;
        }
      }
      if (l.contains('cup')) {
        multipliers['cup'] = opt.grams;
      }
      if (l.contains('glass')) {
        multipliers['glass'] = opt.grams;
      }
      if (l.contains('bowl') || l.contains('katori')) {
        multipliers['bowl'] = opt.grams;
      }
      if (l.contains('plate')) {
        multipliers['plate'] = opt.grams;
      }
      if (l.contains('slice')) {
        multipliers['slice'] = opt.grams;
      }
    }

    // Fallbacks if not already set
    if (_isBeverage(lowerName)) {
      multipliers.putIfAbsent('ml', () => 1.0);
      multipliers.putIfAbsent('cup', () => 240.0);
      multipliers.putIfAbsent('glass', () => 250.0);
    } else if (_isBreadOrRoti(lowerName)) {
      multipliers.putIfAbsent('piece', () => lowerName.contains('naan') ? 120.0 : (lowerName.contains('paratha') ? 90.0 : 45.0));
    } else if (_isEgg(lowerName)) {
      multipliers.putIfAbsent('piece', () => 50.0);
    } else if (_isRiceOrBiryani(lowerName)) {
      multipliers.putIfAbsent('plate', () => 250.0);
      multipliers.putIfAbsent('bowl', () => 150.0);
      multipliers.putIfAbsent('cup', () => 160.0);
    } else if (_isCurryOrDal(lowerName)) {
      multipliers.putIfAbsent('bowl', () => 200.0);
      multipliers.putIfAbsent('cup', () => 240.0);
    }

    // Condiments & common units
    multipliers.putIfAbsent('tbsp', () => 15.0);
    multipliers.putIfAbsent('tsp', () => 5.0);
    multipliers.putIfAbsent('serving', () => 150.0);

    return multipliers;
  }

  // --- Helpers for category detection ---

  static bool _isBeverage(String name) {
    return name.contains('chai') ||
        name.contains('tea') ||
        name.contains('coffee') ||
        name.contains('milk') ||
        name.contains('doodh') ||
        name.contains('juice') ||
        name.contains('water') ||
        name.contains('pani') ||
        name.contains('lassi') ||
        name.contains('shake') ||
        name.contains('smoothie') ||
        name.contains('soup') ||
        name.contains('soda') ||
        name.contains('coke') ||
        name.contains('pepsi') ||
        name.contains('sharbat') ||
        name.contains('drink') ||
        name.contains('latte');
  }

  static bool _isBreadOrRoti(String name) {
    return name.contains('roti') ||
        name.contains('chapati') ||
        name.contains('naan') ||
        name.contains('paratha') ||
        name.contains('puri') ||
        name.contains('poori') ||
        name.contains('bread') ||
        name.contains('toast') ||
        name.contains('kulcha') ||
        name.contains('phulka');
  }

  static bool _isEgg(String name) {
    return name.contains('egg') ||
        name.contains('anda') ||
        name.contains('omelette') ||
        name.contains('omlet');
  }

  static bool _isFruit(String name) {
    return name.contains('apple') ||
        name.contains('banana') ||
        name.contains('orange') ||
        name.contains('mango') ||
        name.contains('peach') ||
        name.contains('guava') ||
        name.contains('pear') ||
        name.contains('date') ||
        name.contains('khajoor') ||
        name.contains('kino') ||
        name.contains('malta') ||
        name.contains('watermelon') ||
        name.contains('melon');
  }

  static bool _isSnackOrFastFood(String name) {
    return name.contains('samosa') ||
        name.contains('pakora') ||
        name.contains('roll') ||
        name.contains('shawarma') ||
        name.contains('burger') ||
        name.contains('sandwich') ||
        name.contains('biscuit') ||
        name.contains('cookie') ||
        name.contains('kebab') ||
        name.contains('kabab') ||
        name.contains('shami') ||
        name.contains('seekh') ||
        name.contains('patty') ||
        name.contains('nugget');
  }

  static bool _isRiceOrBiryani(String name) {
    return name.contains('rice') ||
        name.contains('biryani') ||
        name.contains('pulao') ||
        name.contains('chawal') ||
        name.contains('khichdi');
  }

  static bool _isCurryOrDal(String name) {
    return name.contains('dal') ||
        name.contains('daal') ||
        name.contains('karahi') ||
        name.contains('qorma') ||
        name.contains('korma') ||
        name.contains('nihari') ||
        name.contains('haleem') ||
        name.contains('salan') ||
        name.contains('curry') ||
        name.contains('sabzi') ||
        name.contains('chana') ||
        name.contains('cholay') ||
        name.contains('gravy');
  }

  static bool _isCondimentOrOil(String name) {
    return name.contains('ghee') ||
        name.contains('oil') ||
        name.contains('butter') ||
        name.contains('makkhan') ||
        name.contains('sugar') ||
        name.contains('honey') ||
        name.contains('jam') ||
        name.contains('mayo') ||
        name.contains('sauce') ||
        name.contains('chutney');
  }
}
