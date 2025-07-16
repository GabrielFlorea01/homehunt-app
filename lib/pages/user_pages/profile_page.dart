import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final firestore = FirebaseFirestore.instance; // referinta la db
  final storage = FirebaseStorage.instance; // referinta la storage
  final user = FirebaseAuth.instance.currentUser; // userul curent
  final picker = ImagePicker(); // picker pentru poza

  final nameCtrl = TextEditingController(); // controller nume
  final emailCtrl = TextEditingController(); // controller email
  final phoneCtrl = TextEditingController(); // controller telefon

  bool isLoading = false; // flag pentru loading pagina
  bool imageUploading = false; // flag pentru loading la upload poza
  String? errorMessage; // mesaj de eroare
  String? successMessage; // mesaj de succes
  String? profileImageUrl; // url poza profil

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // utilizatorul din Firestore
  Future<void> loadUser() async {
    if (user == null) return;
    setState(() => isLoading = true);
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

  // incarca poza de profil in Storage
  Future<void> uploadProfileImage() async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => imageUploading = true);
    final bytes = await picked.readAsBytes();
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

  // metoda pentru stergerea pozei de profil
  Future<void> deleteProfileImage() async {
    if (profileImageUrl == null) return;
    setState(() => imageUploading = true);
    try {
      // sterge poza din storage daca exista
      final ref = storage.refFromURL(profileImageUrl!);
      await ref.delete();
    } catch (_) {}
    // sterge url-ul din Firestore
    await firestore.collection('users').doc(user!.uid).update({
      'profileImageUrl': FieldValue.delete(),
    });
    setState(() {
      profileImageUrl = null;
      imageUploading = false;
    });
  }

  // salveaza modificarile
  Future<void> saveProfile() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => errorMessage = 'Numarul de telefon este obligatoriu');
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });
    try {
      final updateData = {'name': nameCtrl.text.trim(), 'phone': phone};
      await firestore.collection('users').doc(user!.uid).update(updateData);
      setState(() => successMessage = 'Profil actualizat!');
    } catch (e) {
      setState(() => errorMessage = 'Eroare: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >=
        900; // verificare pentru layout wide
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: LayoutBuilder(
        builder:
            (ctx, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child:
                      isWide
                          ? Row(children: [buildFormPane(), buildImagePane()])
                          : Column(
                            children: [buildImagePane(), buildFormPane()],
                          ),
                ),
              ),
            ),
      ),
    );
  }

  // widget/formularul de editare profil
  Widget buildFormPane() {
    final theme = Theme.of(context);
    return Expanded(
      flex: 7,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
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
                        if (profileImageUrl != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: InkWell(
                              onTap: imageUploading ? null : deleteProfileImage,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      emailCtrl.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nume complet',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saveProfile,
                child: const Text('Salveaza'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // widget cu imaginea de fundal
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
