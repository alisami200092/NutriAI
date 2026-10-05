import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';

class AppsAndDevicesPage extends StatefulWidget {
  const AppsAndDevicesPage({super.key});

  @override
  State<AppsAndDevicesPage> createState() => _AppsAndDevicesPageState();
}

class _AppsAndDevicesPageState extends State<AppsAndDevicesPage> {
  final Set<String> _connectedDevices = {"Google Fit"};
  final Set<String> _warningDevices = {"Google Fit"};

  void _toggleDevice(String name) {
    setState(() {
      if (_connectedDevices.contains(name)) {
        if (_warningDevices.contains(name)) {
          _warningDevices.remove(name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$name permissions resolved and active!")),
          );
        } else {
          _connectedDevices.remove(name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Disconnected from $name")),
          );
        }
      } else {
        _connectedDevices.add(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connected to $name successfully!")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: _buildGradientAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Direct Connections
            _buildDirectConnectionsSection(),

            const SizedBox(height: 25),

            // Section 2: Other Apps
            _buildOtherAppsSection(),
          ],
        ),
      ),
    );
  }

  // --- 1. Custom Gradient App Bar ---
  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Apps & Devices".tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4DB6AC), // Teal-ish (Left)
              Color(0xFF81C784), // Light Green (Right)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text("Device Sync Help".tr()),
                content: Text(
                  "Connect your favorite fitness devices to synchronize steps, active calories, and workout sessions into NutriApp.".tr(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("OK".tr()),
                  ),
                ],
              ),
            );
          },
        ),
        // Sale Badge
        Padding(
          padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252), // Red/Orange
                shape: BoxShape.circle,
              ),
              child: Text(
                "SALE".tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Direct Connections Card ---
  Widget _buildDirectConnectionsSection() {
    return Column(
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Direct Connections".tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                Text(
                  "${_connectedDevices.length} ${'Connected'.tr()}",
                  style: const TextStyle(
                    color: Color(0xFF388E3C), // Dark Green
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.check, color: Color(0xFF388E3C), size: 20),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Card
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildDirectItem(
                name: "Google Fit",
                logoColor: Colors.blue,
                iconData: Icons.favorite,
                isConnected: _connectedDevices.contains("Google Fit"),
                hasWarning: _warningDevices.contains("Google Fit"),
              ),
              _buildDivider(),
              _buildDirectItem(
                name: "Samsung Health",
                logoColor: Colors.green,
                iconData: Icons.accessibility_new,
                isConnected: _connectedDevices.contains("Samsung Health"),
              ),
              _buildDivider(),
              _buildDirectItem(
                name: "Fitbit",
                logoColor: Colors.teal,
                iconData: Icons.grid_view,
                isConnected: _connectedDevices.contains("Fitbit"),
              ),
              _buildDivider(),
              _buildDirectItem(
                name: "GARMIN",
                logoColor: Colors.black,
                iconData: Icons.watch,
                isConnected: _connectedDevices.contains("GARMIN"),
              ),
              _buildDivider(),
              _buildDirectItem(
                name: "Withings",
                logoColor: Colors.blueAccent,
                iconData: Icons.monitor_heart_outlined,
                isConnected: _connectedDevices.contains("Withings"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. Other Apps Section ---
  Widget _buildOtherAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Connect Other Apps".tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Expand your fitness ecosystem. Connect to popular apps via Health Connect, Google Fit, or Samsung Health.".tr(),
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 15),

        // List from Image 2
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildOtherAppItem(
                "Strava",
                const Color(0xFFFC4C02),
                Icons.arrow_upward,
              ), // Strava Orange
              _buildDivider(),
              _buildOtherAppItem(
                "Nike Run Club",
                Colors.black,
                Icons.check,
              ), // Nike swoosh
              _buildDivider(),
              _buildOtherAppItem(
                "Peloton",
                const Color(0xFF1F1F1F),
                Icons.directions_bike,
              ),
              _buildDivider(),
              _buildOtherAppItem(
                "Pacer",
                const Color(0xFF2196F3),
                Icons.directions_run,
              ), // Blue shoe
              _buildDivider(),
              _buildOtherAppItem(
                "Runkeeper",
                const Color(0xFF4DB6AC),
                Icons.directions_run,
              ), // Teal guy
              _buildDivider(),
              _buildOtherAppItem(
                "MapMyRun",
                const Color(0xFF1565C0),
                Icons.map,
              ), // Under Armour Blue
              _buildDivider(),
              _buildOtherAppItem(
                "Oura",
                Colors.black,
                Icons.donut_large_outlined,
              ), // Ring
              _buildDivider(),
              _buildOtherAppItem(
                "Polar Flow",
                const Color(0xFFD32F2F),
                Icons.watch_later_outlined,
              ), // Red
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  // 1. Direct Connection Item (Has "Action Needed" or "Connect" button)
  Widget _buildDirectItem({
    required String name,
    required Color logoColor,
    required IconData iconData,
    bool isConnected = false,
    bool hasWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Logo Placeholder
          _buildLogo(iconData, logoColor),
          const SizedBox(width: 15),

          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),

          // Action
          if (hasWarning)
            InkWell(
              onTap: () => _toggleDevice(name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Action Needed".tr(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isConnected)
            InkWell(
              onTap: () => _toggleDevice(name),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  "Connected".tr(),
                  style: const TextStyle(
                    color: Color(0xFF388E3C),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _toggleDevice(name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2), // Blue
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text("Connect".tr()),
              ),
            ),
        ],
      ),
    );
  }

  // 2. Other Apps Item (Has "Connect >" style)
  Widget _buildOtherAppItem(String name, Color logoColor, IconData iconData) {
    final bool isConnected = _connectedDevices.contains(name);
    return InkWell(
      onTap: () => _toggleDevice(name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildLogo(iconData, logoColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isConnected)
              Text(
                "Connected".tr(),
                style: const TextStyle(
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            else
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _toggleDevice(name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2), // Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Connect".tr()),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 3. Logo Placeholder (Since we don't have assets, we draw nice icons)
  Widget _buildLogo(IconData icon, Color color) {
    // If 'color' is black/dark, use light background, else use specific tint
    bool isDark = color.computeLuminance() < 0.5;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: isDark ? Colors.white : color, size: 22),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE));
  }
}
