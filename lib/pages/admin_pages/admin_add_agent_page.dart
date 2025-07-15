import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AdminAddAgentPage extends StatefulWidget {
  const AdminAddAgentPage({super.key});

  @override
  AdminAddAgentPageState createState() => AdminAddAgentPageState();
}

class AdminAddAgentPageState extends State<AdminAddAgentPage> {
  // colectia agents din Firestore
  final agents = FirebaseFirestore.instance.collection('agents');
  // controller pentru campurile de input
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  // flag pentru starea de salvare
  bool isSaving = false;
  String? successMessage;

  // functie pentru salvarea agentului
  Future<void> saveAgent() async {
    // daca deja se salveaza, nu mai face nimic
    if (isSaving) return;
    setState(() => isSaving = true);

    await agents.add({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'properties': <String>[],
    });

    if (!mounted) return;
    setState(() => isSaving = false);
    successMessage = 'Agent adaugat cu succes';
    Navigator.of(context).pop(); // inchidem pagina dupa salvare
  }

  @override
  Widget build(BuildContext context) {
    // verific daca ecranul e suficient de lat
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          // pe ecrane mari form + imagine
          if (isWide) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Row(
                children: [
                  Expanded(flex: 7, child: buildFormPane()),
                  Expanded(flex: 5, child: buildImagePane()),
                ],
              ),
            );
          } else {
            // pe ecrane inguste scroll cu imagine sus
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [buildImagePane(height: 300), buildFormPane()],
              ),
            );
          }
        },
      ),
    );
  }

  //partea de formular
  Widget buildFormPane() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // header cu back si titlu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Adauga Agent',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // buton adauga
                TextButton(
                  onPressed: saveAgent,
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Adauga'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // camp nume
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nume',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // camp email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // camp telefon
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }

  // pane pentru afisare imagine
  Widget buildImagePane({double? height}) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/homehuntlogin.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
