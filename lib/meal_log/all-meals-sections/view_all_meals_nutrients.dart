import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'day_nutrition_service.dart';

class NutrientsSection extends StatefulWidget {
  final DayNutritionData data;

  const NutrientsSection({super.key, required this.data});

  @override
  State<NutrientsSection> createState() => _NutrientsSectionState();
}

class _NutrientsSectionState extends State<NutrientsSection> {
  String selectedTab = "Health Factors";

  final List<String> tabs = [
    "Health Factors",
    "My Nutrients",
    "Popular",
    "All",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grain, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Nutrients".tr(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // --- Tabs ---
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade800),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Row(children: _buildSegmentedTabs()),
            ),
          ),

          const SizedBox(height: 24),

          // --- Content List ---
          if (selectedTab == "Health Factors") _buildHealthFactorsList(),
          if (selectedTab == "My Nutrients") _buildMyNutrientsList(),
          if (selectedTab == "Popular") _buildPopularList(),
          if (selectedTab == "All") _buildAllNutrientsList(),
        ],
      ),
    );
  }

  List<Widget> _buildSegmentedTabs() {
    List<Widget> widgets = [];

    for (int i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final isSelected = selectedTab == tab;

      int flexValue = 1;
      if (tab.length > 8) flexValue = 2;

      widgets.add(
        Expanded(
          flex: flexValue,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedTab = tab;
              });
            },
            child: Container(
              height: double.infinity,
              color: isSelected
                  ? const Color(0xFFE1F5FE)
                  : Colors.transparent,
              child: Center(
                child: Text(
                  tab.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (i < tabs.length - 1) {
        widgets.add(Container(width: 1, color: Colors.grey.shade800));
      }
    }
    return widgets;
  }

  // =========================================================
  // VIEW: ALL
  // =========================================================
  Widget _buildAllNutrientsList() {
    final d = widget.data;
    final calProgress = d.targetCals > 0 ? (d.totalCals / d.targetCals).clamp(0.0, 1.0) : 0.0;
    final fatProgress = d.targetFat > 0 ? (d.totalFat / d.targetFat).clamp(0.0, 1.0) : 0.0;
    final carbProgress = d.targetCarbs > 0 ? (d.totalCarbs / d.targetCarbs).clamp(0.0, 1.0) : 0.0;
    final protProgress = d.targetProtein > 0 ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.0) : 0.0;
    final satProgress = d.targetSatFat > 0 ? (d.totalSatFat / d.targetSatFat).clamp(0.0, 1.0) : 0.0;
    final fiberProgress = d.targetFiber > 0 ? (d.totalFiber / d.targetFiber).clamp(0.0, 1.0) : 0.0;
    final saltProgress = d.targetSalt > 0 ? (d.totalSalt / d.targetSalt).clamp(0.0, 1.0) : 0.0;
    final calcProgress = d.targetCalcium > 0 ? (d.totalCalcium / d.targetCalcium).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Top Main Macros ---
        _buildMacroRow(
          label: "Cals",
          value: "${d.totalCals.round()}cals, ${d.calsPercent}%",
          status: d.isCalsOver ? "over ${d.calsOverDiff}cals" : "left ${d.calsLeftDiff}cals",
          statusColor: d.isCalsOver ? Colors.orange : Colors.black87,
          progress: calProgress,
          progressColor: d.isCalsOver ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Fat",
          value: "${d.totalFat.round()}g, ${d.targetFat > 0 ? ((d.totalFat / d.targetFat) * 100).round() : 0}%",
          status: d.totalFat > d.targetFat ? "over ${d.fatOver}g" : "left ${d.fatLeft}g",
          statusColor: d.totalFat > d.targetFat ? Colors.orange : Colors.black87,
          progress: fatProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "T. Carbs",
          value: "${d.totalCarbs.round()}g, ${d.targetCarbs > 0 ? ((d.totalCarbs / d.targetCarbs) * 100).round() : 0}%",
          status: d.totalCarbs > d.targetCarbs ? "over ${d.carbsOver}g" : "left ${d.carbsLeft}g",
          statusColor: d.totalCarbs > d.targetCarbs ? Colors.orange : Colors.black87,
          progress: carbProgress,
          progressColor: d.totalCarbs > d.targetCarbs ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Protein",
          value: "${d.totalProtein.round()}g, ${d.targetProtein > 0 ? ((d.totalProtein / d.targetProtein) * 100).round() : 0}%",
          status: d.totalProtein > d.targetProtein ? "over ${d.proteinOver}g" : "left ${d.proteinLeft}g",
          statusColor: Colors.black87,
          progress: protProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildPremiumRow("Caffeine"),
        _buildPremiumRow("Alcohol"),

        // --- Fat-related ---
        _buildSectionHeader("Fat-related"),
        _buildMacroRow(
          label: "Sat Fat",
          value: "${d.totalSatFat.round()}g",
          status: d.totalSatFat > d.targetSatFat
              ? "over ${(d.totalSatFat - d.targetSatFat).round()}g"
              : "limit ${d.targetSatFat.round()}g",
          statusColor: d.totalSatFat > d.targetSatFat ? Colors.orange : Colors.black87,
          progress: satProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildMacroRow(
          label: "Tr. Fat",
          value: "${d.totalTrFat.round()}g",
          status: "limit 0g",
          statusColor: Colors.black87,
          progress: 0.0,
          progressColor: Colors.transparent,
          isBackgroundOnly: true,
        ),
        _buildPremiumRow("M. Unsat. Fat"),
        _buildPremiumRow("P. Unsat. Fat"),
        _buildPremiumRow("Chol."),

        // --- Carbs-related ---
        _buildSectionHeader("Carbs-related"),
        _buildPremiumRow("Net Carbs"),
        _buildMacroRow(
          label: "Fiber",
          value: "${d.totalFiber.round()}g, ${d.targetFiber > 0 ? ((d.totalFiber / d.targetFiber) * 100).round() : 0}%",
          status: d.totalFiber >= d.targetFiber
              ? "hit goal!"
              : "left ${(d.targetFiber - d.totalFiber).clamp(0, 999).round()}g",
          statusColor: Colors.black87,
          progress: fiberProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildPremiumRow("T. Sugars"),
        _buildPremiumRow("Added Sugars"),

        // --- Minerals ---
        const SizedBox(height: 20),
        _buildMacroRow(
          label: "Salt",
          value: "${d.totalSalt.toStringAsFixed(1)}g, ${d.targetSalt > 0 ? ((d.totalSalt / d.targetSalt) * 100).round() : 0}%",
          status: d.totalSalt > d.targetSalt
              ? "over ${(d.totalSalt - d.targetSalt).toStringAsFixed(1)}g"
              : "left ${(d.targetSalt - d.totalSalt).clamp(0, 999).toStringAsFixed(1)}g",
          statusColor: d.totalSalt > d.targetSalt ? Colors.orange : Colors.black87,
          progress: saltProgress,
          progressColor: d.totalSalt > d.targetSalt ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Calcium",
          value: "${d.totalCalcium.round()}mg, ${d.targetCalcium > 0 ? ((d.totalCalcium / d.targetCalcium) * 100).round() : 0}%",
          status: d.totalCalcium >= d.targetCalcium
              ? "hit goal!"
              : "left ${(d.targetCalcium - d.totalCalcium).clamp(0, 9999).round()}mg",
          statusColor: Colors.black87,
          progress: calcProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildPremiumRow("Iron"),
        _buildPremiumRow("Potassium"),
        _buildPremiumRow("Phosph."),
        _buildPremiumRow("Magnesium"),
        _buildPremiumRow("Zinc"),
        _buildPremiumRow("Selenium"),
        _buildPremiumRow("Copper"),
        _buildPremiumRow("Manganese"),
        _buildPremiumRow("Chromium"),
        _buildPremiumRow("Iodine"),
        _buildPremiumRow("Molybdenum"),
        _buildPremiumRow("Fluoride"),

        // --- Vitamins ---
        _buildSectionHeader("Vitamins"),
        _buildPremiumRow("Vit. A"),
        _buildPremiumRow("Vit. C"),
        _buildPremiumRow("Retinol"),
        _buildPremiumRow("A-Carotene"),
        _buildPremiumRow("B-Carotene"),
        _buildPremiumRow("Lutein"),
        _buildPremiumRow("Zeaxanthin"),
        _buildPremiumRow("B-Crypt."),
        _buildPremiumRow("Lutein+Zeax."),
        _buildPremiumRow("Lycopene"),
        _buildPremiumRow("Vit. D"),

        // --- Aminos ---
        _buildSectionHeader("Aminos"),
        _buildPremiumRow("Alanine"),
        _buildPremiumRow("Arginine"),
        _buildPremiumRow("Asp. Acid"),
        _buildPremiumRow("Cysteine"),
        _buildPremiumRow("Cystine"),
        _buildPremiumRow("Glut. Acid"),
        _buildPremiumRow("Glutamine"),
        _buildPremiumRow("Glycine"),
        _buildPremiumRow("Histidine"),
        _buildPremiumRow("Hydroxyproline"),

        // --- Omegas ---
        _buildSectionHeader("Omegas"),
        _buildPremiumRow("Omega-3s"),
        _buildPremiumRow("Omega-3 ALA"),
        _buildPremiumRow("Omega-3 EPA"),
        _buildPremiumRow("Omega-3 DHA"),
        _buildPremiumRow("Omega-6s"),
        _buildPremiumRow("Omega-6 LA"),
        _buildPremiumRow("Omega-9 EA"),

        // --- MCTs ---
        _buildSectionHeader("MCTs"),
        _buildPremiumRow("MCTs"),
        _buildPremiumRow("Caproic Acid"),
        _buildPremiumRow("Capry. Acid"),
        _buildPremiumRow("Cap. Acid"),
        _buildPremiumRow("Lau. Acid"),

        // --- Other ---
        _buildSectionHeader("Other"),
        _buildPremiumRow("CoQ10"),
        _buildPremiumRow("Oxalate"),
        _buildPremiumRow("Phytost."),
      ],
    );
  }

  // =========================================================
  // VIEW: POPULAR
  // =========================================================
  Widget _buildPopularList() {
    final d = widget.data;
    final calProgress = d.targetCals > 0 ? (d.totalCals / d.targetCals).clamp(0.0, 1.0) : 0.0;
    final fatProgress = d.targetFat > 0 ? (d.totalFat / d.targetFat).clamp(0.0, 1.0) : 0.0;
    final carbProgress = d.targetCarbs > 0 ? (d.totalCarbs / d.targetCarbs).clamp(0.0, 1.0) : 0.0;
    final protProgress = d.targetProtein > 0 ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.0) : 0.0;
    final satProgress = d.targetSatFat > 0 ? (d.totalSatFat / d.targetSatFat).clamp(0.0, 1.0) : 0.0;
    final fiberProgress = d.targetFiber > 0 ? (d.totalFiber / d.targetFiber).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMacroRow(
          label: "Cals",
          value: "${d.totalCals.round()}cals, ${d.calsPercent}%",
          status: d.isCalsOver ? "over ${d.calsOverDiff}cals" : "left ${d.calsLeftDiff}cals",
          statusColor: d.isCalsOver ? Colors.orange : Colors.black87,
          progress: calProgress,
          progressColor: d.isCalsOver ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Fat",
          value: "${d.totalFat.round()}g, ${d.targetFat > 0 ? ((d.totalFat / d.targetFat) * 100).round() : 0}%",
          status: d.totalFat > d.targetFat ? "over ${d.fatOver}g" : "left ${d.fatLeft}g",
          statusColor: d.totalFat > d.targetFat ? Colors.orange : Colors.black87,
          progress: fatProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Sat Fat",
          value: "${d.totalSatFat.round()}g",
          status: d.totalSatFat > d.targetSatFat
              ? "over ${(d.totalSatFat - d.targetSatFat).round()}g"
              : "limit ${d.targetSatFat.round()}g",
          statusColor: d.totalSatFat > d.targetSatFat ? Colors.orange : Colors.black87,
          progress: satProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildMacroRow(
          label: "Tr. Fat",
          value: "${d.totalTrFat.round()}g",
          status: "limit 0g",
          statusColor: Colors.black87,
          progress: 0.0,
          progressColor: Colors.transparent,
          isBackgroundOnly: true,
        ),
        _buildPremiumRow("M. Unsat. Fat"),
        _buildPremiumRow("P. Unsat. Fat"),
        _buildMacroRow(
          label: "T. Carbs",
          value: "${d.totalCarbs.round()}g, ${d.targetCarbs > 0 ? ((d.totalCarbs / d.targetCarbs) * 100).round() : 0}%",
          status: d.totalCarbs > d.targetCarbs ? "over ${d.carbsOver}g" : "left ${d.carbsLeft}g",
          statusColor: d.totalCarbs > d.targetCarbs ? Colors.orange : Colors.black87,
          progress: carbProgress,
          progressColor: d.totalCarbs > d.targetCarbs ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Protein",
          value: "${d.totalProtein.round()}g, ${d.targetProtein > 0 ? ((d.totalProtein / d.targetProtein) * 100).round() : 0}%",
          status: d.totalProtein > d.targetProtein ? "over ${d.proteinOver}g" : "left ${d.proteinLeft}g",
          statusColor: Colors.black87,
          progress: protProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Fiber",
          value: "${d.totalFiber.round()}g, ${d.targetFiber > 0 ? ((d.totalFiber / d.targetFiber) * 100).round() : 0}%",
          status: d.totalFiber >= d.targetFiber
              ? "hit goal!"
              : "left ${(d.targetFiber - d.totalFiber).clamp(0, 999).round()}g",
          statusColor: Colors.black87,
          progress: fiberProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildPremiumRow("Net Carbs"),
        _buildPremiumRow("T. Sugars"),
        _buildPremiumRow("Sodium"),
      ],
    );
  }

  // =========================================================
  // VIEW: MY NUTRIENTS
  // =========================================================
  Widget _buildMyNutrientsList() {
    final d = widget.data;
    final calProgress = d.targetCals > 0 ? (d.totalCals / d.targetCals).clamp(0.0, 1.0) : 0.0;
    final fatProgress = d.targetFat > 0 ? (d.totalFat / d.targetFat).clamp(0.0, 1.0) : 0.0;
    final carbProgress = d.targetCarbs > 0 ? (d.totalCarbs / d.targetCarbs).clamp(0.0, 1.0) : 0.0;
    final protProgress = d.targetProtein > 0 ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.0) : 0.0;
    final satProgress = d.targetSatFat > 0 ? (d.totalSatFat / d.targetSatFat).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMacroRow(
          label: "Cals",
          value: "${d.totalCals.round()}cals, ${d.calsPercent}%",
          status: d.isCalsOver ? "over ${d.calsOverDiff}cals" : "left ${d.calsLeftDiff}cals",
          statusColor: d.isCalsOver ? Colors.orange : Colors.black87,
          progress: calProgress,
          progressColor: d.isCalsOver ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Fat",
          value: "${d.totalFat.round()}g, ${d.targetFat > 0 ? ((d.totalFat / d.targetFat) * 100).round() : 0}%",
          status: d.totalFat > d.targetFat ? "over ${d.fatOver}g" : "left ${d.fatLeft}g",
          statusColor: d.totalFat > d.targetFat ? Colors.orange : Colors.black87,
          progress: fatProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "T. Carbs",
          value: "${d.totalCarbs.round()}g, ${d.targetCarbs > 0 ? ((d.totalCarbs / d.targetCarbs) * 100).round() : 0}%",
          status: d.totalCarbs > d.targetCarbs ? "over ${d.carbsOver}g" : "left ${d.carbsLeft}g",
          statusColor: d.totalCarbs > d.targetCarbs ? Colors.orange : Colors.black87,
          progress: carbProgress,
          progressColor: d.totalCarbs > d.targetCarbs ? Colors.orange : const Color(0xFF00C896),
        ),
        _buildMacroRow(
          label: "Protein",
          value: "${d.totalProtein.round()}g, ${d.targetProtein > 0 ? ((d.totalProtein / d.targetProtein) * 100).round() : 0}%",
          status: d.totalProtein > d.targetProtein ? "over ${d.proteinOver}g" : "left ${d.proteinLeft}g",
          statusColor: Colors.black87,
          progress: protProgress,
          progressColor: const Color(0xFF00C896),
        ),
        _buildSectionHeader("Fat-related"),
        _buildMacroRow(
          label: "Sat Fat",
          value: "${d.totalSatFat.round()}g",
          status: d.totalSatFat > d.targetSatFat
              ? "over ${(d.totalSatFat - d.targetSatFat).round()}g"
              : "limit ${d.targetSatFat.round()}g",
          statusColor: d.totalSatFat > d.targetSatFat ? Colors.orange : Colors.black87,
          progress: satProgress,
          progressColor: Colors.purpleAccent,
        ),
        _buildMacroRow(
          label: "Tr. Fat",
          value: "${d.totalTrFat.round()}g",
          status: "limit not set",
          statusColor: Colors.black87,
          progress: 0.0,
          progressColor: Colors.transparent,
          isBackgroundOnly: true,
        ),
      ],
    );
  }

  // =========================================================
  // VIEW: HEALTH FACTORS
  // =========================================================
  Widget _buildHealthFactorsList() {
    final d = widget.data;
    final double saltRatio = d.targetSalt > 0 ? (d.totalSalt / d.targetSalt).clamp(0.0, 1.0) : 0.0;
    final double boneRatio = ((d.targetCalcium > 0 ? d.totalCalcium / d.targetCalcium : 0.0) * 0.5 +
            (d.targetProtein > 0 ? d.totalProtein / d.targetProtein : 0.0) * 0.5)
        .clamp(0.0, 1.0);
    final double energyRatio = d.targetCals > 0 ? (d.totalCals / d.targetCals).clamp(0.0, 1.0) : 0.0;
    final double bloodRatio = d.targetProtein > 0 ? (d.totalProtein / d.targetProtein).clamp(0.0, 1.0) : 0.0;
    final double immuneRatio = ((d.targetProtein > 0 ? d.totalProtein / d.targetProtein : 0.0) * 0.5 +
            (d.targetFiber > 0 ? d.totalFiber / d.targetFiber : 0.0) * 0.5)
        .clamp(0.0, 1.0);

    return Column(
      children: [
        _buildHealthRow(
          "Electrolytes",
          saltRatio,
          Icons.flash_on_outlined,
          Colors.cyan,
          Colors.cyan.shade50,
        ),
        _buildHealthRow(
          "Bone Health",
          boneRatio,
          Icons.accessibility_new,
          Colors.brown.shade300,
          Colors.brown.shade50,
        ),
        _buildHealthRow(
          "Energy Support",
          energyRatio,
          Icons.bolt,
          Colors.amber,
          Colors.amber.shade50,
        ),
        _buildHealthRow(
          "Blood Health",
          bloodRatio,
          Icons.water_drop,
          Colors.redAccent,
          Colors.red.shade50,
        ),
        _buildHealthRow(
          "Immune Support",
          immuneRatio,
          Icons.shield_outlined,
          Colors.blue,
          Colors.blue.shade50,
        ),
      ],
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

  String _formatStatus(String status) {
    if (status == "hit goal!") return "hit goal!".tr();
    if (status == "limit not set") return "limit not set".tr();
    if (status.startsWith("over ")) return "${"over".tr()} ${status.substring(5)}";
    if (status.startsWith("left ")) return "${"left".tr()} ${status.substring(5)}";
    if (status.startsWith("limit ")) return "${"limit".tr()} ${status.substring(6)}";
    return status.tr();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required double progress,
    required Color progressColor,
    bool isBackgroundOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label.tr(),
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: isBackgroundOnly ? 0.0 : progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEEEEEE),
                          color: isBackgroundOnly ? Colors.transparent : progressColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label.tr(),
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        "Available in Premium".tr(),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.lock, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0,
                          minHeight: 8,
                          backgroundColor: Color(0xFFEEEEEE),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(
    String title,
    double percentage,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${(percentage * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
