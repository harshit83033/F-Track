import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int workouts = 0;
  int minutes = 0;
  int workoutCalories = 0;
  int foodCalories = 0;

  double? weight;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userEmail = prefs.getString('user_email');

      if (userEmail == null || userEmail.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage('User email not found. Please login again.');
        return;
      }

      final encodedEmail = Uri.encodeComponent(userEmail);

      final responses = await Future.wait([
        http.get(
          Uri.parse(
            'https://f-track-backend.onrender.com/workouts/$encodedEmail',
          ),
        ),
        http.get(
          Uri.parse(
            'https://f-track-backend.onrender.com/nutrition/$encodedEmail',
          ),
        ),
        http.get(
          Uri.parse(
            'https://f-track-backend.onrender.com/weight/$encodedEmail',
          ),
        ),
      ]);

      final workoutResponse = responses[0];
      final nutritionResponse = responses[1];
      final weightResponse = responses[2];

      int totalWorkouts = 0;
      int totalMinutes = 0;
      int totalWorkoutCalories = 0;
      int totalFoodCalories = 0;
      double? latestWeight;

      if (workoutResponse.statusCode == 200) {
        final data = jsonDecode(workoutResponse.body);

        final List<dynamic> workoutList =
            data['workouts'] ?? [];

        totalWorkouts = workoutList.length;

        for (final workout in workoutList) {
          totalMinutes +=
              ((workout['duration'] ?? 0) as num).toInt();

          totalWorkoutCalories +=
              ((workout['calories'] ?? 0) as num).toInt();
        }
      }

      if (nutritionResponse.statusCode == 200) {
        final data = jsonDecode(nutritionResponse.body);

        final List<dynamic> nutritionList =
            data['nutrition'] ?? [];

        for (final meal in nutritionList) {
          totalFoodCalories +=
              ((meal['calories'] ?? 0) as num).toInt();
        }
      }

      if (weightResponse.statusCode == 200) {
        final data = jsonDecode(weightResponse.body);

        final List<dynamic> weightList =
            data['weights'] ?? [];

        if (weightList.isNotEmpty) {
          latestWeight =
              (weightList.first['weight'] as num).toDouble();
        }
      }

      if (!mounted) return;

      setState(() {
        workouts = totalWorkouts;
        minutes = totalMinutes;
        workoutCalories = totalWorkoutCalories;
        foodCalories = totalFoodCalories;
        weight = latestWeight;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load progress data.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _card(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Progress',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF9F1FC),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadProgress,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep going and reach your fitness goals.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _card(
                      Icons.fitness_center,
                      'Total Workouts',
                      '$workouts',
                    ),

                    _card(
                      Icons.timer,
                      'Workout Minutes',
                      '$minutes min',
                    ),

                    _card(
                      Icons.local_fire_department,
                      'Calories Burned',
                      '$workoutCalories kcal',
                    ),

                    _card(
                      Icons.restaurant,
                      'Food Calories',
                      '$foodCalories kcal',
                    ),

                    _card(
                      Icons.monitor_weight,
                      'Current Weight',
                      weight == null
                          ? '-- kg'
                          : '${weight!.toStringAsFixed(1)} kg',
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F1FA),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 45,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Keep Moving!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            workouts == 0
                                ? 'Start your first workout today.'
                                : 'Great job! Keep building your fitness routine.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
