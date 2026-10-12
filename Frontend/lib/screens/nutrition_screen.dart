import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _foodController =
      TextEditingController();

  final TextEditingController _calorieController =
      TextEditingController();

  String _mealType = 'Breakfast';

  List<Map<String, dynamic>> _foods = [];

  int _totalCalories = 0;

  bool _isLoading = false;

  final String baseUrl = 'https://f-track-backend.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  // ==========================================
  // GET USER EMAIL
  // ==========================================

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('user_email') ??
        prefs.getString('email') ??
        prefs.getString('saved_email');
  }

  // ==========================================
  // LOAD NUTRITION FROM MONGODB
  // ==========================================

  Future<void> _loadFoods() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final email = await _getUserEmail();

      if (email == null || email.isEmpty) {
        _message('User email not found. Please login again.');
        return;
      }

      final encodedEmail = Uri.encodeComponent(email);

      final response = await http.get(
        Uri.parse(
          '$baseUrl/nutrition/$encodedEmail',
        ),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final List<dynamic> nutritionList =
            responseData['nutrition'] ?? [];

        final foods = nutritionList.map<Map<String, dynamic>>(
          (item) {
            return Map<String, dynamic>.from(item);
          },
        ).toList();

        int total = 0;

        for (final food in foods) {
          total +=
              (food['calories'] as num?)?.toInt() ?? 0;
        }

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setInt(
          'nutrition_calories',
          total,
        );

        if (!mounted) return;

        setState(() {
          _foods = foods;
          _totalCalories = total;
        });
      } else {
        _message(
          'Failed to load nutrition data.',
        );
      }
    } catch (error) {
      _message(
        'Could not connect to backend.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // ADD FOOD TO MONGODB
  // ==========================================

  Future<void> _addFood() async {
    final food = _foodController.text.trim();

    final calories =
        int.tryParse(_calorieController.text.trim());

    if (food.isEmpty) {
      _message('Please enter food name.');
      return;
    }

    if (calories == null || calories < 0) {
      _message('Please enter valid calories.');
      return;
    }

    try {
      final email = await _getUserEmail();

      if (email == null || email.isEmpty) {
        _message(
          'User email not found. Please login again.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('$baseUrl/nutrition'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userEmail': email,
          'meal': _mealType,
          'food': food,
          'calories': calories,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final savedNutrition =
            Map<String, dynamic>.from(
          responseData['nutrition'],
        );

        if (!mounted) return;

        setState(() {
          _foods.insert(
            0,
            savedNutrition,
          );

          _totalCalories += calories;
        });

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setInt(
          'nutrition_calories',
          _totalCalories,
        );

        _foodController.clear();
        _calorieController.clear();

        _message(
          'Food added successfully!',
        );
      } else {
        _message(
          'Failed to save food.',
        );
      }
    } catch (error) {
      _message(
        'Could not connect to backend.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // DELETE FOOD FROM MONGODB
  // ==========================================

  Future<void> _deleteFood(int index) async {
    final item = _foods[index];

    final id = item['_id']?.toString();

    if (id == null || id.isEmpty) {
      _message(
        'Unable to delete this entry.',
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.delete(
        Uri.parse(
          '$baseUrl/nutrition/$id',
        ),
      );

      if (response.statusCode == 200) {
        await _loadFoods();

        _message(
          'Food deleted successfully.',
        );
      } else {
        _message(
          'Failed to delete food.',
        );
      }
    } catch (error) {
      _message(
        'Could not connect to backend.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // CLEAR ALL NUTRITION
  // ==========================================

  Future<void> _clearAll() async {
    if (_foods.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      for (final food in _foods) {
        final id = food['_id']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        await http.delete(
          Uri.parse(
            '$baseUrl/nutrition/$id',
          ),
        );
      }

      await _loadFoods();

      _message(
        'Nutrition history cleared.',
      );
    } catch (error) {
      _message(
        'Could not clear nutrition history.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // MESSAGE
  // ==========================================

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _foodController.dispose();
    _calorieController.dispose();

    super.dispose();
  }

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Nutrition Tracker',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            const Color(0xFFF9F1FC),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Track Your Nutrition',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Keep track of what you eat every day.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================
            // TOTAL CALORIES
            // ==================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: const Color(0xFFF8F1FA),
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 42,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$_totalCalories kcal',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    'Total Calories',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Add Food',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            // ==================================
            // MEAL TYPE
            // ==================================

            DropdownButtonFormField<String>(
              initialValue: _mealType,

              decoration: InputDecoration(
                labelText: 'Meal',

                prefixIcon:
                    const Icon(Icons.restaurant),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              items: const [
                DropdownMenuItem(
                  value: 'Breakfast',
                  child: Text('Breakfast'),
                ),

                DropdownMenuItem(
                  value: 'Lunch',
                  child: Text('Lunch'),
                ),

                DropdownMenuItem(
                  value: 'Dinner',
                  child: Text('Dinner'),
                ),

                DropdownMenuItem(
                  value: 'Snack',
                  child: Text('Snack'),
                ),
              ],

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _mealType = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // ==================================
            // FOOD NAME
            // ==================================

            TextField(
              controller: _foodController,

              decoration: InputDecoration(
                labelText: 'Food Name',
                hintText:
                    'Example: Rice and Dal',

                prefixIcon:
                    const Icon(Icons.fastfood),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================
            // CALORIES
            // ==================================

            TextField(
              controller: _calorieController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                labelText: 'Calories',
                hintText: 'Example: 400',

                prefixIcon:
                    const Icon(
                  Icons.local_fire_department,
                ),

                suffixText: 'kcal',

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================
            // ADD BUTTON
            // ==================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : _addFood,

                icon: const Icon(Icons.add),

                label: Text(
                  _isLoading
                      ? 'Saving...'
                      : 'Add Food',

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFF0E5FA),

                  foregroundColor:
                      const Color(0xFF6D4BA8),

                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================
            // FOOD HISTORY HEADER
            // ==================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Food History',

                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_foods.isNotEmpty)
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _clearAll,

                    child: const Text(
                      'Clear All',

                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================
            // LOADING
            // ==================================

            if (_isLoading && _foods.isEmpty)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(30),
                  child:
                      CircularProgressIndicator(),
                ),
              )

            // ==================================
            // EMPTY
            // ==================================

            else if (_foods.isEmpty)
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
                      Icons.restaurant,
                      size: 45,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 10),

                    Text(
                      'No food entries yet',

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )

            // ==================================
            // FOOD LIST
            // ==================================

            else
              ...List.generate(
                _foods.length,
                (index) {
                  final item =
                      _foods[index];

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(16),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFF8F1FA),

                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 32,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                item['food']
                                        ?.toString() ??
                                    'Food',

                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                item['meal']
                                        ?.toString() ??
                                    '',

                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                '${item['calories']} kcal',
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                      _deleteFood(
                                        index,
                                      );
                                    },

                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}