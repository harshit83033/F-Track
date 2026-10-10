import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  String _goal = 'Stay Fit';

  bool _isLoading = true;
  bool _isSaving = false;

  final String baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail =
        prefs.getString('user_email') ??
        prefs.getString('email') ??
        '';

    if (savedEmail.isEmpty) {
      _loadLocalProfile(prefs);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }

    try {
      final url =
          '$baseUrl/profile/${Uri.encodeComponent(savedEmail)}';

      debugPrint('PROFILE GET URL: $url');

      final response = await http.get(
        Uri.parse(url),
      );

      debugPrint(
        'PROFILE GET STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PROFILE GET RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend sends profile inside "user"
        final user = data['user'];

        if (user != null) {
          nameController.text = user['name'] ?? '';

          emailController.text =
              user['email'] ?? savedEmail;

          mobileController.text =
              user['mobile'] ?? '';

          ageController.text =
              user['age']?.toString() ?? '';

          heightController.text =
              user['height']?.toString() ?? '';

          setState(() {
            _goal =
                user['fitnessGoal'] ?? 'Stay Fit';
          });

          // Update local storage
          await prefs.setString(
            'user_name',
            user['name'] ?? '',
          );

          await prefs.setString(
            'user_email',
            user['email'] ?? savedEmail,
          );

          await prefs.setString(
            'user_mobile',
            user['mobile'] ?? '',
          );

          await prefs.setString(
            'user_age',
            user['age']?.toString() ?? '',
          );

          await prefs.setString(
            'user_height',
            user['height']?.toString() ?? '',
          );

          await prefs.setString(
            'fitness_goal',
            user['fitnessGoal'] ?? 'Stay Fit',
          );
        }
      } else {
        debugPrint(
          'PROFILE GET FAILED: ${response.body}',
        );

        _loadLocalProfile(prefs);
      }
    } catch (e) {
      debugPrint(
        'PROFILE LOAD ERROR: $e',
      );

      _loadLocalProfile(prefs);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadLocalProfile(
    SharedPreferences prefs,
  ) {
    nameController.text =
        prefs.getString('user_name') ??
        prefs.getString('name') ??
        '';

    emailController.text =
        prefs.getString('user_email') ??
        prefs.getString('email') ??
        '';

    mobileController.text =
        prefs.getString('user_mobile') ??
        prefs.getString('mobile') ??
        '';

    ageController.text =
        prefs.getString('user_age') ?? '';

    heightController.text =
        prefs.getString('user_height') ?? '';

    _goal =
        prefs.getString('fitness_goal') ??
        'Stay Fit';
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final age = ageController.text.trim();
    final height = heightController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill Name, Email and Mobile Number',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final url = '$baseUrl/profile';

      debugPrint('PROFILE PUT URL: $url');

      final requestBody = {
        'email': email,
        'name': name,
        'mobile': mobile,
        'age': age,
        'height': height,
        'fitnessGoal': _goal,
      };

      debugPrint(
        'PROFILE PUT BODY: ${jsonEncode(requestBody)}',
      );

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint(
        'PROFILE PUT STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PROFILE PUT RESPONSE: ${response.body}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          'user_name',
          name,
        );

        await prefs.setString(
          'name',
          name,
        );

        await prefs.setString(
          'user_email',
          email,
        );

        await prefs.setString(
          'email',
          email,
        );

        await prefs.setString(
          'user_mobile',
          mobile,
        );

        await prefs.setString(
          'mobile',
          mobile,
        );

        await prefs.setString(
          'user_age',
          age,
        );

        await prefs.setString(
          'user_height',
          height,
        );

        await prefs.setString(
          'fitness_goal',
          _goal,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile saved successfully!',
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Failed to save profile',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'PROFILE SAVE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROFILE ERROR: $e',
          ),
          duration: const Duration(
            seconds: 8,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          width: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    ageController.dispose();
    heightController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration(
                      'Full Name',
                      Icons.person,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      'Email',
                      Icons.email,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: mobileController,
                    keyboardType:
                        TextInputType.phone,
                    decoration: _inputDecoration(
                      'Mobile Number',
                      Icons.phone,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: ageController,
                    keyboardType:
                        TextInputType.number,
                    decoration: _inputDecoration(
                      'Age',
                      Icons.cake,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: heightController,
                    keyboardType:
                        TextInputType.number,
                    decoration: _inputDecoration(
                      'Height (cm)',
                      Icons.height,
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _goal,
                    decoration: _inputDecoration(
                      'Fitness Goal',
                      Icons.fitness_center,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Stay Fit',
                        child: Text('Stay Fit'),
                      ),
                      DropdownMenuItem(
                        value: 'Lose Weight',
                        child: Text('Lose Weight'),
                      ),
                      DropdownMenuItem(
                        value: 'Gain Weight',
                        child: Text('Gain Weight'),
                      ),
                      DropdownMenuItem(
                        value: 'Build Muscle',
                        child: Text('Build Muscle'),
                      ),
                      DropdownMenuItem(
                        value: 'Improve Endurance',
                        child: Text(
                          'Improve Endurance',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _goal = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            Colors.grey.shade300,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your profile information is saved to your F-Track account.',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}