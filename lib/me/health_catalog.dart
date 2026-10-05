import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HealthCatalogPage extends StatelessWidget {
  const HealthCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Health Catalog".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
        // This creates the rectangular gradient background
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF42E695),
                Color(0xFF3BB2B8),
              ], // Green to Teal gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // --- Health Section ---
            _buildSectionCard(
              title: "Health".tr(),
              onHeaderClick: () {},
              children: [
                _buildHealthItem(
                  icon: Icons.bloodtype_outlined,
                  iconColor: Colors.blue,
                  title: "Blood Pressure".tr(),
                  subtitle: "The force of your blood against vessel walls".tr(),
                  showSeeAll: false,
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.monitor_heart_outlined,
                  iconColor: Colors.green,
                  title: "Heart Rate".tr(),
                  subtitle: "Pulse rate per minute".tr(),
                  showSeeAll: true,
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.favorite_border,
                  iconColor: Colors.redAccent,
                  title: "Resting Heart Rate".tr(),
                  subtitle: "Pulse rate when at rest".tr(),
                  showSeeAll: false,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Body Log Section ---
            _buildSectionCard(
              title: "Body Log".tr(),
              onHeaderClick: () {},
              children: [
                _buildHealthItem(
                  icon: Icons.accessibility_new,
                  iconColor: Colors.orange,
                  title: "Waist Size".tr(),
                  subtitle: "Your waist circumference".tr(),
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.accessibility,
                  iconColor: Colors.purpleAccent,
                  title: "Hip Size".tr(),
                  subtitle: "The circumference of your hips".tr(),
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.person_outline,
                  iconColor: Colors.pinkAccent,
                  title: "Chest Size".tr(),
                  subtitle: "Your chest circumference".tr(),
                  showSeeAll: true,
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.water_drop_outlined,
                  iconColor: Colors.yellow.shade700,
                  title: "Body Fat %".tr(),
                  subtitle: "Percentage of total body weight that is fat".tr(),
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.fitness_center,
                  iconColor: Colors.brown,
                  title: "Muscle %".tr(),
                  subtitle: "Percentage of total weight from muscle".tr(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Apps & Devices Data ---
            _buildSectionCard(
              title: "Apps & Devices Data".tr(),
              onHeaderClick: () {},
              children: [
                _buildHealthItem(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: Colors.deepOrange,
                  title: "Calories Out".tr(),
                  subtitle:
                      "Total calories burned for the day including activities".tr(),
                  showSeeAll: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Sleep Section ---
            _buildSectionCard(
              title: "Sleep".tr(),
              onHeaderClick: () {},
              children: [
                _buildHealthItem(
                  icon: Icons.bedtime_outlined,
                  iconColor: Colors.indigo,
                  title: "Hours of Sleep".tr(),
                  subtitle: "Total hours slept last night".tr(),
                  showSeeAll: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Custom Trackers (With Special Button) ---
            _buildSectionCard(
              title: "Custom Trackers".tr(),
              onHeaderClick: () {},
              children: [
                const SizedBox(height: 10),
                _buildCreateTrackerButton(),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 20),

            // --- Medications & Other ---
            _buildSectionCard(
              title: "Medications & Other".tr(),
              onHeaderClick: () {},
              children: [
                _buildHealthItem(
                  icon: Icons.medication_outlined,
                  iconColor: Colors.teal,
                  title: "Medications".tr(),
                  subtitle: "Log your daily intake".tr(),
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.medical_services_outlined,
                  iconColor: Colors.red,
                  title: "Insulin".tr(),
                  subtitle: "Track insulin levels".tr(),
                ),
                _buildDivider(),
                _buildHealthItem(
                  icon: Icons.work_outline,
                  iconColor: Colors.blueGrey,
                  title: "Hours of Work".tr(),
                  subtitle: "Total hours worked".tr(),
                  showSeeAll: true,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  // 1. The Card Container
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required VoidCallback onHeaderClick,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title Row
          GestureDetector(
            onTap: onHeaderClick,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // List Items
          ...children,
        ],
      ),
    );
  }

  // 2. The Individual Health Item
  Widget _buildHealthItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showSeeAll = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with pastel background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (showSeeAll)
                      Text(
                        "See All".tr(),
                        style: const TextStyle(
                          color: Color(0xFF3BB2B8), // Teal color
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Create Custom Tracker Button (Capsule Style)
  Widget _buildCreateTrackerButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1), // Light Teal Background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF009688)),
              const SizedBox(width: 10),
              Text(
                "Create Custom Tracker".tr(),
                style: const TextStyle(
                  color: Color(0xFF00796B),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF009688),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // 4. Light Divider
  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade100,
      thickness: 1,
      height: 24, // Spacing around the divider
    );
  }
}
