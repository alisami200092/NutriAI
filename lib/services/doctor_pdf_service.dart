import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nutriapp/services/gi_trigger_service.dart';

class DoctorPdfService {
  /// Generates a high-quality, modern clinical PDF document for physician review.
  static Future<Uint8List> generatePdfBytes({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? giData,
    required List<Map<String, dynamic>> recentMeals,
    required String clinicalBrief,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final reportId = 'NB-${now.millisecondsSinceEpoch.toString().substring(5)}';

    final name = profile?['name']?.toString() ??
        profile?['fullName']?.toString() ??
        profile?['username']?.toString() ??
        'Patient';
    final age = profile?['age']?.toString() ?? 'N/A';
    final gender = profile?['gender']?.toString() ?? 'N/A';

    final rawWeight = profile?['weight'];
    final weightNum = (rawWeight is num)
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight?.toString() ?? '');
    final weight = weightNum != null ? '${weightNum.toStringAsFixed(1)} kg' : 'N/A';

    final rawHeight = profile?['height'];
    final heightNum = (rawHeight is num)
        ? rawHeight.toDouble()
        : double.tryParse(rawHeight?.toString() ?? '');
    final height = heightNum != null ? '${heightNum.toStringAsFixed(1)} cm' : 'N/A';

    final rawTarget = profile?['dailyCalorieTarget'] ??
        profile?['calories'] ??
        profile?['calorieTarget'];
    final targetNum = (rawTarget is num)
        ? rawTarget.round()
        : int.tryParse(rawTarget?.toString() ?? '');
    final calories = targetNum != null ? '$targetNum kcal' : '2000 kcal';

    final bool isGutShieldActive = giData?['gut_shield_active'] == true;
    final List<dynamic> rawTriggers =
        (giData?['active_gi_triggers'] as List<dynamic>?) ?? [];
    final activeTriggers = rawTriggers.map((e) => e.toString()).toList();
    final symptomSummary =
        giData?['symptom_summary']?.toString() ?? 'Reported digestive discomfort';

    // Modern Medical Colors
    final primaryTeal = PdfColor.fromHex('#004D40'); // Deep clinical teal
    final secondaryGreen = PdfColor.fromHex('#2E7D32'); // Medical green
    final softBg = PdfColor.fromHex('#F4F9F6');
    final accentGreen = PdfColor.fromHex('#E8F5E9');
    final borderGray = PdfColor.fromHex('#CFD8DC');
    final darkText = PdfColor.fromHex('#263238');
    final grayText = PdfColor.fromHex('#546E7A');

    // Parse clinical brief lines into clean paragraphs/sections
    final briefSections = _parseClinicalBrief(clinicalBrief);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          '+',
                          style: pw.TextStyle(
                            color: primaryTeal,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NutriBot Clinical Health Record',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'DIETARY & GI SYMPTOM CONSULTATION REPORT',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#B2DFDB'),
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'REF: $reportId',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: $dateStr',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#B2DFDB'),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.only(bottom: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NutriBot Clinical Health Record | Patient: $name | REF: $reportId',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: primaryTeal,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          }
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 5),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CONFIDENTIAL MEDICAL RECORD - For Attending Physician / Clinician Review',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. Patient Demographics & Baseline Vitals
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: softBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderGray, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '1. PATIENT DEMOGRAPHICS & NUTRITIONAL BASELINE',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                      pw.Text(
                        'Status: Active Record',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: grayText,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 22,
                        child: _buildMetricBox('Patient Name', name),
                      ),
                      pw.Expanded(
                        flex: 18,
                        child: _buildMetricBox('Age / Gender', '$age yrs | $gender'),
                      ),
                      pw.Expanded(
                        flex: 18,
                        child: _buildMetricBox('Body Weight', weight),
                      ),
                      pw.Expanded(
                        flex: 18,
                        child: _buildMetricBox('Height', height),
                      ),
                      pw.Expanded(
                        flex: 24,
                        child: _buildMetricBox('Caloric Target', calories),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 9),

