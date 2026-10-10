import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all the fields',
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
        Uri.parse('http://localhost:5000/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        final user = data['user'];

        final prefs =
            await SharedPreferences.getInstance();

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

        await prefs.setBool(
          'account_created',
          true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! 🎉',
            ),
          ),
        );

        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Account creation failed',
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
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.fitness_center,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Create Your F-Track Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(
                  Icons.person,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileController,
              keyboardType:
                  TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(
                  Icons.phone,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(
                  Icons.lock,
                ),
                border: const OutlineInputBorder(),
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

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
                  isLoading ? null : createAccount,
              style: ElevatedButton.styleFrom(
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}