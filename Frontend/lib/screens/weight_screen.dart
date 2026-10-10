import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _weightController =
      TextEditingController();

  List<Map<String, dynamic>> _history = [];

  double? _currentWeight;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWeight();
  }

  // ==========================================
  // LOAD WEIGHT FROM MONGODB
  // ==========================================
  Future<void> _loadWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userEmail = prefs.getString('user_email');

      if (userEmail == null || userEmail.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _message('User email not found. Please login again.');
        return;
      }

      final encodedEmail = Uri.encodeComponent(userEmail);

      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/weight/$encodedEmail',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> weights =
            data['weights'] ?? [];

        final history = weights
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        setState(() {
          _history = history;

          if (_history.isNotEmpty) {
            _currentWeight =
                (_history.first['weight'] as num).toDouble();
          } else {
            _currentWeight = null;
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        _message('Unable to load weight history.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _message('Unable to connect to server.');
    }
  }

  // ==========================================
  // SAVE WEIGHT TO MONGODB
  // ==========================================
  Future<void> _addWeight() async {
    final weight =
        double.tryParse(_weightController.text.trim());

    if (weight == null || weight <= 0) {
      _message('Enter a valid weight.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final userEmail = prefs.getString('user_email');

      if (userEmail == null || userEmail.isEmpty) {
        _message(
          'User email not found. Please login again.',
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }

        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:5000/weight'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userEmail': userEmail,
          'weight': weight,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final savedWeight =
            Map<String, dynamic>.from(data['weight']);

        setState(() {
          _history.insert(0, savedWeight);
          _currentWeight = weight;
        });

        _weightController.clear();

        _message('Weight saved successfully! 🎉');
      } else {
        final data = jsonDecode(response.body);

        _message(
          data['message'] ?? 'Unable to save weight.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _message('Unable to connect to server.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================
  // DELETE WEIGHT FROM MONGODB
  // ==========================================
  Future<void> _deleteWeight(int index) async {
    if (index < 0 || index >= _history.length) {
      return;
    }

    final item = _history[index];

    final id = item['_id'];

    if (id == null) {
      _message('Weight ID not found.');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse(
          'http://localhost:5000/weight/$id',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _history.removeAt(index);

          if (_history.isNotEmpty) {
            _currentWeight =
                (_history.first['weight'] as num).toDouble();
          } else {
            _currentWeight = null;
          }
        });

        _message('Weight deleted successfully.');
      } else {
        final data = jsonDecode(response.body);

        _message(
          data['message'] ?? 'Unable to delete weight.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _message('Unable to connect to server.');
    }
  }

  // ==========================================
  // SHOW MESSAGE
  // ==========================================
  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? change;

    if (_history.length >= 2) {
      final current =
          (_history[0]['weight'] as num).toDouble();

      final previous =
          (_history[1]['weight'] as num).toDouble();

      change = current - previous;
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Weight Tracker',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF9F1FC),
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Track Your Weight',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Monitor your weight over time.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CURRENT WEIGHT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F1FA),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.monitor_weight,
                          size: 45,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _currentWeight == null
                              ? '-- kg'
                              : '${_currentWeight!.toStringAsFixed(1)} kg',

                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Text(
                          'Current Weight',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        if (change != null) ...[
                          const SizedBox(height: 10),

                          Text(
                            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg since last entry',

                            style: TextStyle(
                              color: change > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ADD WEIGHT
                  const Text(
                    'Add Weight',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _weightController,

                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),

                    decoration: InputDecoration(
                      labelText: 'Weight',
                      hintText: 'Example: 70.5',

                      prefixIcon: const Icon(
                        Icons.monitor_weight,
                      ),

                      suffixText: 'kg',

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton.icon(
                      onPressed:
                          _isSaving ? null : _addWeight,

                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),

                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Weight',

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

                  // WEIGHT HISTORY
                  const Text(
                    'Weight History',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_history.isEmpty)
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
                            Icons.monitor_weight,
                            size: 45,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 10),

                          Text(
                            'No weight records yet',

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(
                      _history.length,
                      (index) {
                        final item =
                            _history[index];

                        final weight =
                            (item['weight'] as num)
                                .toDouble();

                        String dateText = '';

                        if (item['date'] != null) {
                          try {
                            final date =
                                DateTime.parse(
                              item['date'].toString(),
                            );

                            dateText =
                                '${date.day.toString().padLeft(2, '0')}/'
                                '${date.month.toString().padLeft(2, '0')}/'
                                '${date.year}';
                          } catch (_) {}
                        }

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),

                          padding:
                              const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF8F1FA),

                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.monitor_weight,
                                size: 30,
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      '${weight.toStringAsFixed(1)} kg',

                                      style:
                                          const TextStyle(
                                        fontSize: 19,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    if (dateText.isNotEmpty)
                                      const SizedBox(
                                        height: 4,
                                      ),

                                    if (dateText.isNotEmpty)
                                      Text(
                                        dateText,

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  _deleteWeight(index);
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
