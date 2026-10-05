import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';
import 'day_nutrition_service.dart';

class DayFoodReportPage extends StatefulWidget {
  final DateTime selectedDate;

  const DayFoodReportPage({super.key, required this.selectedDate});

  @override
  State<DayFoodReportPage> createState() => _DayFoodReportPageState();
}

class _DayFoodReportPageState extends State<DayFoodReportPage> {
  late DateTime _currentDate;
  final List<String> categories = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
  }

  void _previousDay() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF09B84F),
          title: Text("Day Food Report".tr(), style: const TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Text("Please log in to view your Day Food Report.".tr()),
        ),
      );
    }

    return StreamBuilder<DayNutritionData>(
      stream: DayNutritionService.streamDayNutrition(user.uid, _currentDate),
      builder: (context, snapshot) {
        final data = snapshot.data ?? DayNutritionData.empty(_currentDate);
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF09B84F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Day Food Report".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMM').format(_currentDate),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                tooltip: "Previous Day".tr(),
                onPressed: _previousDay,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                tooltip: "Next Day".tr(),
                onPressed: _nextDay,
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PremiumScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Go Premium".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: _buildReportTable(data),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildReportTable(DayNutritionData data) {
    const Map<int, TableColumnWidth> colWidths = {
      0: FixedColumnWidth(180), // Food Name
      1: FixedColumnWidth(55), // Cals
      2: FixedColumnWidth(50), // Grade
      3: FixedColumnWidth(48), // Fat
      4: FixedColumnWidth(50), // Carbs
      5: FixedColumnWidth(50), // Protein
      6: FixedColumnWidth(50), // Sat Fat
      7: FixedColumnWidth(50), // Tr Fat
      8: FixedColumnWidth(50), // Fiber
      9: FixedColumnWidth(50), // Salt
      10: FixedColumnWidth(60), // Calcium
    };

    List<TableRow> rows = [];

    // --- 1. HEADER ROW ---
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[200]),
        children: [
          const SizedBox(height: 110),
          _buildVerticalHeader("Calories, kcal".tr()),
          _buildVerticalHeader("Food Grade".tr()),
          _buildVerticalHeader("Fat, g".tr()),
          _buildVerticalHeader("T. Carbs, g".tr()),
          _buildVerticalHeader("Protein, g".tr()),
          _buildVerticalHeader("Sat Fat, g".tr()),
          _buildVerticalHeader("Tr. Fat, g".tr()),
          _buildVerticalHeader("Fiber, g".tr()),
          _buildVerticalHeader("Salt, g".tr()),
          _buildVerticalHeader("Calcium, mg".tr()),
        ],
      ),
    );

    // --- 2. CATEGORY SECTIONS ---
    for (String cat in categories) {
      final items = data.itemsByCategory[cat] ?? [];

      double sCals = 0;
      double sFat = 0;
      double sCarbs = 0;
      double sProt = 0;
      double sSat = 0;
      double sTr = 0;
      double sFib = 0;
      double sSalt = 0;
      double sCalc = 0;

      for (var item in items) {
        double itemCals = 0;
        if (item.containsKey('estCalories') && item['estCalories'] is num) {
          itemCals = (item['estCalories'] as num).toDouble();
        } else if (item.containsKey('calories') && item['calories'] is num) {
          itemCals = (item['calories'] as num).toDouble();
        } else {
          itemCals = DayNutritionService.calculateMacroValue(item, 'caloriesPer100g');
        }
        sCals += itemCals;
        sFat += DayNutritionService.calculateMacroValue(item, 'saturatedFatPer100g', 'fat');
        sCarbs += DayNutritionService.calculateMacroValue(item, 'carbsPer100g', 'carbs');
        sProt += DayNutritionService.calculateMacroValue(item, 'proteinPer100g', 'protein');
        sSat += DayNutritionService.calculateMacroValue(item, 'saturatedFatPer100g');
        sFib += DayNutritionService.calculateMacroValue(item, 'fiberPer100g');
        sSalt += DayNutritionService.calculateMacroValue(item, 'saltPer100g');
        sCalc += DayNutritionService.calculateMacroValue(item, 'calciumPer100g');
      }

      final String catTitle = cat == 'snack'
          ? 'Snacks'
          : "${cat[0].toUpperCase()}${cat.substring(1)}";

      // Section Header Row
      rows.add(
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Text(
                catTitle.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
            _buildCellText(sCals.round().toString(), isBold: true),
            _buildGradeCell(items.isEmpty ? "--" : _calculateCategoryGrade(sProt, sSat, sCals)),
            _buildCellText(sFat.round().toString(), isBold: true),
            _buildCellText(sCarbs.round().toString(), isBold: true),
            _buildCellText(sProt.round().toString(), isBold: true),
            _buildCellText(sSat.round().toString(), isBold: true),
            _buildCellText(sTr.round().toString(), isBold: true),
            _buildCellText(sFib.round().toString(), isBold: true),
            _buildCellText(sSalt.toStringAsFixed(1), isBold: true),
            _buildCellText(sCalc.round().toString(), isBold: true),
          ],
        ),
      );

      // Individual Food Items
      if (items.isEmpty) {
        rows.add(
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text(
                  "No food logged".tr(),
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
              _buildCellText("-"),
            ],
          ),
        );
      } else {
        for (var item in items) {
          final String name = (item['name'] ?? "Food").toString();
          String servingText = "1 serving";
          if (item['loggedServing'] != null && item['loggedServing'] is Map) {
            final amt = item['loggedServing']['amount'];
            final unit = item['loggedServing']['unit'];
            if (amt != null && unit != null) {
              servingText = "$amt $unit";
            }
          }

          double itemCals = 0;
          if (item.containsKey('estCalories') && item['estCalories'] is num) {
            itemCals = (item['estCalories'] as num).toDouble();
          } else if (item.containsKey('calories') && item['calories'] is num) {
            itemCals = (item['calories'] as num).toDouble();
          } else {
            itemCals = DayNutritionService.calculateMacroValue(item, 'caloriesPer100g');
          }

          final itemFat = DayNutritionService.calculateMacroValue(item, 'saturatedFatPer100g', 'fat');
          final itemCarbs = DayNutritionService.calculateMacroValue(item, 'carbsPer100g', 'carbs');
          final itemProt = DayNutritionService.calculateMacroValue(item, 'proteinPer100g', 'protein');
          final itemSat = DayNutritionService.calculateMacroValue(item, 'saturatedFatPer100g');
          final itemFib = DayNutritionService.calculateMacroValue(item, 'fiberPer100g');
          final itemSalt = DayNutritionService.calculateMacroValue(item, 'saltPer100g');
          final itemCalc = DayNutritionService.calculateMacroValue(item, 'calciumPer100g');

          final itemGrade = _calculateItemGrade(itemProt, itemSat, itemCals);

          rows.add(
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              children: [
                _buildFoodNameCell(name, servingText),
                _buildCellText(itemCals.round().toString()),
                _buildGradeCell(itemGrade),
                _buildCellText(itemFat.round().toString()),
                _buildCellText(itemCarbs.round().toString()),
                _buildCellText(itemProt.round().toString()),
                _buildCellText(itemSat.round().toString()),
                _buildCellText("0"),
                _buildCellText(itemFib.round().toString()),
                _buildCellText(itemSalt.toStringAsFixed(1)),
                _buildCellText(itemCalc.round().toString()),
              ],
            ),
          );
        }
      }
    }

    // --- 3. FOOTER: Day Total ---
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[200]),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Day total".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          _buildCellText(data.totalCals.round().toString(), isBold: true),
          _buildGradeCell(data.foodGrade),
          _buildCellText(data.totalFat.round().toString(), isBold: true),
          _buildCellText(data.totalCarbs.round().toString(), isBold: true),
          _buildCellText(data.totalProtein.round().toString(), isBold: true),
          _buildCellText(data.totalSatFat.round().toString(), isBold: true),
          _buildCellText(data.totalTrFat.round().toString(), isBold: true),
          _buildCellText(data.totalFiber.round().toString(), isBold: true),
          _buildCellText(data.totalSalt.toStringAsFixed(1), isBold: true),
          _buildCellText(data.totalCalcium.round().toString(), isBold: true),
        ],
      ),
    );

    // --- 4. FOOTER: My Target ---
    rows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "My Target".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          _buildCellText(data.targetCals.round().toString()),
          const SizedBox(),
          _buildCellText(data.targetFat.round().toString()),
          _buildCellText(data.targetCarbs.round().toString()),
          _buildCellText(data.targetProtein.round().toString()),
          _buildCellText(data.targetSatFat.round().toString()),
          _buildCellText(data.targetTrFat.round().toString()),
          _buildCellText(data.targetFiber.round().toString()),
          _buildCellText(data.targetSalt.toStringAsFixed(1)),
          _buildCellText(data.targetCalcium.round().toString()),
        ],
      ),
    );

    // --- 5. FOOTER: % of Target (with Bars) ---
    rows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "% of My Target".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          _buildPercentCell(data.totalCals, data.targetCals),
          const SizedBox(),
          _buildPercentCell(data.totalFat, data.targetFat),
          _buildPercentCell(data.totalCarbs, data.targetCarbs),
          _buildPercentCell(data.totalProtein, data.targetProtein),
          _buildPercentCell(data.totalSatFat, data.targetSatFat),
          const SizedBox(),
          _buildPercentCell(data.totalFiber, data.targetFiber),
          _buildPercentCell(data.totalSalt, data.targetSalt),
          _buildPercentCell(data.totalCalcium, data.targetCalcium),
        ],
      ),
    );

    return Table(
      columnWidths: colWidths,
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildVerticalHeader(String text) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCellText(String text, {bool isBold = false}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildGradeCell(String grade) {
    Color gradeColor = Colors.grey;
    if (grade.startsWith("A")) gradeColor = const Color(0xFF00C896);
    if (grade.startsWith("B")) gradeColor = const Color(0xFF37C97D);
    if (grade.startsWith("C")) gradeColor = Colors.orange;
    if (grade.startsWith("D")) gradeColor = Colors.red;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        grade,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: gradeColor,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFoodNameCell(String name, String serving) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          Text(
            _emojiForLabel(name),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  serving,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentCell(double actual, double target) {
    if (target <= 0) return _buildCellText("-");

    double percent = (actual / target);
    String text = "${(percent * 100).toInt()}%";

    double barHeight = percent > 1.0 ? 1.0 : percent;
    if (barHeight < 0) barHeight = 0;

    return Container(
      height: 60,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: barHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: percent > 1.0 ? Colors.orange : const Color(0xFF37C97D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('bread') || lower.contains('roti') || lower.contains('chapati') || lower.contains('naan')) {
      return '🍞';
    }
    if (lower.contains('kebab') || lower.contains('tikka')) return '🥙';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('rice') || lower.contains('biryani')) return '🍚';
    if (lower.contains('daal') || lower.contains('lentil')) return '🍲';
    if (lower.contains('chai') || lower.contains('tea')) return '☕';
    if (lower.contains('coffee')) return '☕';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('salad')) return '🥗';
    if (lower.contains('biscuit') || lower.contains('cookie')) return '🍪';
    return '🍽️';
  }

  String _calculateCategoryGrade(double protein, double satFat, double calories) {
    if (calories <= 0) return "--";
    final protCal = protein * 4.0;
    final satCal = satFat * 9.0;
    final protRatio = protCal / calories;
    final satRatio = satCal / calories;

    if (protRatio >= 0.25 && satRatio <= 0.15) return "A";
    if (protRatio >= 0.18 && satRatio <= 0.25) return "B+";
    if (protRatio >= 0.10 && satRatio <= 0.35) return "B";
    if (satRatio > 0.40) return "C";
    return "B-";
  }

  String _calculateItemGrade(double protein, double satFat, double calories) {
    return _calculateCategoryGrade(protein, satFat, calories);
  }
}
