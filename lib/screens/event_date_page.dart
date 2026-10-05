import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'activity_level_page.dart';

class EventDatePage extends StatefulWidget {
  final String selectedEvent;
  final Function(DateTime) onDateSelected;
  final double weightKg;
  final double heightCm;
  final int age;
  final String gender;
  final double targetWeight;
  final String dietaryGoal;

  const EventDatePage(
    this.weightKg,
    this.heightCm,
    this.age,
    this.gender,
    this.targetWeight,
    this.dietaryGoal, {
    super.key,
    required this.selectedEvent,
    required this.onDateSelected,
  });

  @override
  State<EventDatePage> createState() => _EventDatePageState();
}

class _EventDatePageState extends State<EventDatePage> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  final List<int> days = List.generate(31, (index) => index + 1);
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<int> years = List.generate(
    60,
    (index) => DateTime.now().year - 10 + index,
  );

  String get displayQuestion {
    return widget.selectedEvent == "No"
        ? "When do you want to reach your goal?"
        : "When will this event take place?";
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = now.day;
    selectedMonth = now.month - 1;
    selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final pickedDate = DateTime(
      selectedYear,
      selectedMonth + 1,
      selectedDay.clamp(1, DateTime(selectedYear, selectedMonth + 1, 0).day),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Lottie.asset(
                "assets/animations/robot-working.json",
                width: 140,
                height: 140,
              ),
              const SizedBox(height: 16),
              Image.asset(
                "assets/images/event_date.png",
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 16),
              Text(
                displayQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Date picker with blue border
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: CupertinoPicker(
                              backgroundColor: Colors.transparent,
                              scrollController: FixedExtentScrollController(
                                initialItem: selectedDay - 1,
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedDay = days[index];
                                });
                              },
                              children: days
                                  .map(
                                    (day) =>
                                        Center(child: Text(day.toString())),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: CupertinoPicker(
                              backgroundColor: Colors.transparent,
                              scrollController: FixedExtentScrollController(
                                initialItem: selectedMonth,
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedMonth = index;
                                  selectedDay = selectedDay.clamp(
                                    1,
                                    DateTime(
                                      selectedYear,
                                      selectedMonth + 1,
                                      0,
                                    ).day,
                                  );
                                });
                              },
                              children: months
                                  .map((m) => Center(child: Text(m)))
                                  .toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: CupertinoPicker(
                              backgroundColor: Colors.transparent,
                              scrollController: FixedExtentScrollController(
                                initialItem: years.indexOf(selectedYear),
                              ),
                              itemExtent: 40,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedYear = years[index];
                                  selectedDay = selectedDay.clamp(
                                    1,
                                    DateTime(
                                      selectedYear,
                                      selectedMonth + 1,
                                      0,
                                    ).day,
                                  );
                                });
                              },
                              children: years
                                  .map(
                                    (year) =>
                                        Center(child: Text(year.toString())),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Blue outline (IgnorePointer allows scrolling underneath)
                  Positioned(
                    top: 55,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  widget.onDateSelected(pickedDate);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLevelPage(
                        weightKg: widget.weightKg,
                        heightCm: widget.heightCm,
                        age: widget.age,
                        gender: widget.gender,
                        targetWeight: widget.targetWeight,
                        dietaryGoal: widget.dietaryGoal,
                        eventName: widget.selectedEvent,
                        eventDate: pickedDate,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
