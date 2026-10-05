import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nutriapp/screens/event_date_page.dart';

class EventsPage extends StatefulWidget {
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender;
  final double targetWeight;
  final String dietaryGoal;

  const EventsPage(
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
    this.targetWeight,
    this.dietaryGoal, {
    super.key,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String? selectedEvent;

  final List<Map<String, String>> eventOptions = [
    {'emoji': '🏝️', 'label': 'Vacation'},
    {'emoji': '💍', 'label': 'Wedding'},
    {'emoji': '🏅', 'label': 'Competition'},
    {'emoji': '🧑‍🤝‍🧑', 'label': 'Reunion'},
    {'emoji': '🎂', 'label': 'Birthday'},
    {'emoji': '🗓️', 'label': 'Other Event'},
    {'emoji': '❌', 'label': 'No'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              Image.asset(
                "assets/images/event_symbol.png",
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.event, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                "Do you have a specific event that's motivating you to get in shape?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Event selection list
              Column(
                children: eventOptions.map((event) {
                  final isSelected = selectedEvent == event['label'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEvent = event['label'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                            right: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              event['emoji']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              event['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.green
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Continue button
              ElevatedButton.icon(
                onPressed: selectedEvent != null
                    ? () {
                        debugPrint("Selected Event: $selectedEvent");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDatePage(
                              widget.weightKg,
                              widget.heightCm,
                              widget.age,
                              widget.gender,
                              widget.targetWeight,
                              widget.dietaryGoal,
                              selectedEvent: selectedEvent!, // ✅ pass this
                              onDateSelected: (pickedDate) {
                                // Handle the selected date or just navigate forward if handled inside EventDatePage
                                debugPrint("Date selected: $pickedDate");
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
