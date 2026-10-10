import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_screen.dart';
import 'nutrition_screen.dart';
import 'weight_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({
    super.key,
    this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';

  int _workouts = 0;
  int _minutes = 0;
  int _workoutCalories = 0;
  int _nutritionCalories = 0;

  double? _weight;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String name = widget.userName ?? '';

      if (name.isEmpty) {
        name = prefs.getString('user_name') ?? '';
      }

      if (name.isEmpty) {
        name = prefs.getString('name') ?? '';
      }

      final userEmail = prefs.getString('user_email');

      double? latestWeight;

      // Fetch latest weight from MongoDB
      if (userEmail != null && userEmail.isNotEmpty) {
        final encodedEmail = Uri.encodeComponent(userEmail);

        final response = await http.get(
          Uri.parse(
            'http://localhost:5000/weight/$encodedEmail',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final List<dynamic> weightList =
              data['weights'] ?? [];

          if (weightList.isNotEmpty) {
            latestWeight =
                (weightList.first['weight'] as num).toDouble();
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = name.isEmpty ? 'User' : name;

        _workouts = prefs.getInt('workout_count') ?? 0;
        _minutes = prefs.getInt('workout_minutes') ?? 0;
        _workoutCalories =
            prefs.getInt('workout_calories') ?? 0;
        _nutritionCalories =
            prefs.getInt('nutrition_calories') ?? 0;

        _weight = latestWeight;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _userName =
            widget.userName ??
            prefs.getString('user_name') ??
            prefs.getString('name') ??
            'User';

        _workouts =
            prefs.getInt('workout_count') ?? 0;

        _minutes =
            prefs.getInt('workout_minutes') ?? 0;

        _workoutCalories =
            prefs.getInt('workout_calories') ?? 0;

        _nutritionCalories =
            prefs.getInt('nutrition_calories') ?? 0;

        _isLoading = false;
      });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    await _loadData();
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        height: 150,
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEDE2F2),
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                size: 24,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: action,
        child: Container(
          height: 150,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F1FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEDE2F2),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBanner() {
    String message;

    if (_workouts == 0) {
      message =
          'Start your first workout and begin your fitness journey.';
    } else if (_workouts < 3) {
      message =
          'Great start! Keep building your fitness routine.';
    } else if (_workouts < 7) {
      message =
          'You are doing great! Stay consistent and keep going.';
    } else {
      message =
          'Excellent work! Your consistency is paying off.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDE2F2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep Moving!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.4,
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
          'F-Track',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF9F1FC),
        elevation: 0,

        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadData,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () =>
                _open(const ProfileScreen()),
            tooltip: 'Profile',
            icon: const Icon(
              Icons.person_outline,
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
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  25,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // Welcome section
                    Text(
                      'Hello, $_userName! 👋',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Welcome back to your fitness journey.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Today's Activity
                    const Text(
                      "Today's Activity",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _statCard(
                          Icons.fitness_center,
                          '$_workouts',
                          'Workouts',
                        ),
                        _statCard(
                          Icons.timer,
                          '$_minutes',
                          'Minutes',
                        ),
                        _statCard(
                          Icons.local_fire_department,
                          '$_workoutCalories',
                          'Calories',
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        _statCard(
                          Icons.restaurant,
                          '$_nutritionCalories',
                          'Food kcal',
                        ),
                        _statCard(
                          Icons.monitor_weight,
                          _weight == null
                              ? '--'
                              : _weight!
                                  .toStringAsFixed(1),
                          'Weight kg',
                        ),
                        _statCard(
                          Icons.favorite,
                          'Active',
                          'Status',
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Progress banner
                    _progressBanner(),

                    const SizedBox(height: 28),

                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _actionCard(
                          Icons.fitness_center,
                          'Workout',
                          'Track exercise',
                          () => _open(
                            const WorkoutScreen(),
                          ),
                        ),
                        _actionCard(
                          Icons.restaurant,
                          'Nutrition',
                          'Track meals',
                          () => _open(
                            const NutritionScreen(),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        _actionCard(
                          Icons.monitor_weight,
                          'Weight',
                          'Track weight',
                          () => _open(
                            const WeightScreen(),
                          ),
                        ),
                        _actionCard(
                          Icons.bar_chart,
                          'Progress',
                          'View progress',
                          () => _open(
                            const ProgressScreen(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Footer message
                    Center(
                      child: Text(
                        'Stay consistent. Stay healthy. 💪',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
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