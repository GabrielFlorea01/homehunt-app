import 'package:flutter/material.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/forgot_password_page.dart';
import 'package:homehunt/pages/signup_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> googleSignIn() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().googleSignIn();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "A aparut o eroare";
        });
      }
    }
  }

    Future<void> facebookSignIn() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().facebookSignIn();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "A aparut o eroare";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 44, 48, 77),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child:
                    isWide
                        ? Row(
                          children: [buildLoginContainer(), buildImageSide()],
                        )
                        : Column(
                          children: [buildImageSide(), buildLoginContainer()],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLoginContainer() {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 15),
                Image(
                  image: const AssetImage('lib/images/logomov.png'),
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 30),
                if (errorMessage != null) ...[
                  ErrorBanner(
                    message: errorMessage!,
                    onDismiss: () => setState(() => errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text('Ai uitat parola'),
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton(
                  onPressed: isLoading ? null : login,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Conecteaza-te'),
                ),
                const SizedBox(height: 45),
                FilledButton.icon(
                  onPressed: isLoading ? null : googleSignIn,
                  icon: Image.asset(
                    'lib/images/google.png',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Continua cu Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 0.5),
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: isLoading ? null : facebookSignIn,
                  icon: Image.asset(
                    'lib/images/facebook.png',
                    width: 20,
                    height: 22,
                  ),
                  label: const Text('Continua cu Facebook'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blueAccent, width: 0.5),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nu ai un cont?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: const Text('Creeaza cont nou'),
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

  Widget buildImageSide() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/homehuntlogin.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
