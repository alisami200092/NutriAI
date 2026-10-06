import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/dashboard/doctor_report_screen.dart';
import 'package:nutriapp/services/gi_trigger_service.dart';

class GutShieldBanner extends StatelessWidget {
  final String symptomSummary;
  final List<String> activeTriggers;
  final VoidCallback onDismiss;

  const GutShieldBanner({
    super.key,
    required this.symptomSummary,
    required this.activeTriggers,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final String summaryText = symptomSummary.trim().isNotEmpty
        ? symptomSummary.trim()
        : "digestive discomfort".tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), // Gentle soft soothing green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81C784),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Dismiss Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield Icon Badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Gut Shield Active".tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "PROTECTED".tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${"Meals filtered to ease".tr()} $summaryText.",
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Active Trigger Chips
          if (activeTriggers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: activeTriggers.map((trigger) {
                final label = GiTriggerService.formatTriggerLabel(trigger);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFA5D6A7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.do_not_disturb_on_total_silence_rounded,
                        size: 13,
                        color: Color(0xFFC62828),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFC8E6C9)),
          const SizedBox(height: 6),

          // Bottom Actions: Doctor Report + Dismiss button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorReportScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.assignment_outlined,
                  size: 15,
                  color: Color(0xFF1B5E20),
                ),
                label: Text(
                  "Doctor Report".tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: Color(0xFF2E7D32),
                ),
                label: Text(
                  "Feeling better? Dismiss".tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
