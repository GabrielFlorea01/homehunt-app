import 'package:flutter/material.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/home_page.dart';
import 'package:homehunt/pages/login_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userTypeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _userTypeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signUp(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text.trim(),
        _userTypeController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 48, 77), // Dark background
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), // Small container
          padding: const EdgeInsets.all(32), // Padding for inner elements
          decoration: const BoxDecoration(
            color: Colors.white, // White background for the form container
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ), // Rounded corners
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '...and start the hunt',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Error Banner
                if (_errorMessage != null) ...[
                  ErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 20),
                ],

                // Form Fields
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: null, // Initial value (null means no selection)
                  decoration: const InputDecoration(
                    labelText: 'User Type',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Buyer',
                      child: Text('Buyer'),
                    ),
                    DropdownMenuItem(
                      value: 'Seller',
                      child: Text('Seller'),
                    ),
                    DropdownMenuItem(
                      value: 'Agent',
                      child: Text('Agent'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _userTypeController.text = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _signUp,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Sign Up'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
