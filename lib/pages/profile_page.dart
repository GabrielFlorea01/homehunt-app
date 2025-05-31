import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool isGoogleUser = false;
  bool isLoading = false;
  bool imageUploading = false;
  String? errorMessage;
  String? successMessage;
  String? phoneError;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    if (user == null) return;
    setState(() => isLoading = true);

    isGoogleUser = user!.providerData.any((p) => p.providerId == 'google.com');
    final doc = await firestore.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameCtrl.text = data['name'] ?? '';
      emailCtrl.text = data['email'] ?? user!.email!;
      phoneCtrl.text = data['phone'] ?? '';
      profileImageUrl = data['profileImageUrl'];
    }

    setState(() => isLoading = false);
  }

  Future<void> uploadProfileImage() async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => imageUploading = true);
    final Uint8List bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last;
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    final ref = storage.ref('profile_images/${user!.uid}/$filename');
    final snap = await ref.putData(
      bytes,
      SettableMetadata(contentType: picked.mimeType),
    );
    final url = await snap.ref.getDownloadURL();

    await firestore.collection('users').doc(user!.uid).update({
      'profileImageUrl': url,
    });

    setState(() {
      profileImageUrl = url;
      imageUploading = false;
    });
  }

  Future<void> saveProfile() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => phoneError = 'Numar de telefon este necesar');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      phoneError = null;
    });

    try {
      final updateData = {'name': nameCtrl.text.trim(), 'phone': phone};
      if (!isGoogleUser && emailCtrl.text.trim() != user!.email) {
        await user!.updateEmail(emailCtrl.text.trim());
        updateData['email'] = emailCtrl.text.trim();
      }
      await firestore.collection('users').doc(user!.uid).update(updateData);

      setState(() {
        successMessage = 'Profil actualizat cu succes';
      });
    } catch (e) {
      setState(() => errorMessage = 'Eroare: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child:
                    isWide
                        ? Row(children: [buildFormPane(), buildImagePane()])
                        : Column(children: [buildImagePane(), buildFormPane()]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildFormPane() {
    final theme = Theme.of(context);
    return Expanded(
      flex: 7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
                children: [
                if (errorMessage != null) ...[
                  ErrorBanner(
                  message: errorMessage!,
                  messageType: MessageType.error,
                  onDismiss: () => setState(() => errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                ] else if (successMessage != null) ...[
                  ErrorBanner(
                  message: successMessage!,
                  messageType: MessageType.success,
                  onDismiss: () => setState(() => successMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(height: 50),
                // Avatar + buton upload
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                    0.1,
                    ),
                    backgroundImage:
                      profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child:
                      profileImageUrl == null
                        ? Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.primary,
                        )
                        : null,
                  ),
                  InkWell(
                    onTap: imageUploading ? null : uploadProfileImage,
                    child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child:
                      imageUploading
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                    ),
                  ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? nameCtrl.text,
                  style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Formular
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Text(
                      'Informatii personale',
                      style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                      labelText: 'Nume complet',
                      prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      enabled: !isGoogleUser,
                      decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: const Icon(Icons.phone),
                      errorText: phoneError,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: saveProfile,
                      child:
                        isLoading
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                          )
                          : const Text('Salveaza modificarile'),
                    ),
                    ],
                  ),
                  ),
                ),
                const Spacer(),
                //buton inapoi
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Inapoi la marketplace'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImagePane() {
    return Expanded(
      flex: 5,
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
