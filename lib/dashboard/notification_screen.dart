import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/dashboard/bottom_nav.dart';
import 'package:nutriapp/meal_log/meal_log_switch.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/me/app_preferences_page.dart';
import 'package:nutriapp/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nutriapp/subscription/subscription_screen.dart';

class NotificationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const NotificationScreen({
    super.key,
    required this.cameras,
    required this.yolo,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService.instance;
  String _selectedFilter = 'all';
  bool _hasSystemPermission = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _service.checkPermissionStatus();
    if (mounted) {
      setState(() {
        _hasSystemPermission = granted;
      });
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<NotificationItem> get _filteredNotifications {
    final all = _service.notifications;
    if (_selectedFilter == 'all') return all;
    return all.where((n) => n.category == _selectedFilter).toList();
  }

  void _handleNotificationTap(NotificationItem notif) {
    if (!notif.isRead) {
      _service.markAsRead(notif.id);
    }
    _showNotificationDetailsSheet(notif);
  }

  void _showNotificationDetailsSheet(NotificationItem notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09B84F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notif.category.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09B84F),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  notif.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              notif.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              notif.message,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (notif.actionRoute != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateToAction(notif.actionRoute!);
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(_getActionLabel(notif.actionRoute!)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09B84F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton(
                  tooltip: "Delete alert",
                  onPressed: () {
                    Navigator.pop(ctx);
                    _service.deleteNotification(notif.id);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAction(String route) {
    switch (route) {
      case 'premium':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(),
          ),
        );
        break;
      case 'meal':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MealLogSwitchPage(
              selectedDate: DateTime.now(),
              cameras: widget.cameras,
              yolo: widget.yolo,
            ),
          ),
        );
        break;
      case 'water':
      case 'macros':
      default:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                BottomNav(cameras: widget.cameras, yolo: widget.yolo),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;
    final unread = _service.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Notifications & Alerts",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (unread > 0)
              Text(
                "$unread unread alert${unread > 1 ? 's' : ''}",
                style: const TextStyle(
                  color: Color(0xFF09B84F),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      BottomNav(cameras: widget.cameras, yolo: widget.yolo),
                ),
              );
            }
          },
        ),
        actions: [
          // Dismiss All button directly in the AppBar
          if (unread > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF09B84F)),
              label: const Text(
                "Dismiss All",
                style: TextStyle(
                  color: Color(0xFF09B84F),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                _service.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications marked as read"),
                    duration: Duration(milliseconds: 900),
                    backgroundColor: Color(0xFF09B84F),
                  ),
                );
              },
            ),
          // Quick link to notification mute/unmute preferences
          IconButton(
            tooltip: "Notification Mute Controls",
            icon: const Icon(Icons.tune_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppPreferencesPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              if (value == 'read_all') {
                _service.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications marked as read"),
                    duration: Duration(milliseconds: 900),
                    backgroundColor: Color(0xFF09B84F),
                  ),
                );
              } else if (value == 'simulate') {
                final alert = _service.generateRandomAlert(
                    showPopup: false, showSystemNotification: true);
                if (alert != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Generated: ${alert.title}"),
                      duration: const Duration(milliseconds: 1000),
                      backgroundColor: const Color(0xFF09B84F),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Notifications are currently muted in Preferences"),
                    ),
                  );
                }
              } else if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 18, color: Color(0xFF09B84F)),
                    SizedBox(width: 10),
                    Text("Mark all as read"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate',
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 18, color: Colors.amber),
                    SizedBox(width: 10),
                    Text("Simulate Live Alert"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Clear All"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // System notification permission warning banner if permission is not granted
          if (!_hasSystemPermission)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.amber.shade900, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "External status-bar notifications are disabled in Android settings.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await openAppSettings();
                      await _checkPermission();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Enable",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Tabs
          _buildFilterTabs(),

          // Sub-header bar with Dismiss All & Clear All quick buttons
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unread > 0
                        ? "$unread unread alert${unread > 1 ? 's' : ''}"
                        : "All alerts read",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: unread > 0
                          ? const Color(0xFF09B84F)
                          : Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      if (unread > 0)
                        InkWell(
                          onTap: () {
                            _service.markAllAsRead();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("All notifications marked as read"),
                                duration: Duration(milliseconds: 800),
                                backgroundColor: Color(0xFF09B84F),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF09B84F)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.done_all,
                                    size: 13, color: Color(0xFF09B84F)),
                                SizedBox(width: 4),
                                Text(
                                  "Dismiss All",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF09B84F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          _service.generateRandomAlert(
                            showPopup: false,
                            showSystemNotification: true,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Triggered immediate test notification!"),
                              duration: Duration(milliseconds: 800),
                              backgroundColor: Color(0xFF09B84F),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 13, color: Colors.blue),
                              SizedBox(width: 3),
                              Text(
                                "Test Alert",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showClearAllDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_sweep_outlined,
                                  size: 13, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                "Clear All",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Main list or empty state
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildDismissibleCard(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'desi_swaps', 'label': '🍛 Desi Swaps'},
      {'key': 'fasting', 'label': '⏳ Fasting'},
      {'key': 'glucose_crash', 'label': '👟 Glucose'},
      {'key': 'workout_fuel', 'label': '🏋️ Workout'},
      {'key': 'mindset', 'label': '🧠 Mindset'},
      {'key': 'gut_health', 'label': '🌱 Gut Health'},
      {'key': 'water', 'label': '💧 Water'},
      {'key': 'meal', 'label': '🍳 Meals'},
      {'key': 'nutrition', 'label': '🥗 Nutrition'},
      {'key': 'mineral', 'label': '🥬 Minerals'},
      {'key': 'premium', 'label': '⭐ Premium'},
      {'key': 'streak', 'label': '🔥 Streaks'},
    ];

    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSelected = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = f['key']!;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF09B84F) : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissibleCard(NotificationItem notif) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        _service.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification dismissed"),
            duration: Duration(milliseconds: 700),
          ),
        );
      },
      child: _buildNotificationCard(notif),
    );
  }

  Widget _buildNotificationCard(NotificationItem notif) {
    IconData icon;
    Color color;

    switch (notif.category) {
      case 'desi_swaps':
        icon = Icons.restaurant_menu;
        color = Colors.amber.shade900;
        break;
      case 'fasting':
        icon = Icons.hourglass_bottom;
        color = Colors.deepPurple;
        break;
      case 'glucose_crash':
        icon = Icons.directions_walk;
        color = Colors.indigo;
        break;
      case 'workout_fuel':
        icon = Icons.fitness_center;
        color = Colors.red.shade700;
        break;
      case 'mindset':
        icon = Icons.psychology;
        color = Colors.pink.shade600;
        break;
      case 'gut_health':
        icon = Icons.spa;
        color = Colors.teal.shade700;
        break;
      case 'water':
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'meal':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'nutrition':
        icon = Icons.pie_chart;
        color = Colors.teal;
        break;
      case 'mineral':
        icon = Icons.biotech;
        color = Colors.purple;
        break;
      case 'premium':
        icon = Icons.stars;
        color = Colors.amber.shade800;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.deepOrange;
        break;
      default:
        icon = Icons.notifications_active;
        color = const Color(0xFF09B84F);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : const Color(0xFFF1FAF4),
        borderRadius: BorderRadius.circular(14),
        border: notif.isRead
            ? Border.all(color: Colors.grey.shade200)
            : Border.all(color: const Color(0xFF09B84F).withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: notif.isRead ? 0.03 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleNotificationTap(notif),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Text(
                            notif.timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notif.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (notif.actionRoute != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _getActionLabel(notif.actionRoute!),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 10, color: color),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!notif.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF09B84F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getActionLabel(String route) {
    switch (route) {
      case 'premium':
        return "Upgrade Now";
      case 'meal':
        return "Log Food";
      case 'water':
        return "Log Water";
      case 'macros':
        return "View Nutrition";
      case 'fasting':
        return "Check Window";
      default:
        return "View Details";
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF09B84F).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 48,
                color: Color(0xFF09B84F),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Alerts Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? "You're all caught up! New dynamic alerts will arrive throughout your 24h health journey."
                  : "No notifications currently for this category.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                _service.generateRandomAlert(
                    showPopup: false, showSystemNotification: true);
              },
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text("Simulate Live Alert"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09B84F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear all notifications?"),
        content: const Text(
          "This will delete all saved alerts and reset your notification list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}