            // 2. GI Safety Status & Active Trigger Exclusions
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: accentGreen,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: PdfColor.fromHex('#A5D6A7'),
                  width: 0.8,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '2. GASTROINTESTINAL (GI) SAFETY STATUS',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryGreen,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: isGutShieldActive
                              ? secondaryGreen
                              : PdfColors.grey500,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          isGutShieldActive ? 'PROTECTED (GUT SHIELD ACTIVE)' : 'INACTIVE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Chief Complaint: $symptomSummary',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Active Dietary Exclusions: ',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: grayText,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          activeTriggers.isNotEmpty
                              ? activeTriggers
                                  .map((t) =>
                                      GiTriggerService.formatTriggerLabel(t))
                                  .join(', ')
                              : 'None active',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: secondaryGreen,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 9),

            // 3. Structured Clinical Assessment (Parsed EHR Sections)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderGray, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '3. CLINICAL SCRIBE CONSULTATION BRIEF',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...briefSections.map((sec) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (sec.title.isNotEmpty) ...[
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: softBg,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                sec.title,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                          ],
                          ...sec.lines.map((line) {
                            final isBullet = line.startsWith('• ') ||
                                line.startsWith('- ') ||
                                line.startsWith('* ');
                            final cleanText =
                                isBullet ? line.substring(2).trim() : line;

                            if (isBullet) {
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 2.5),
                                child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      margin: const pw.EdgeInsets.only(
                                          top: 3.2, right: 4.5),
                                      width: 3.2,
                                      height: 3.2,
                                      decoration: pw.BoxDecoration(
                                        color: primaryTeal,
                                        shape: pw.BoxShape.circle,
                                      ),
                                    ),
                                    pw.Expanded(
                                      child: pw.Text(
                                        cleanText,
                                        style: pw.TextStyle(
                                          fontSize: 8.5,
                                          color: darkText,
                                          lineSpacing: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 2),
                                child: pw.Text(
                                  cleanText,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    color: darkText,
                                    lineSpacing: 1.25,
                                  ),
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 9),

            // 4. Nutritional Log Table (Today's Meals)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '4. RECENT NUTRITIONAL INTAKE (RECORDED TODAY)',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    pw.Text(
                      '${recentMeals.length} logged items',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        color: grayText,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                if (recentMeals.isEmpty)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: softBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGray, width: 0.8),
                    ),
                    child: pw.Text(
                      'No manual meal entries recorded for today yet.',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  )
                else
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder(
                      top: pw.BorderSide(color: borderGray, width: 0.8),
                      bottom: pw.BorderSide(color: borderGray, width: 0.8),
                      left: pw.BorderSide(color: borderGray, width: 0.8),
                      right: pw.BorderSide(color: borderGray, width: 0.8),
                      horizontalInside: const pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 0.5,
                      ),
                      verticalInside: const pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 0.5,
                      ),
                    ),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2),
                      1: pw.FlexColumnWidth(1.9),
                      2: pw.FlexColumnWidth(1.1),
                      3: pw.FlexColumnWidth(1.4),
                    },
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                      color: primaryTeal,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: accentGreen,
                    ),
                    headerAlignment: pw.Alignment.center,
                    headerAlignments: const {
                      0: pw.Alignment.center,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                    },
                    cellStyle: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.black,
                    ),
                    cellAlignment: pw.Alignment.center,
                    cellAlignments: const {
                      0: pw.Alignment.center,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                    },
                    cellPadding: const pw.EdgeInsets.symmetric(
                      vertical: 5.5,
                      horizontal: 8,
                    ),
                    oddRowDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey50,
                    ),
                    headers: ['Category', 'Food Item', 'Calories', 'Detected Triggers'],
                    data: recentMeals.map((meal) {
                      final rawCat = meal['category']?.toString() ?? 'Meal';
                      final cat = _toTitleCase(rawCat);
                      final rawName = meal['name']?.toString() ?? 'Item';
                      final name = _toTitleCase(rawName);
                      final cal = '${meal['calories'] ?? 0} kcal';
                      final triggersStr = _formatMealTriggers(rawName);
                      return [cat, name, cal, triggersStr];
                    }).toList(),
                  ),
              ],
            ),
            pw.SizedBox(height: 9),

            // 5. Clinical Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFFDE7'),
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColor.fromHex('#FFF59D')),
              ),
              child: pw.Text(
                'CLINICAL ADVISORY: NutriBot is an educational nutritional lifestyle support application. It does not provide medical diagnosis, diagnostic testing, or medication prescription. Patients experiencing acute or red-flag symptoms (severe chest/abdominal pain, persistent vomiting, or gastrointestinal bleeding) must undergo immediate clinical evaluation.',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColor.fromHex('#5D4037'),
                  fontStyle: pw.FontStyle.italic,
                  lineSpacing: 1.3,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // 6. Physician Review & Signature Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Physician Clinical Notes:',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: 210,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey400, width: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Attending Signature & Date:',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey400, width: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  static String _formatMealTriggers(String foodName) {
    final classified = GiTriggerService.classifyFood(foodName);
    if (classified.isEmpty) return 'None';
    return classified.map((t) {
      switch (t.toLowerCase().trim()) {
        case 'spicy':
          return 'Spicy';
        case 'acidic':
          return 'Acidic';
        case 'dairy':
          return 'Dairy';
        case 'high_fodmap':
          return 'High FODMAP';
        case 'deep_fried':
          return 'Deep Fried';
        case 'caffeine':
          return 'Caffeine';
        case 'carbonated':
          return 'Carbonated';
        case 'artificial_sweeteners':
          return 'Sweeteners';
        case 'gluten':
          return 'Gluten';
        case 'heavy_oil':
          return 'Heavy Oil';
        case 'heavy_fat':
          return 'Heavy Fat';
        case 'dry_refined':
          return 'Refined / Dry';
        case 'insoluble_roughage':
          return 'Roughage';
        default:
          return _toTitleCase(t.replaceAll('_', ' '));
      }
    }).join(', ');
  }

  static pw.Widget _buildMetricBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7.5,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Parses raw scribe output into clean section blocks
  static List<_PdfSection> _parseClinicalBrief(String text) {
    final rawLines = text.split('\n');
    final sections = <_PdfSection>[];
    String currentTitle = '';
    final currentLines = <String>[];

    final checkboxRegex = RegExp(r'^(\s*[-*•]?\s*)\[([ xXvV✓\-]?)\]\s*');

    for (final rawLine in rawLines) {
      String line = rawLine
          .replaceAll(RegExp(r'\*{2,}'), '')
          .replaceAll(RegExp(r'#{1,6}\s*'), '')
          .trim();

      if (line.isEmpty) continue;

      // Strip any checkbox syntax like [x], [X], [ ], - [x], etc. and convert to clean bullet
      if (checkboxRegex.hasMatch(line)) {
        line = line.replaceFirst(checkboxRegex, '- ');
      }

      // Check for section header bracket like [HEADER] or all-caps header
      final isHeader = (line.startsWith('[') && line.endsWith(']')) ||
          (line.toUpperCase() == line &&
              line.length < 50 &&
              !line.startsWith('-') &&
              !line.startsWith('•'));

      if (isHeader) {
        if (currentLines.isNotEmpty) {
          sections.add(_PdfSection(currentTitle, List<String>.from(currentLines)));
          currentLines.clear();
        }
        currentTitle = line.replaceAll('[', '').replaceAll(']', '').trim();
      } else {
        currentLines.add(line);
      }
    }

    if (currentLines.isNotEmpty) {
      sections.add(_PdfSection(currentTitle, List<String>.from(currentLines)));
    }

    if (sections.isEmpty) {
      sections.add(_PdfSection('SUMMARY', [text.replaceAll(RegExp(r'[\*#]'), '').trim()]));
    }

    return sections;
  }

  /// Directly opens the system print dialog or gracefully falls back to native PDF sharing.
  static Future<void> printOrDownloadPdf({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? giData,
    required List<Map<String, dynamic>> recentMeals,
    required String clinicalBrief,
  }) async {
    final pdfBytes = await generatePdfBytes(
      profile: profile,
      giData: giData,
      recentMeals: recentMeals,
      clinicalBrief: clinicalBrief,
    );

    final filename =
        'NutriBot_Clinical_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
    } catch (_) {
      // Graceful fallback when Printing plugin is not yet natively linked:
      // Shares the PDF file directly via SharePlus which is already compiled.
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pdfBytes,
              mimeType: 'application/pdf',
              name: filename,
            )
          ],
          subject: 'NutriBot Clinical GI & Dietary Summary Report',
          text: 'NutriBot Clinical GI & Dietary Summary Report for Physician Review.',
        ),
      );
    }
  }

  /// Shares the generated PDF file directly to other apps (WhatsApp, Email, Drive).
  static Future<void> sharePdfFile({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? giData,
    required List<Map<String, dynamic>> recentMeals,
    required String clinicalBrief,
  }) async {
    final pdfBytes = await generatePdfBytes(
      profile: profile,
      giData: giData,
      recentMeals: recentMeals,
      clinicalBrief: clinicalBrief,
    );

    final filename =
        'NutriBot_Clinical_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pdfBytes,
              mimeType: 'application/pdf',
              name: filename,
            )
          ],
          subject: 'NutriBot Clinical GI & Dietary Summary Report',
        ),
      );
    }
  }
}

class _PdfSection {
  final String title;
  final List<String> lines;
  _PdfSection(this.title, this.lines);
}
