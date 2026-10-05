import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLanguagePage extends StatefulWidget {
  const AppLanguagePage({super.key});

  @override
  State<AppLanguagePage> createState() => _AppLanguagePageState();
}

class _AppLanguagePageState extends State<AppLanguagePage> {
  final Color _primaryColor = const Color(0xFF09B84F);
  String _searchQuery = "";

  final List<Map<String, String>> _languages = [
    {"code": "en", "name": "English", "native": "English", "flag": "🇺🇸"},
    {"code": "es", "name": "Spanish", "native": "Español", "flag": "🇪🇸"},
    {"code": "ar", "name": "Arabic", "native": "العربية", "flag": "🇸🇦"},
    {"code": "fr", "name": "French", "native": "Français", "flag": "🇫🇷"},
    {"code": "ur", "name": "Urdu", "native": "اردو", "flag": "🇵🇰"},
    {"code": "de", "name": "German", "native": "Deutsch", "flag": "🇩🇪"},
    {"code": "it", "name": "Italian", "native": "Italiano", "flag": "🇮🇹"},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLang = context.locale.languageCode;

    final filtered = _languages.where((lang) {
      final q = _searchQuery.toLowerCase();
      return lang['name']!.toLowerCase().contains(q) ||
          lang['native']!.toLowerCase().contains(q) ||
          lang['code']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "drawer_language".tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: _primaryColor, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "lang_banner".tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "lang_search".tr(),
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "lang_available".tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 60),
                itemBuilder: (context, index) {
                  final lang = filtered[index];
                  final bool isSelected = currentLang == lang['code'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? _primaryColor : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      lang['native']!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: _primaryColor)
                        : null,
                    onTap: () async {
                      await context.setLocale(Locale(lang['code']!));
                      if (mounted) {
                        setState(() {});
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${"lang_changed".tr()} ${lang['name']}"),
                            duration: const Duration(seconds: 1),
                            backgroundColor: _primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
