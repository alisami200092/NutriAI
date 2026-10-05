import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/me/app_devices.dart';
import 'package:nutriapp/me/app_language_page.dart';
import 'package:nutriapp/me/app_preferences_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  final Color _primaryColor = const Color(0xFF09B84F);
  final Color _tealColor = const Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    final String currentLangCode = context.locale.languageCode;
    final String currentLangName = _getLanguageName(currentLangCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "App Settings".tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Localization".tr()),
            _buildCard([
              // 1. Language Navigation
              ListTile(
                leading: Icon(Icons.language_outlined, color: _primaryColor, size: 24),
                title: Text(
                  "App Language".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  currentLangName,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppLanguagePage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),

              // 2. Preferences Navigation
              ListTile(
                leading: Icon(Icons.tune_outlined, color: _tealColor, size: 24),
                title: Text(
                  "App Preferences".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  "Units, notifications, audio & more".tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppPreferencesPage()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader("Devices & Wearables".tr()),
            _buildCard([
              ListTile(
                leading: const Icon(Icons.watch_outlined, color: Colors.indigo, size: 24),
                title: Text(
                  "Connected Devices".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  "Manage fitness trackers & health apps".tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppsAndDevicesPage()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader("Data & Storage".tr()),
            _buildCard([
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orange, size: 24),
                title: Text(
                  "Clear Cache".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  "Free up temporary storage".tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Cache cleared successfully!".tr()),
                      backgroundColor: _primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader("About NutriAI".tr()),
            _buildCard([
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blueGrey, size: 24),
                title: Text(
                  "App Version".tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text("v1.0.0 (Build 2026.10)"),
              ),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'es':
        return "Español (Spanish)";
      case 'ar':
        return "العربية (Arabic)";
      case 'fr':
        return "Français (French)";
      case 'ur':
        return "اردو (Urdu)";
      case 'de':
        return "Deutsch (German)";
      case 'it':
        return "Italiano (Italian)";
      default:
        return "English (US)";
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
