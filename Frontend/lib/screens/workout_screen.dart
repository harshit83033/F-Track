import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final TextEditingController _exerciseController =
      TextEditingController();

  final TextEditingController _durationController =
      TextEditingController();

  final TextEditingController _caloriesController =
      TextEditingController();

  String _selectedWorkout = 'Strength Training';

  int _totalWorkouts = 0;
  int _totalMinutes = 0;
  int _totalCalories = 0;

  List<Map<String, dynamic>> _workouts = [];

  bool _isLoading = false;
  bool _isSaving = false;

  static const String baseUrl = 'https://f-track-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  // ============================================================
  // GET USER EMAIL
  // ============================================================

  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('user_email') ??
        prefs.getString('email') ??
        prefs.getString('saved_email') ??
        '';
  }

  // ============================================================
  // LOAD WORKOUTS FROM MONGODB
  // ============================================================

  Future<void> _loadWorkoutData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = await _getUserEmail();

      if (userEmail.isEmpty) {
        if (!mounted) return;

        setState(() {
          _workouts = [];
          _totalWorkouts = 0;
          _totalMinutes = 0;
          _totalCalories = 0;
          _isLoading = false;
        });

        _showMessage('User email not found. Please login again.');
        return;
      }

      final encodedEmail = Uri.encodeComponent(userEmail);

      final response = await http.get(
        Uri.parse('$baseUrl/workouts/$encodedEmail'),
      );

      if (response.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showMessage('Failed to load workout history.');
        return;
      }

      final responseData = jsonDecode(response.body);

      final List<dynamic> workoutList =
          responseData['workouts'] ?? [];

      final loadedWorkouts = workoutList
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();

      int totalMinutes = 0;
      int totalCalories = 0;

      for (final workout in loadedWorkouts) {
        totalMinutes +=
            (workout['duration'] as num?)?.toInt() ?? 0;

        totalCalories +=
            (workout['calories'] as num?)?.toInt() ?? 0;
      }

      // Keep SharedPreferences updated for the dashboard.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        'workout_count',
        loadedWorkouts.length,
      );

      await prefs.setInt(
        'workout_minutes',
        totalMinutes,
      );

      await prefs.setInt(
        'workout_calories',
        totalCalories,
      );

      await prefs.setInt(
        'minutes',
        totalMinutes,
      );

      await prefs.setInt(
        'calories',
        totalCalories,
      );

      if (!mounted) return;

      setState(() {
        _workouts = loadedWorkouts;
        _totalWorkouts = loadedWorkouts.length;
        _totalMinutes = totalMinutes;
        _totalCalories = totalCalories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load workout error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Backend connection failed while loading workouts.',
      );
    }
  }

  // ============================================================
  // SAVE WORKOUT TO MONGODB
  // ============================================================

  Future<void> _saveWorkout() async {
    if (_isSaving) return;

    final exercise = _exerciseController.text.trim();

    final duration = int.tryParse(
      _durationController.text.trim(),
    );

    final calories = int.tryParse(
      _caloriesController.text.trim(),
    );

    if (exercise.isEmpty) {
      _showMessage('Please enter an exercise name.');
      return;
    }

    if (duration == null || duration <= 0) {
      _showMessage('Please enter a valid duration.');
      return;
    }

    if (calories == null || calories < 0) {
      _showMessage('Please enter valid calories.');
      return;
    }

    final userEmail = await _getUserEmail();

    if (userEmail.isEmpty) {
      _showMessage('User email not found. Please login again.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final workout = <String, dynamic>{
      'userEmail': userEmail,
      'type': _selectedWorkout,
      'exercise': exercise,
      'duration': duration,
      'calories': calories,
      'date': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workouts'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(workout),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        _showMessage('Failed to save workout to database.');
        return;
      }

      final responseData = jsonDecode(response.body);

      final savedWorkout = responseData['workout'];

      if (savedWorkout is Map) {
        final newWorkout =
            Map<String, dynamic>.from(savedWorkout);

        setState(() {
          _workouts.insert(0, newWorkout);
          _totalWorkouts = _workouts.length;
          _totalMinutes += duration;
          _totalCalories += calories;
        });
      } else {
        await _loadWorkoutData();
      }

      // Keep dashboard values updated.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        'workout_count',
        _totalWorkouts,
      );

      await prefs.setInt(
        'workout_minutes',
        _totalMinutes,
      );

      await prefs.setInt(
        'workout_calories',
        _totalCalories,
      );

      await prefs.setInt(
        'minutes',
        _totalMinutes,
      );

      await prefs.setInt(
        'calories',
        _totalCalories,
      );

      _exerciseController.clear();
      _durationController.clear();
      _caloriesController.clear();

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Workout saved successfully!');
    } catch (e) {
      debugPrint('Save workout error: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Backend connection failed.');
    }
  }

  // ============================================================
  // DELETE WORKOUT FROM MONGODB
  // ============================================================

  Future<void> _deleteWorkout(int index) async {
    if (index < 0 || index >= _workouts.length) {
      return;
    }

    final workout = _workouts[index];

    final workoutId = workout['_id']?.toString();

    if (workoutId == null || workoutId.isEmpty) {
      _showMessage('Workout ID not found.');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/workouts/$workoutId'),
      );

      if (response.statusCode != 200) {
        _showMessage('Failed to delete workout.');
        return;
      }

      await _loadWorkoutData();

      _showMessage('Workout deleted successfully!');
    } catch (e) {
      debugPrint('Delete workout error: $e');

      _showMessage(
        'Backend connection failed while deleting workout.',
      );
    }
  }

  // ============================================================
  // CLEAR ALL WORKOUTS
  // ============================================================

  Future<void> _clearAllWorkouts() async {
    if (_workouts.isEmpty) {
      _showMessage('There is no workout history.');
      return;
    }

    try {
      // Delete every MongoDB workout one by one.
      for (final workout in _workouts) {
        final workoutId = workout['_id']?.toString();

        if (workoutId == null || workoutId.isEmpty) {
          continue;
        }

        await http.delete(
          Uri.parse('$baseUrl/workouts/$workoutId'),
        );
      }

      await _loadWorkoutData();

      _showMessage('Workout history cleared successfully!');
    } catch (e) {
      debugPrint('Clear workout error: $e');

      _showMessage(
        'Backend connection failed while clearing history.',
      );
    }
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Workout?'),
          content: const Text(
            'Do you want to remove this workout from your history?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteWorkout(index);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CONFIRM CLEAR ALL
  // ============================================================

  void _confirmClearAll() {
    if (_workouts.isEmpty) {
      _showMessage('There is no workout history.');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text(
            'This will permanently delete all workout history from the database.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _clearAllWorkouts();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '';
    }

    try {
      final parsedDate = DateTime.parse(date);

      final day =
          parsedDate.day.toString().padLeft(2, '0');

      final month =
          parsedDate.month.toString().padLeft(2, '0');

      final year =
          parsedDate.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F1FA),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: Colors.black87,
            ),
            const SizedBox(height: 9),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WORKOUT HISTORY CARD
  // ============================================================

  Widget _workoutHistoryCard(
    Map<String, dynamic> workout,
    int index,
  ) {
    final type =
        workout['type']?.toString() ?? 'Workout';

    final exercise =
        workout['exercise']?.toString() ?? 'Exercise';

    final duration =
        (workout['duration'] as num?)?.toInt() ?? 0;

    final calories =
        (workout['calories'] as num?)?.toInt() ?? 0;

    final date = _formatDate(
      workout['date']?.toString(),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            child: const Icon(
              Icons.fitness_center,
              size: 28,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  exercise,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text('$duration min'),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.local_fire_department,
                      size: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text('$calories kcal'),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _exerciseController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F1FC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Workout Tracker',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadWorkoutData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWorkoutData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Your Workout',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Record your exercises and keep improving.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Workout Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    _summaryCard(
                      icon: Icons.fitness_center,
                      title: 'Workouts',
                      value: '$_totalWorkouts',
                    ),
                    _summaryCard(
                      icon: Icons.timer,
                      title: 'Minutes',
                      value: '$_totalMinutes',
                    ),
                    _summaryCard(
                      icon: Icons.local_fire_department,
                      title: 'Calories',
                      value: '$_totalCalories',
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  'Add Workout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  initialValue: _selectedWorkout,
                  decoration: InputDecoration(
                    labelText: 'Workout Type',
                    prefixIcon:
                        const Icon(Icons.fitness_center),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Strength Training',
                      child: Text('Strength Training'),
                    ),
                    DropdownMenuItem(
                      value: 'Cardio',
                      child: Text('Cardio'),
                    ),
                    DropdownMenuItem(
                      value: 'Running',
                      child: Text('Running'),
                    ),
                    DropdownMenuItem(
                      value: 'Cycling',
                      child: Text('Cycling'),
                    ),
                    DropdownMenuItem(
                      value: 'Yoga',
                      child: Text('Yoga'),
                    ),
                    DropdownMenuItem(
                      value: 'Walking',
                      child: Text('Walking'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedWorkout = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _exerciseController,
                  decoration: InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'Example: Push Ups',
                    prefixIcon:
                        const Icon(Icons.sports_gymnastics),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    hintText: 'Example: 30',
                    prefixIcon:
                        const Icon(Icons.timer),
                    suffixText: 'min',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Calories Burned',
                    hintText: 'Example: 250',
                    prefixIcon: const Icon(
                      Icons.local_fire_department,
                    ),
                    suffixText: 'kcal',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSaving ? null : _saveWorkout,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.add,
                            color: Color(0xFF6D4BA8),
                          ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Add Workout',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4BA8),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF0E5FA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workout History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_workouts.isNotEmpty)
                      TextButton(
                        onPressed:
                            _confirmClearAll,
                        child: const Text(
                          'Clear All',
                          style:
                              TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_isLoading)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF8F1FA),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text(
                          'Loading workout history...',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_workouts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF8F1FA),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No workouts yet',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add your first workout above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(
                    _workouts.length,
                    (index) =>
                        _workoutHistoryCard(
                      _workouts[index],
                      index,
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}