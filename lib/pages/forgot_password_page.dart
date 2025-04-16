import 'package:flutter/material.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/login_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().forgotPassword(_emailController.text.trim());
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
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
                  'Reset Password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _emailSent
                      ? 'Check your email for a reset link'
                      : 'Enter your email to receive a reset link',
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

                // Form or Success Message
                if (!_emailSent) ...[
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Send Reset Link'),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
