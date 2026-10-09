import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutriapp/chatbot/chatbot_services.dart';
import 'package:nutriapp/services/doctor_pdf_service.dart';
import 'package:nutriapp/services/gi_trigger_service.dart';

class DoctorReportScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final Map<String, dynamic>? giData;

  const DoctorReportScreen({
    super.key,
    this.initialProfile,
    this.giData,
  });

  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String _reportContent = "";
  String? _errorMessage;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _giData;
  List<Map<String, dynamic>> _recentMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchAndGenerateReport();
  }

  Future<void> _fetchAndGenerateReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic>? profile = widget.initialProfile;
      Map<String, dynamic>? giData = widget.giData;

      if (user != null) {
        if (profile == null || giData == null) {
          final doc = await FirebaseFirestore.instance
              .collection('UserProfiles')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            profile = doc.data();
            giData = {
              'gut_shield_active': doc.data()?['gut_shield_active'],
              'motility_state': doc.data()?['motility_state'],
              'dietary_strategy': doc.data()?['dietary_strategy'],
              'blocked_triggers': doc.data()?['blocked_triggers'],
              'active_gi_triggers': doc.data()?['active_gi_triggers'],
              'symptom_summary': doc.data()?['symptom_summary'],
              'last_gi_incident': doc.data()?['last_gi_incident'],
            };
          }
        }
      }

      // Collect recent meals from today's mealslog
      List<Map<String, dynamic>> recentMeals = [];
      if (user != null) {
        final now = DateTime.now();
        final dateKey =
            "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        for (final cat in ['breakfast', 'lunch', 'dinner', 'snack']) {
          try {
            final snap = await FirebaseFirestore.instance
                .collection('mealslog')
                .doc(user.uid)
                .collection('days')
                .doc(dateKey)
                .collection(cat)
                .get();

            for (final d in snap.docs) {
              final data = d.data();
              recentMeals.add({
                'category': cat,
                'name': data['name'] ?? 'Food',
                'calories': data['calories'] ?? data['estCalories'] ?? 0,
              });
            }
          } catch (_) {}
        }
      }

      final report = await ChatbotService.generateDoctorSummaryReport(
        profile: profile,
        giData: giData,
        recentMeals: recentMeals,
      );

      if (mounted) {
        setState(() {
          _profile = profile;
          _giData = giData;
          _recentMeals = recentMeals;
          _reportContent = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadOrPrintPdf() async {
    if (_reportContent.isEmpty) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await DoctorPdfService.printOrDownloadPdf(
        profile: _profile,
        giData: _giData,
        recentMeals: _recentMeals,
        clinicalBrief: _reportContent,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _sharePdf() async {
    if (_reportContent.isEmpty) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await DoctorPdfService.sharePdfFile(
        profile: _profile,
        giData: _giData,
        recentMeals: _recentMeals,
        clinicalBrief: _reportContent,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _copyToClipboard() {
    if (_reportContent.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _reportContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Report copied to clipboard".tr()),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGutShieldActive = _giData?['gut_shield_active'] == true;
    final List<dynamic> rawTriggers =
        (_giData?['active_gi_triggers'] as List<dynamic>?) ?? [];
    final activeTriggers = rawTriggers.map((e) => e.toString()).toList();
    final symptomSummary =
        _giData?['symptom_summary']?.toString() ?? 'Reported discomfort';

    final age = _profile?['age']?.toString() ?? 'N/A';

    final rawWeight = _profile?['weight'];
    final weightNum = (rawWeight is num)
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight?.toString() ?? '');
    final weight = weightNum != null ? '${weightNum.toStringAsFixed(1)} kg' : 'N/A';

    final rawHeight = _profile?['height'];
    final heightNum = (rawHeight is num)
        ? rawHeight.toDouble()
        : double.tryParse(rawHeight?.toString() ?? '');
    final height = heightNum != null ? '${heightNum.toStringAsFixed(1)} cm' : 'N/A';

    final rawTarget = _profile?['dailyCalorieTarget'] ??
        _profile?['calories'] ??
        _profile?['calorieTarget'];
    final targetNum = (rawTarget is num)
        ? rawTarget.round()
        : int.tryParse(rawTarget?.toString() ?? '');
    final calories = targetNum != null ? '$targetNum kcal' : '2000 kcal';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(
          "Doctor Summary Report".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: "Refresh Report".tr(),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchAndGenerateReport,
          ),
          IconButton(
            tooltip: "Download / Print PDF".tr(),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _reportContent.isEmpty || _isGeneratingPdf
                ? null
                : _downloadOrPrintPdf,
          ),
          IconButton(
            tooltip: "Share PDF".tr(),
            icon: const Icon(Icons.share_rounded),
            onPressed:
                _reportContent.isEmpty || _isGeneratingPdf ? null : _sharePdf,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Compiling clinical summary with GPT-4o...".tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAndGenerateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          child: Text("Try Again".tr()),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with Hospital Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF1B5E20).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Clinical Dietary & GI Brief".tr(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "For review with your healthcare provider".tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Patient Demographics Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patient Demographics".tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricTile("Age".tr(), "$age yrs"),
                                _buildMetricTile("Weight".tr(), "$weight kg"),
                                _buildMetricTile("Height".tr(), "$height cm"),
                                _buildMetricTile("Target".tr(), "$calories kcal"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // GI Safety Status Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "GI Safety Status".tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isGutShieldActive
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isGutShieldActive
                                        ? "PROTECTED".tr()
                                        : "INACTIVE".tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${"Reported Symptom:".tr()} $symptomSummary",
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            if (activeTriggers.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: activeTriggers.map((t) {
                                  final label =
                                      GiTriggerService.formatTriggerLabel(t);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFA5D6A7),
                                      ),
                                    ),
                                    child: Text(
                                      label.tr(),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Clinical Scribe Assessment Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Clinical Scribe Assessment".tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Copy Text".tr(),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  onPressed: _copyToClipboard,
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            _buildModernClinicalBrief(_reportContent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Recent Meals Log Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recent Nutritional Intake".tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_recentMeals.isEmpty)
                              Text(
                                "No manual meals recorded today.".tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentMeals.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final meal = _recentMeals[index];
                                  final rawCat = meal['category']
                                          ?.toString()
                                          .toLowerCase() ??
                                      'meal';
                                  final cat = rawCat == 'breakfast'
                                      ? 'Breakfast'
                                      : rawCat == 'lunch'
                                          ? 'Lunch'
                                          : rawCat == 'dinner'
                                              ? 'Dinner'
                                              : rawCat == 'snack'
                                                  ? 'Snack'
                                                  : 'Meal';
                                  final name =
                                      meal['name']?.toString() ?? 'Food';
                                  final cal = '${meal['calories'] ?? 0} kcal';
                                  final classified =
                                      GiTriggerService.classifyFood(name);
                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          cat.tr(),
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        cal,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      if (classified.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 15,
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Clinical Advisory Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFF59D)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFFF57F17),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "NutriAI is an educational nutritional lifestyle application and does not offer medical diagnosis or prescription. Red-flag symptoms require immediate clinical care.".tr(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5D4037),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons (Download/Print PDF & Share PDF)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _reportContent.isEmpty ||
                                      _isGeneratingPdf
                                  ? null
                                  : _downloadOrPrintPdf,
                              icon: _isGeneratingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      size: 18,
                                    ),
                              label: Text("Download / Print PDF".tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reportContent.isEmpty ||
                                      _isGeneratingPdf
                                  ? null
                                  : _sharePdf,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: Text("Share PDF".tr()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                    color: Color(0xFF2E7D32), width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildModernClinicalBrief(String rawText) {
    final lines = rawText.split('\n');
    final widgets = <Widget>[];

    String? currentHeader;
    final currentBlock = <String>[];

    void flushBlock() {
      if (currentHeader != null || currentBlock.isNotEmpty) {
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentHeader != null && currentHeader!.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 14,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentHeader!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 8),
                ],
                ...currentBlock.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildClinicalLine(line),
                  );
                }),
              ],
            ),
          ),
        );
        currentHeader = null;
        currentBlock.clear();
      }
    }

    for (final rawLine in lines) {
      String line = rawLine
          .replaceAll(RegExp(r'\*{3,}'), '')
          .replaceAll(RegExp(r'#{1,6}\s*'), '')
          .trim();

      if (line.isEmpty) continue;

      final isHeader = (line.startsWith('[') && line.endsWith(']')) ||
          (line.toUpperCase() == line &&
              line.length < 50 &&
              !line.startsWith('-') &&
              !line.startsWith('•'));

      if (isHeader) {
        flushBlock();
        currentHeader = line.replaceAll('[', '').replaceAll(']', '').trim();
      } else {
        currentBlock.add(line);
      }
    }

    flushBlock();

    if (widgets.isEmpty) {
      return Text(
        rawText,
        style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildClinicalLine(String line) {
    // Replace any markdown checkbox syntax ([x], [X], [ ], [v], [✓]) with clean bullet
    String processed = line;
    final checkboxRegex = RegExp(r'^(\s*[-*•]?\s*)\[([ xXvV✓\-]?)\]\s*');
    if (checkboxRegex.hasMatch(processed)) {
      processed = processed.replaceFirst(checkboxRegex, '• ');
    }

    final isBullet = processed.startsWith('• ') ||
        processed.startsWith('- ') ||
        processed.startsWith('* ');
    final cleanLine = isBullet ? processed.substring(2).trim() : processed;

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastIndex = 0;

    const baseStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: Color(0xFF37474F),
    );
    const boldStyle = TextStyle(
      fontSize: 13,
      height: 1.5,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1B5E20),
    );

    for (final match in regex.allMatches(cleanLine)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: cleanLine.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: boldStyle,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < cleanLine.length) {
      spans.add(TextSpan(
        text: cleanLine.substring(lastIndex),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleanLine, style: baseStyle));
    }

    if (isBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(text: TextSpan(children: spans)),
          ),
        ],
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
