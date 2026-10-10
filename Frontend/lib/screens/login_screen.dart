import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> login() async {
    final emailOrMobile = emailController.text.trim();
    final password = passwordController.text;

    if (emailOrMobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter email/mobile and password.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'emailOrMobile': emailOrMobile,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool('logged_in', true);
        await prefs.setString(
          'user_name',
          user['name'],
        );
        await prefs.setString(
          'user_email',
          user['email'],
        );
        await prefs.setString(
          'user_mobile',
          user['mobile'],
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login successful! 🎉',
            ),
          ),
        );

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: user['name'],
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Login failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect to server: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fitness_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 40,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  const Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'F-Track',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Track Your Fitness Journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 45),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Login to continue',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText:
                                'Email or Mobile Number',
                            prefixIcon:
                                Icon(Icons.person),
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock),
                            border:
                                const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword =
                                      !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        ElevatedButton(
                          onPressed:
                              isLoading ? null : login,
                          style:
                              ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child:
                                      CircularProgressIndicator(),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "Don't have an account?",
                          textAlign: TextAlign.center,
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Create New Account',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}