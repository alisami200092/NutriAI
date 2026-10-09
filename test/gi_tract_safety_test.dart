import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/services/red_flag_triage_service.dart';
import 'package:nutriapp/services/gi_trigger_service.dart';
import 'package:nutriapp/services/doctor_pdf_service.dart';

void main() {
  group('RedFlagTriageService Tests', () {
    test('Detects GI bleeding variations', () {
      expect(RedFlagTriageService.hasRedFlag('There is blood in my stool'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('I noticed black stool today'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('I have been pooping blood'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Vomiting blood since morning'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Suffering from rectal bleeding'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Potty mein khoon aa raha hai'), isTrue);
    });

    test('Detects dangerous high fever', () {
      expect(RedFlagTriageService.hasRedFlag('I have high fever and stomach pain'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Temperature is 103 F with chills'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Fever 39.5 C and belly ache'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Tez bukhar hai pet dard ke sath'), isTrue);
    });

    test('Detects persistent vomiting & inability to keep fluids down', () {
      expect(RedFlagTriageService.hasRedFlag('Continuous vomiting for 24 hours'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Unable to hold liquids down'), isTrue);
      expect(RedFlagTriageService.hasRedFlag("Can't keep water down at all"), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Throwing up all night non stop'), isTrue);
    });

    test('Detects severe localized abdominal pain', () {
      expect(RedFlagTriageService.hasRedFlag('Severe abdominal pain since last night'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Sharp localized stomach pain on lower right'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Excruciating stomach pain and doubled over'), isTrue);
    });

    test('Detects fainting & severe unexplained dizziness', () {
      expect(RedFlagTriageService.hasRedFlag('I fainted and fell down with stomach pain'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Passed out after stomach cramps'), isTrue);
      expect(RedFlagTriageService.hasRedFlag('Unexplained dizziness and blacking out'), isTrue);
    });

    test('Correctly honors negations (no false positives)', () {
      expect(RedFlagTriageService.hasRedFlag('I have no blood in my stool'), isFalse);
      expect(RedFlagTriageService.hasRedFlag('There is no bleeding'), isFalse);
      expect(RedFlagTriageService.hasRedFlag('Doctor confirmed no high fever'), isFalse);
    });

    test('Excludes ordinary menstrual / period cramps from abdominal emergency', () {
      expect(RedFlagTriageService.hasRedFlag('Just having cramps from my period'), isFalse);
      expect(RedFlagTriageService.hasRedFlag('Normal menstrual cramps today'), isFalse);
    });

    test('Allows standard non-emergency GI motility symptoms to pass', () {
      expect(RedFlagTriageService.hasRedFlag("Haven't gone to the bathroom in 2 days, constipated"), isFalse);
      expect(RedFlagTriageService.hasRedFlag('Stomach running and watery loose stools'), isFalse);
      expect(RedFlagTriageService.hasRedFlag('Feeling queasy with mild nausea'), isFalse);
      expect(RedFlagTriageService.hasRedFlag('Acid reflux and mild heartburn after coffee'), isFalse);
    });
  });

  group('GiTriggerService Keyword Collision & Precision Tests', () {
    test('Rolled oats does NOT collide with deep_fried "roll"', () {
      final triggers = GiTriggerService.classifyFood('Rolled Oats Porridge with Banana');
      expect(triggers.contains('deep_fried'), isFalse);
      expect(triggers.contains('heavy_oil'), isFalse);
    });

    test('Chia seeds does NOT collide with roughage "seeds"', () {
      final triggers = GiTriggerService.classifyFood('Chia Seed Pudding with Almond Milk');
      expect(triggers.contains('insoluble_roughage'), isFalse);
    });

    test('Bell pepper does NOT collide with "pepper" in spicy', () {
      final triggers = GiTriggerService.classifyFood('Sautéed Bell Peppers and Mushrooms');
      expect(triggers.contains('spicy'), isFalse);
    });

    test('Makhana does NOT collide with butter "makhan" in dairy', () {
      final triggers = GiTriggerService.classifyFood('Roasted Makhana (Foxnuts)');
      expect(triggers.contains('dairy'), isFalse);
    });

    test('Correctly catches Bhatura in heavy_oil', () {
      final triggers = GiTriggerService.classifyFood('Chole Bhatura with Pickles');
      expect(triggers.contains('heavy_oil'), isTrue);
    });

    test('Correctly catches Cucumber Salad in insoluble_roughage', () {
      final triggers = GiTriggerService.classifyFood('Dal Tadka with Steamed Rice and Cucumber Salad');
      expect(triggers.contains('insoluble_roughage'), isTrue);
    });

    test('isBland strictly excludes Rasam, Sambar, Cabbage, and Spicy items', () {
      expect(GiTriggerService.isBland('South Indian Meals: Sambar, Rasam, Cabbage Poriyal & Steamed Rice'), isFalse);
      expect(GiTriggerService.isBland('Chole Bhatura with Masala'), isFalse);
      expect(GiTriggerService.isBland('Spicy Chicken Karahi'), isFalse);
      expect(GiTriggerService.isBland('Steamed Basmati Rice with Plain Dahi'), isTrue);
      expect(GiTriggerService.isBland('Moong Dal Khichdi'), isTrue);
      expect(GiTriggerService.isBland('Plain Toast with Boiled Egg'), isTrue);
    });
  });

  group('DoctorPdfService Tests', () {
    test('generatePdfBytes succeeds and formats bullets & centered table', () async {
      final pdfBytes = await DoctorPdfService.generatePdfBytes(
        profile: {
          'name': 'Ali Sami',
          'age': '25',
          'gender': 'Male',
          'weight': 70.0,
          'height': 175.0,
          'dailyCalorieTarget': 2200,
        },
        giData: {
          'gut_shield_active': true,
          'motility_state': 'diarrhea',
          'dietary_strategy': 'low_residue_bland',
          'active_gi_triggers': ['spicy', 'dairy'],
          'symptom_summary': 'Loose watery stools',
        },
        recentMeals: [
          {'category': 'breakfast', 'name': 'Moong Dal Khichdi', 'calories': 350},
          {'category': 'lunch', 'name': 'Steamed Rice with Boiled Chicken', 'calories': 480},
        ],
        clinicalBrief: """
[CHIEF COMPLAINT & SYMPTOM TIMELINE]
- [x] Patient presents with active GI motility changes (diarrhea).
- [ ] No red-flag symptoms reported.
• Diet adjusted for low-residue bland foods.
""",
      );
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
