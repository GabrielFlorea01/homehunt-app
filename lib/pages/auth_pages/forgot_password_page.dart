import 'package:flutter/material.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';
import 'package:homehunt/pages/auth_pages/login_page.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController(); // controller pentru email
  bool isLoading = false; // flag pentru loading
  bool emailSent = false; // flag daca s-a trimis emailul
  String? errorMessage; // mesaj de eroare

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  //emailul de resetare
  Future<void> sendResetEmail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().forgotPassword(emailController.text.trim()); // serviciul de resetare
      setState(() => emailSent = true); // marcheaza ca trimis emailul
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 48, 77),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Reseteaza parola',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  //text informativ
                  emailSent
                      ? 'Verifica email-ul pentru linkul de resetare'
                      : 'Introdu adresa de email pentru a primi link de resetare',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // afiseaza eroare daca e cazul
                if (errorMessage != null) ...[
                  ErrorBanner(
                    message: errorMessage!,
                    onDismiss: () => setState(() => errorMessage = null),
                  ),
                  const SizedBox(height: 20),
                ],
                // formularul doar daca nu s-a trimis emailul
                if (!emailSent) ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : sendResetEmail,
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2), // loading
                            )
                            : const Text('Trimite link'),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(), // inapoi la login
                      ),
                    );
                  },
                  child: const Text('Inapoi la login'), //buton inapoi
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}