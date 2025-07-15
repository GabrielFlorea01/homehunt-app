import 'package:flutter/material.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';
import 'package:homehunt/pages/auth_pages/login_page.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  // controllere pentru inputuri
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false; // stare pentru indicator de incarcare
  String? errorMessage; // mesaj de eroare daca exista
  bool obscurePassword = true; // ascunde/afiseaza parola

  @override
  void dispose() {
    //se elibereaza controllerele la eliminarea widget-ului din arbore
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    // se apeleaza metoda de inregistrare din AuthService
    try {
      await AuthService().signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim(),
        phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(); // revine la pagina de login dupa succes
      }
    } on AuthException catch (e) {
      setState(
        () => errorMessage = e.message,
      ); // seteaza mesajul de eroare cu mesajul custom din AuthException
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // construieste UI pentru pagina de signup
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
                // titlu
                Text(
                  'Creeaza un cont',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '...si incepe cautarea',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // afiseaza eroarea daca exista
                if (errorMessage != null) ...[
                  ErrorBanner(
                    message: errorMessage!,
                    onDismiss: () => setState(() => errorMessage = null),
                  ),
                  const SizedBox(height: 20),
                ],

                // camp pentru nume complet
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nume complet',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                // camp pentru telefon cu selector de tara
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'RO',
                  disableLengthCheck: true,
                  onChanged: (phone) {
                    phoneController.text = phone.completeNumber;
                  },
                  pickerDialogStyle: PickerDialogStyle(
                    width: 300,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // camp pentru email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // camp pentru parola cu toggle pentru vizibilitate
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Parola',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // buton pentru creare cont cu circular progress indicator daca e loading
                FilledButton(
                  onPressed: isLoading ? null : signUp,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Creeaza cont'),
                ),
                const SizedBox(height: 32),
                // buton si text catre pagina de login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ai deja un cont?'),
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
                      child: const Text('Conecteaza-te'),
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
