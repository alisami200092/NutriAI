import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nutriapp/chatbot/chatbot_screen.dart';
import 'package:nutriapp/dashboard/dashboard_screen.dart';
import 'package:nutriapp/dashboard/notification_screen.dart';
import 'package:nutriapp/me/me_page.dart';
import 'package:nutriapp/meal_log/meal_log_switch.dart';
import 'package:nutriapp/meal_log/yolo_service.dart';
import 'package:nutriapp/services/notification_service.dart';

class BottomNav extends StatefulWidget {
  final List<CameraDescription> cameras;
  final YoloService yolo;

  const BottomNav({super.key, required this.cameras, required this.yolo});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 1; // Dashboard is default
  int _notificationCount = 0; // Dynamic count of unread notifications

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _notificationCount = NotificationService.instance.unreadCount;
    NotificationService.instance.addListener(_syncNotificationCount);
    NotificationService.instance.latestAlertNotifier
        .addListener(_showInAppAlert);

    // Initialize pages with the required cameras + yolo
    _pages = [
      const ChatbotPage(), // Index 0

      DashboardScreen(cameras: widget.cameras, yolo: widget.yolo), // Index 1

      MealLogSwitchPage(
        selectedDate: DateTime.now(),
        cameras: widget.cameras,
        yolo: widget.yolo,
      ), // Index 2
      NotificationScreen(cameras: widget.cameras, yolo: widget.yolo), // Index 3

      MePage(cameras: widget.cameras, yolo: widget.yolo), // Index 4
    ];

    // Request Android 13/14 notification permissions when Activity is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestNotificationPermission();
    });
  }

  void _syncNotificationCount() {
    if (mounted) {
      setState(() {
        _notificationCount = NotificationService.instance.unreadCount;
      });
    }
  }

  void _showInAppAlert() {
    final alert = NotificationService.instance.latestAlertNotifier.value;
    if (alert != null && mounted && _selectedIndex != 3) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
          content: Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: Color(0xFF09B84F), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white),
                    ),
                    Text(
                      alert.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "VIEW".tr(),
            textColor: const Color(0xFF09B84F),
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_syncNotificationCount);
    NotificationService.instance.latestAlertNotifier
        .removeListener(_showInAppAlert);
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      debugPrint("Invalid tab index: $index");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF37C97D),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: "Chatbot".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            label: "Dashboard".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_dining_outlined),
            label: "Log Food".tr(),
          ),
          // ✅ NEW: Notification Item with Badge
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _notificationCount > 0, // Hide if 0
              label: Text('$_notificationCount'), // The small count thing
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: const Icon(Icons.notifications_outlined),
            ),
            label: "Alerts".tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: "Me".tr(),
          ),
        ],
      ),
    );
  }
}
