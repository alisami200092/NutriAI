import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'exercise_entry_page.dart';

class ActivitySearchPage extends StatefulWidget {
  const ActivitySearchPage({super.key});

  @override
  State<ActivitySearchPage> createState() => _ActivitySearchPageState();
}

class _ActivitySearchPageState extends State<ActivitySearchPage> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  String _getDateText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selected == today) {
      return "Today".tr();
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return "Yesterday".tr();
    } else if (selected == today.add(const Duration(days: 1))) {
      return "Tomorrow".tr();
    } else {
      return DateFormat('EEE, d MMM').format(_selectedDate);
    }
  }

  // --- HELPER: SMART EMOJI PICKER ---
  // This fixes the "Flexed Biceps everywhere" issue.
  // If DB has no emoji, we pick one based on the name.
  String _getSmartEmoji(String name, String? dbEmoji) {
    // 1. If DB has a specific emoji (not null and not empty), use it.
    if (dbEmoji != null && dbEmoji.isNotEmpty && dbEmoji != '💪') {
      return dbEmoji;
    }

    // 2. Otherwise, look at keywords in the name
    final lowerName = name.toLowerCase();
    if (lowerName.contains('run') || lowerName.contains('jog')) return '🏃‍♂️';
    if (lowerName.contains('walk') || lowerName.contains('hike')) {
      return '🚶‍♂️';
    }
    if (lowerName.contains('cycle') || lowerName.contains('bike')) return '🚴';
    if (lowerName.contains('swim')) return '🏊';
    if (lowerName.contains('yoga') || lowerName.contains('meditat')) {
      return '🧘‍♀️';
    }
    if (lowerName.contains('weight') ||
        lowerName.contains('lift') ||
        lowerName.contains('gym')) {
      return '🏋️‍♂️';
    }
    if (lowerName.contains('jump') || lowerName.contains('jack')) return '🤸';
    if (lowerName.contains('skip') || lowerName.contains('rope')) return '🪢';
    if (lowerName.contains('box') || lowerName.contains('fight')) return '🥊';
    if (lowerName.contains('dance') || lowerName.contains('zumba')) return '💃';
    if (lowerName.contains('basketball')) return '🏀';
    if (lowerName.contains('football') || lowerName.contains('soccer')) {
      return '⚽';
    }
    if (lowerName.contains('tennis') || lowerName.contains('badminton')) {
      return '🎾';
    }
    if (lowerName.contains('pilates')) return '🧘';

    // 3. Fallback if no keyword matches
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBarRow(),
                  const SizedBox(height: 25),

                  // Recent Activities (Hide if searching)
                  if (_searchQuery.isEmpty) ...[
                    Text(
                      "Recent Activities".tr(),
                      style: const TextStyle(
                        color: Color(0xFF1B3A33),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRecentActivitiesRow(),
                    const SizedBox(height: 25),
                  ],

                  // Exercise Catalog Title
                  Text(
                    _searchQuery.isEmpty
                        ? "Exercise Catalog".tr()
                        : "Search Results".tr(),
                    style: const TextStyle(
                      color: Color(0xFF1B3A33),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Dynamic Grid
                  _buildDynamicCatalogGrid(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCatalogGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ActivityPlan').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF37C97D)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No exercises in catalog.".tr()));
        }

        // Search Filter
        final allDocs = snapshot.data!.docs;
        final filteredExercises = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['exerciseName'] ?? '').toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query);
        }).toList();

        if (filteredExercises.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("No matching exercises found.".tr()),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: filteredExercises.length,
          itemBuilder: (context, index) {
            final data =
                filteredExercises[index].data() as Map<String, dynamic>;

            String name = data['exerciseName'] ?? 'Exercise';
            String? dbEmoji = data['emoji'];
            int calsPerMin = (data['caloriesPerMinute'] as num?)?.toInt() ?? 5;

            // UPDATED: Use the smart helper
            String finalEmoji = _getSmartEmoji(name, dbEmoji);

            Color cardColor = _getCategoryColor(index);

            return _buildCatalogCard(
              name,
              cardColor,
              finalEmoji, // Pass the smart emoji
              null,
              calsPerMin,
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogCard(
    String name,
    Color color,
    String emoji,
    IconData? badgeIcon,
    int calsPerMin,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseEntryPage(
              exerciseName: name,
              emoji: emoji,
              baseCaloriesPerMinute: calsPerMin,
              initialDate: _selectedDate,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (badgeIcon != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Color(0xFF81C784), // Green
      Color(0xFF64B5F6), // Blue
      Color(0xFFFFB74D), // Orange
      Color(0xFF9575CD), // Purple
      Color(0xFFFF8A65), // Red-Orange
      Color(0xFF4DB6AC), // Teal
    ];
    return colors[index % colors.length];
  }

  Widget _buildCustomHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 10,
        right: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF37C97D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Activity Log".tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDateText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Find or Log Exercise".tr(),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseEntryPage(
                  exerciseName: "Custom Workout".tr(),
                  emoji: "✨",
                  baseCaloriesPerMinute: 5,
                  initialDate: _selectedDate,
                ),
              ),
            );
          },
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF7BC468), Color(0xFF4FA87F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: const [
                Text(
                  "Log Custom",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 5),
                Icon(Icons.edit, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Static Recent Activities
  Widget _buildRecentActivitiesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildRecentCard(
            "Morning Run - 30 min",
            Icons.directions_run,
            "🏃‍♂️",
            11,
          ),
          const SizedBox(width: 10),
          _buildRecentCard(
            "Weightlifting - 40 min",
            Icons.fitness_center,
            "🏋️‍♂️",
            5,
          ),
          const SizedBox(width: 10),
          _buildRecentCard(
            "Yoga Flow - 20 min",
            Icons.self_improvement,
            "🧘‍♀️",
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard(
    String text,
    IconData icon,
    String emoji,
    int calsPerMin,
  ) {
    final parts = text.split(' - ');
    final title = parts[0];
    final sub = parts.length > 1 ? parts[1] : '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseEntryPage(
              exerciseName: title,
              emoji: emoji,
              baseCaloriesPerMinute: calsPerMin,
              initialDate: _selectedDate,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF88C96C), Color(0xFF3B9E83)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}
