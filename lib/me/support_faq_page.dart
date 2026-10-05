import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  final Color primaryTeal = const Color(0xFF81C7B5);
  final Color scaffoldBg = const Color(0xFFF0F2F5);

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _allFaqs = [
    {
      "question": "How do I log my food?",
      "answer":
          "Tap the center '+' camera button on the bottom navigation bar or dashboard to snap a photo of your food or search the meal database.",
    },
    {
      "question": "Can I track macronutrients?",
      "answer":
          "Yes! Navigate to 'My Plan' and select the 'Macros' tab to see your daily breakdown of Carbs, Protein, and Fats in grams and percentages.",
    },
    {
      "question": "Where can you find recipes?",
      "answer":
          "Check the Recipes section in the app to discover AI-tailored recipes that match your calorie budget and dietary restrictions.",
    },
    {
      "question": "How are my calories calculated?",
      "answer":
          "We use the Mifflin-St Jeor formula factoring in your gender, weight, height, age, and activity level to compute your maintenance TDEE and deficit target.",
    },
    {
      "question": "Can I sync with Google Fit or Samsung Health?",
      "answer":
          "Yes! Go to Me -> Apps & Devices to connect your fitness trackers and synchronize burned exercise calories automatically.",
    },
  ];

  String _searchQuery = "";
  final Set<int> _expandedIndices = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    const String email = 'support@nutriapp.com';
    await Clipboard.setData(const ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Support email copied to clipboard: support@nutriapp.com"),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      final q = faq["question"]!.toLowerCase();
      final a = faq["answer"]!.toLowerCase();
      final search = _searchQuery.toLowerCase();
      return q.contains(search) || a.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Support & Center".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("NutriApp Help & Support Center")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search FAQS & Help Articles".tr(),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Top FAQS Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchQuery.isEmpty ? "Top FAQS".tr() : "${"Search Results".tr()} (${filteredFaqs.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredFaqs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text("No articles found matching your search.".tr(), style: const TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...List.generate(filteredFaqs.length, (index) {
                        final faq = filteredFaqs[index];
                        final isExpanded = _expandedIndices.contains(index);
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedIndices.remove(index);
                                  } else {
                                    _expandedIndices.add(index);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            faq["question"]!.tr(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                                          color: isExpanded ? primaryTeal : Colors.grey,
                                        ),
                                      ],
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        faq["answer"]!.tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (index < filteredFaqs.length - 1)
                              const Divider(height: 1, thickness: 0.5),
                          ],
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Categories List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildCategoryItem(
                      icon: Icons.restaurant_menu,
                      title: "Food Logging".tr(),
                      count: "15 ${"articles".tr()}",
                      onTap: () {
                        setState(() {
                          _searchController.text = "food";
                          _searchQuery = "food";
                        });
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20),
                    _buildCategoryItem(
                      icon: Icons.bar_chart,
                      title: "Progress & Goals".tr(),
                      count: "10 ${"articles".tr()}",
                      onTap: () {
                        setState(() {
                          _searchController.text = "calories";
                          _searchQuery = "calories";
                        });
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20),
                    _buildCategoryItem(
                      icon: Icons.credit_card,
                      title: "Account & Billing".tr(),
                      count: "5 ${"articles".tr()}",
                      onTap: () {
                        setState(() {
                          _searchController.text = "sync";
                          _searchQuery = "sync";
                        });
                      },
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20),
                    _buildCategoryItem(
                      icon: Icons.eco_outlined,
                      title: "Recipes & Meal Plans".tr(),
                      count: "8 ${"articles".tr()}",
                      onTap: () {
                        setState(() {
                          _searchController.text = "recipes";
                          _searchQuery = "recipes";
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 4. Contact Support Section
              Text(
                "Contact Support".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Need help? Reach out to our support team directly.".tr(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "E-mail Support Team".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 5. Additional Information
              Text(
                "Additional Information".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Terms of Service".tr()),
                      content: const Text(
                        "NutriApp helps you track your meals and health goals. All meal plans are guidance. Consult a medical professional for personal medical advice.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Close".tr()),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  "Terms of Service".tr(),
                  style: const TextStyle(color: Colors.blue, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Privacy Policy".tr()),
                      content: const Text(
                        "Your health data is securely stored and never shared with third parties without your explicit permission.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Close".tr()),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  "Privacy Policy".tr(),
                  style: const TextStyle(color: Colors.blue, fontSize: 15),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required String count,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            if (count.isNotEmpty)
              Text(
                count,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
